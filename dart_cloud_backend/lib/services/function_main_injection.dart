import 'dart:io';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

typedef CloudFunctionInfo = ({
  String className,
  String filePath,
  String classCode,
  String imports,
});

/// Service for injecting main.dart into deployed cloud functions
///
/// This service analyzes the function code to find the class annotated with
/// @cloudFunction and generates a main.dart file that:
/// 1. Reads environment variables
/// 2. Reads request.json (CloudRequest data from backend)
/// 3. Instantiates the cloud function class
/// 4. Calls the handle method with request and environment
/// 5. Writes the response to stdout as JSON
class FunctionMainInjection {
  /// Inject main.dart into the function directory
  ///
  /// This method:
  /// 1. Analyzes all .dart files to find the @cloudFunction annotated class
  /// 2. Generates a main.dart that invokes the cloud function
  /// 3. Writes the main.dart file to the function directory
  ///
  /// Parameters:
  /// - [functionPath]: Absolute path to the function directory
  ///
  /// Returns: true if injection succeeded, false otherwise
  static Future<({bool result, File? file})> injectMain(String functionPath) async {
    try {
      // Find the cloud function class
      final cloudFunctionInfo = await _findCloudFunctionClass(functionPath);

      if (cloudFunctionInfo == null) {
        throw Exception(
          'No class with @cloudFunction annotation found in function directory',
        );
      }

      // Generate main.dart content
      final mainContent = _generateMainDart(
        className: cloudFunctionInfo.className,
        classCode: cloudFunctionInfo.classCode,
        userImports: cloudFunctionInfo.imports,
      );

      // Write main.dart to function directory
      final mainFile = File(path.join(functionPath, 'main.dart'));
      await mainFile.writeAsString(mainContent);

      return (result: true, file: mainFile);
    } catch (e) {
      print('Failed to inject main.dart: $e');
      return (result: false, file: null);
    }
  }

  /// Find the class annotated with @cloudFunction in the function directory
  ///
  /// Validation rules:
  /// - Only ONE class extending CloudDartFunction with @cloudFunction is allowed
  /// - The class MUST be defined in main.dart file
  /// - No @cloudFunction annotated classes are allowed in other .dart files
  ///
  /// Returns a record with:
  /// - className: Name of the class
  /// - filePath: Relative path to the file containing the class
  /// - classCode: The actual class code to embed in main.dart
  /// - imports: Import statements from the original file
  static Future<CloudFunctionInfo?> _findCloudFunctionClass(String functionPath) async {
    final functionDir = Directory(functionPath);

    if (!functionDir.existsSync()) {
      throw Exception('Function directory does not exist: $functionPath');
    }

    // Collect all .dart files
    final allDartFiles = functionDir
        .listSync(recursive: true)
        .where((entity) => entity is File && entity.path.endsWith('.dart'))
        .cast<File>()
        .toList();

    // Separate main.dart from other files
    final mainDartFile = allDartFiles.firstWhereOrNull(
      (file) => path.basename(file.path) == 'main.dart',
    );
    final otherDartFiles = allDartFiles
        .where((file) => path.basename(file.path) != 'main.dart')
        .toList();

    // First, check other files - reject if any @cloudFunction class is found
    for (final file in otherDartFiles) {
      final hasCloudFunction = await _hasCloudFunctionClass(file.path, functionPath);
      if (hasCloudFunction) {
        throw Exception(
          '@cloudFunction annotated class found in "${path.basename(file.path)}". '
          'Cloud functions must be defined only in main.dart',
        );
      }
    }

    // main.dart must exist
    if (mainDartFile == null) {
      throw Exception(
        'main.dart not found. Cloud function must be defined in main.dart',
      );
    }

    // Analyze main.dart for the cloud function class
    final result = await _analyzeFile(
      mainDartFile.path,
      functionPath,
    );
    if (result == null) {
      throw Exception(
        'No class extending CloudDartFunction with @cloudFunction annotation '
        'found in main.dart',
      );
    }

    return result;
  }

  /// Check if a file contains a class with @cloudFunction annotation
  /// extending CloudDartFunction (used for rejection validation)
  static Future<bool> _hasCloudFunctionClass(
    String filePath,
    String functionPath,
  ) async {
    try {
      final collection = AnalysisContextCollection(
        includedPaths: [functionPath],
      );

      final context = collection.contextFor(filePath);
      final result = await context.currentSession.getResolvedUnit(filePath);

      if (result is ResolvedUnitResult) {
        final visitor = _CloudFunctionDetector();
        result.unit.visitChildren(visitor);
        return visitor.foundCloudFunction;
      }
    } catch (e) {
      // Ignore analysis errors for detection
    }
    return false;
  }

