import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

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
  static Future<bool> injectMain(String functionPath) async {
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
        className: cloudFunctionInfo['className'] as String,
        classCode: cloudFunctionInfo['classCode'] as String,
        userImports: cloudFunctionInfo['imports'] as String,
      );

      // Write main.dart to function directory
      final mainFile = File(path.join(functionPath, 'main.dart'));
      await mainFile.writeAsString(mainContent);

      return true;
    } catch (e) {
      print('Failed to inject main.dart: $e');
      return false;
    }
  }

  /// Find the class annotated with @cloudFunction in the function directory
  ///
  /// Returns a map with:
  /// - className: Name of the class
  /// - filePath: Relative path to the file containing the class
  /// - classCode: The actual class code to embed in main.dart
  /// - imports: List of import statements from the original file
  static Future<Map<String, String>?> _findCloudFunctionClass(
    String functionPath,
  ) async {
    final functionDir = Directory(functionPath);

    if (!await functionDir.exists()) {
      throw Exception('Function directory does not exist: $functionPath');
    }

    // Find all .dart files in the function directory (excluding main.dart)
    final dartFiles = await functionDir
        .list(recursive: true)
        .where(
          (entity) =>
              entity is File &&
              entity.path.endsWith('.dart') &&
              !entity.path.endsWith('main.dart'),
        )
        .cast<File>()
        .toList();

    if (dartFiles.isEmpty) {
      throw Exception('No Dart files found in function directory');
    }

    // Analyze each file to find the @cloudFunction annotated class
    for (final file in dartFiles) {
      final result = await _analyzeFile(file.path, functionPath);
      if (result != null) {
        return result;
      }
    }

    return null;
  }

  /// Analyze a single Dart file to find @cloudFunction annotated class
  static Future<Map<String, String>?> _analyzeFile(
    String filePath,
    String functionPath,
  ) async {
    try {
      // Create analysis context
      final collection = AnalysisContextCollection(
        includedPaths: [functionPath],
      );

      final context = collection.contextFor(filePath);
      final result = await context.currentSession.getResolvedUnit(filePath);

      if (result is ResolvedUnitResult) {
        final visitor = _CloudFunctionVisitor();
        result.unit.visitChildren(visitor);

        if (visitor.cloudFunctionClassName != null) {
          // Get relative path from function directory
          final relativePath = path.relative(filePath, from: functionPath);

          return {
            'className': visitor.cloudFunctionClassName!,
            'filePath': relativePath,
            'classCode': visitor.classCode,
            'imports': visitor.imports.join('\n'),
          };
        }
      }
    } catch (e) {
      // Continue to next file if analysis fails
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

/// AST visitor to find classes annotated with @cloudFunction
class _CloudFunctionVisitor extends RecursiveAstVisitor<void> {
  String? cloudFunctionClassName;
  String classCode = '';
  final List<String> imports = [];

  @override
  void visitImportDirective(ImportDirective node) {
    // Capture all import statements except dart_cloud_function
    final uri = node.uri.stringValue ?? '';
    if (!uri.contains('dart_cloud_function')) {
      imports.add(node.toSource());
    }
    super.visitImportDirective(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // Check if class has @cloudFunction annotation
    final hasCloudFunctionAnnotation = node.metadata.any((annotation) {
      final name = annotation.name.toString();
      return name == 'cloudFunction' || name == 'CloudFunction';
    });

    // Check if class extends CloudDartFunction
    final extendsClause = node.extendsClause;
    if (extendsClause != null) {
      final superclass = extendsClause.superclass.toString();
      if (superclass == 'CloudDartFunction' && hasCloudFunctionAnnotation) {
        cloudFunctionClassName = node.name.lexeme;
        // Extract the entire class code including annotations
        classCode = node.toSource();
      }
    }

    super.visitClassDeclaration(node);
  }
}