  /// Analyze main.dart to find the single @cloudFunction annotated class
  static Future<CloudFunctionInfo?> _analyzeFile(
    String filePath,
    String functionPath,
  ) async {
    try {
      final normalizedFunctionPath = path.normalize(path.absolute(filePath));
      final collection = AnalysisContextCollection(
        includedPaths: [normalizedFunctionPath],
      );
      final normalizedFilePath = path.normalize(path.absolute(filePath));

      final context = collection.contextFor(normalizedFilePath);
      final result = await context.currentSession.getResolvedUnit(normalizedFilePath);

      if (result is ResolvedUnitResult) {
        final visitor = _CloudFunctionVisitor();
        result.unit.visitChildren(visitor);

        // Validate: exactly one cloud function class
        if (visitor.cloudFunctionClasses.isEmpty) {
          return null;
        }

        if (visitor.cloudFunctionClasses.length > 1) {
          throw Exception(
            'Multiple @cloudFunction annotated classes found in main.dart: '
            '${visitor.cloudFunctionClasses.map((c) => c.name).join(", ")}. '
            'Only one cloud function class is allowed.',
          );
        }

        final cloudFunction = visitor.cloudFunctionClasses.first;
        final relativePath = path.relative(
          normalizedFilePath,
          from: normalizedFunctionPath,
        );

        return (
          className: cloudFunction.name,
          filePath: relativePath,
          classCode: cloudFunction.code,
          imports: visitor.imports.join('\n'),
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      print('Failed to analyze file $filePath: $e');
    }

    return null;
  }

  /// Generate main.dart content that invokes the cloud function
  static String _generateMainDart({
    required String className,
    required String classCode,
    required String userImports,
  }) {
    return '''
import 'dart:io';
import 'dart:convert';
import 'package:dart_cloud_function/dart_cloud_function.dart';

// User imports from original function file
$userImports



/// Auto-generated main.dart for cloud function execution
///
/// This file is generated by the deployment process and should not be modified.
/// It reads the request from request.json, invokes the cloud function,
/// and writes the response to stdout.
void main() async {
  try {
    // Read environment variables
    final env = Platform.environment;

    // Read request from request.json
    final requestFile = File('request.json');
    if (!await requestFile.exists()) {
      _writeError('request.json not found');
      exit(1);
    }

    final requestJson = jsonDecode(await requestFile.readAsString());

    // Parse CloudRequest from JSON
    final request = CloudRequest(
      method: requestJson['method'] as String? ?? 'POST',
      path: requestJson['path'] as String? ?? '/',
      headers: Map<String, String>.from(requestJson['headers'] as Map? ?? {}),
      query: Map<String, String>.from(requestJson['query'] as Map? ?? {}),
      body: requestJson['body'],
    );

    // Instantiate the cloud function
    final function = $className();

    // Execute the function
    final response = await function.handle(
      request: request,
      env: env,
    );

    // Write response to stdout as JSON
    final responseJson = {
      'statusCode': response.statusCode,
      'headers': response.headers,
      'body': response.body,
    };

    stdout.writeln(jsonEncode(responseJson));
    exit(0);
  } catch (e, stackTrace) {
    _writeError('Function execution failed: \$e\\n\$stackTrace');
    exit(1);
  }
}

void _writeError(String message) {
  final errorResponse = {
    'statusCode': 500,
    'headers': {'content-type': 'application/json'},
    'body': {'error': message},
  };
  stdout.writeln(jsonEncode(errorResponse));
}
// Cloud function class code
$classCode
''';
  }
}

/// Data class for cloud function class info
class _CloudFunctionClassInfo {
  final String name;
  final String code;

  _CloudFunctionClassInfo({required this.name, required this.code});
}

/// Simple detector to check if a file contains @cloudFunction class
class _CloudFunctionDetector extends RecursiveAstVisitor<void> {
  bool foundCloudFunction = false;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (_isCloudFunctionClass(node)) {
      foundCloudFunction = true;
    }
    super.visitClassDeclaration(node);
  }
}

/// AST visitor to find and collect classes annotated with @cloudFunction
class _CloudFunctionVisitor extends RecursiveAstVisitor<void> {
  final List<_CloudFunctionClassInfo> cloudFunctionClasses = [];
  final List<String> imports = [];

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue ?? '';
    if (!uri.contains('dart_cloud_function')) {
      imports.add(node.toSource());
    }
    super.visitImportDirective(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (_isCloudFunctionClass(node)) {
      cloudFunctionClasses.add(
        _CloudFunctionClassInfo(
          name: node.name.lexeme,
          code: node.toSource(),
        ),
      );
    }
    super.visitClassDeclaration(node);
  }
}

/// Check if a class declaration is a valid cloud function class
/// (extends CloudDartFunction and has @cloudFunction annotation)
bool _isCloudFunctionClass(ClassDeclaration node) {
  final hasAnnotation = node.metadata.any((annotation) {
    final name = annotation.name.toString();
    return name == 'cloudFunction' || name == 'CloudFunction';
  });

  if (!hasAnnotation) return false;

  final extendsClause = node.extendsClause;
  if (extendsClause == null) return false;

  final superclass = extendsClause.superclass.toString();
  return superclass == 'CloudDartFunction';
}
