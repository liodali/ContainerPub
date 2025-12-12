import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Information about a cloud function class found in the codebase
typedef CloudFunctionInfo = ({
  String className,
  String filePath,
  String classCode,
  String imports,
  String allUserCode, // All top-level declarations except main() and imports
});

/// Result of main injection with file location info
typedef InjectionResult = ({
  bool success,
  File? mainFile,
  String entrypoint, // Relative path for Dockerfile (e.g., 'bin/main.dart')
  String? error,
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
  /// 2. Generates a main.dart in bin/ directory that invokes the cloud function
  /// 3. Returns the entrypoint path for Dockerfile generation
  ///
  /// **Strategy:**
  /// - Searches ALL .dart files for @cloudFunction class
  /// - Creates `bin/main.dart` with proper imports to the original file
  /// - Does NOT modify the user's original source files
  ///
  /// Parameters:
  /// - [functionPath]: Absolute path to the function directory
  ///
  /// Returns: InjectionResult with success status, main file, and entrypoint path
  static Future<InjectionResult> injectMain(String functionPath) async {
    try {
      // Find the cloud function class from any .dart file
      final cloudFunctionInfo = await _findCloudFunctionClass(functionPath);

      if (cloudFunctionInfo == null) {
        return (
          success: false,
          mainFile: null,
          entrypoint: '',
          error: 'No class with @cloudFunction annotation found in function directory',
        );
      }

      // Determine where to create main.dart
      final mainLocation = await _determineMainLocation(
        functionPath,
        cloudFunctionInfo,
      );

      // Check if the cloud function is in bin/main.dart itself
      final isInBinMain =
          cloudFunctionInfo.filePath.endsWith('bin/main.dart') ||
          cloudFunctionInfo.filePath.endsWith('bin${path.separator}main.dart');

      // Generate main.dart content
      final mainContent = _generateMainDart(
        className: cloudFunctionInfo.className,
        importPath: mainLocation.importPath,
        userImports: cloudFunctionInfo.imports,
        allUserCode: isInBinMain ? cloudFunctionInfo.allUserCode : null,
      );

      // Ensure directory exists
      final mainDir = mainLocation.mainFile.parent;
      if (!await mainDir.exists()) {
        await mainDir.create(recursive: true);
      }

      // Write main.dart
      await mainLocation.mainFile.writeAsString(mainContent);

      return (
        success: true,
        mainFile: mainLocation.mainFile,
        entrypoint: mainLocation.entrypoint,
        error: null,
      );
    } catch (e) {
      print('Failed to inject main.dart: $e');
      return (
        success: false,
        mainFile: null,
        entrypoint: '',
        error: e.toString(),
      );
    }
  }

  /// Determine where to create main.dart and how to import the cloud function
  static Future<({File mainFile, String entrypoint, String importPath})>
  _determineMainLocation(
    String functionPath,
    CloudFunctionInfo cloudFunctionInfo,
  ) async {
    // Always create bin/main.dart to avoid modifying user's source files
    final binDir = Directory(path.join(functionPath, 'bin'));
    final mainFile = File(path.join(binDir.path, 'main.dart'));

    // Calculate relative import path from bin/main.dart to the cloud function file
    final cloudFunctionFilePath = cloudFunctionInfo.filePath;
    final importPath = _calculateImportPath(functionPath, cloudFunctionFilePath);

    return (
      mainFile: mainFile,
      entrypoint: 'bin/main.dart',
      importPath: importPath,
    );
  }

  /// Calculate the import path from bin/main.dart to the cloud function file
  static String _calculateImportPath(
    String functionPath,
    String cloudFunctionFilePath,
  ) {
    // Get relative path from function root to the cloud function file
    final relativePath = path.relative(
      cloudFunctionFilePath,
      from: functionPath,
    );

    // From bin/main.dart, we need to go up one level then to the file
    // e.g., if file is at lib/my_function.dart, import is '../lib/my_function.dart'
    // e.g., if file is at src/handler.dart, import is '../src/handler.dart'
    return '../$relativePath';
  }

  /// Find the class annotated with @cloudFunction in the function directory
  ///
  /// Searches ALL .dart files for the @cloudFunction annotated class.
  /// Only ONE class with @cloudFunction is allowed across all files.
  ///
  /// Returns a record with:
  /// - className: Name of the class
  /// - filePath: Absolute path to the file containing the class
  /// - classCode: The actual class code (for reference)
  /// - imports: Import statements from the original file
  static Future<CloudFunctionInfo?> _findCloudFunctionClass(
    String functionPath,
  ) async {
    final functionDir = Directory(functionPath);

    if (!functionDir.existsSync()) {
      throw Exception('Function directory does not exist: $functionPath');
    }

    // Collect all .dart files (excluding generated bin/main.dart)
    final allDartFiles = functionDir
        .listSync(recursive: true)
        .where(
          (entity) => entity is File && entity.path.endsWith('.dart'),
          // && !entity.path.contains('bin/main.dart'),
        )
        .cast<File>()
        .toList();

    // Find all cloud function classes across all files
    final List<(CloudFunctionInfo, String)> foundClasses = [];

    for (final file in allDartFiles) {
      final result = await _analyzeFile(file.path, functionPath);
      if (result != null) {
        foundClasses.add((result, file.path));
      }
    }

    // Validate: exactly one cloud function class
    if (foundClasses.isEmpty) {
      return null;
    }

    if (foundClasses.length > 1) {
      final locations = foundClasses
          .map((e) => '${e.$1.className} in ${path.basename(e.$2)}')
          .join(', ');
      throw Exception(
        'Multiple @cloudFunction annotated classes found: $locations. '
        'Only one cloud function class is allowed per deployment.',
      );
    }

    final (info, filePath) = foundClasses.first;
    return (
      className: info.className,
      filePath: filePath,
      classCode: info.classCode,
      imports: info.imports,
      allUserCode: info.allUserCode,
    );
  }

  /// Analyze a Dart file to find @cloudFunction annotated class
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
          allUserCode: visitor.topLevelDeclarations.join('\n\n'),
        );
      }
    } catch (e) {
      if (e is Exception) rethrow;
      print('Failed to analyze file $filePath: $e');
    }

    return null;
  }

  /// Generate main.dart content that invokes the cloud function
  ///
  /// Uses import to reference the cloud function class instead of embedding code.
  /// This keeps the user's source files intact and allows proper dependency resolution.
  ///
  /// If [allUserCode] is provided, all user code (classes, extensions, functions, etc.)
  /// is embedded directly (for bin/main.dart case) instead of importing,
  /// since we're overwriting the original file.
  static String _generateMainDart({
    required String className,
    required String importPath,
    required String userImports,
    String? allUserCode,
  }) {
    // If allUserCode is provided, embed it directly instead of importing
    final importOrEmbed = allUserCode != null && allUserCode.isNotEmpty
        ? '''
// User's code (embedded from original bin/main.dart)
// Includes all classes, extensions, functions, variables, etc.
$allUserCode
'''
        : '''
// Import the cloud function class
import '$importPath';
''';
    final importDefaults = '''
import 'dart:io';
import 'dart:convert';
import 'package:dart_cloud_function/dart_cloud_function.dart';
import 'package:dotenv/dotenv.dart' as dotenv;
''';

    final importDefaultsSet = importDefaults
        .split('import ')
        .map((importEle) => importEle.trim())
        .toSet();
    final userImportsSet = userImports
        .split('import ')
        .map((importEle) => importEle.trim())
        .toSet();

    final imports = importDefaultsSet
        .union(userImportsSet)
        .where((ele) => ele.isNotEmpty)
        .map((importEle) => 'import $importEle')
        .join('\n');

    return '''

// User imports from original function file
// Default imports Auto generated
$imports

/// Auto-generated main.dart for cloud function execution
///
/// This file is generated by the deployment process and should not be modified.
/// It reads the request from /request.json, invokes the cloud function,
/// and writes the response to stdout.
///
/// Environment loading strategy:
/// 1. Load .env.config (injected by container runtime via --env-file)
/// 2. Load .env.secret (for secrets, will be injected in future)
/// 3. Merge with system environment as fallback
void main() async {
  try {
    // Load environment from .env.config and .env.secret files using DotEnv
    // These files are injected by the container runtime as volumes
    final env = _loadEnvironment();

    // Read request from /request.json (mounted by container runtime)
    final requestFile = File('/request.json');
    if (!await requestFile.exists()) {
      _writeError('request.json not found');
      exit(1);
    }

    final requestJson = jsonDecode(await requestFile.readAsString());
    print(requestJson);
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
      env: null,//TODO: implement env
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

/// Load environment variables from .env files using DotEnv package
/// 
/// Priority (highest to lowest):
/// 1. .env.secret - For sensitive data (API keys, passwords)
/// 2. .env.config - For configuration (injected by runtime)
Map<String, String> _loadEnvironment() {
  final env = dotenv.DotEnv();
  
  // Load .env.config if exists (configuration variables)
  final configFile = File('/.env.config');
  if (configFile.existsSync()) {
    env.load(['/.env.config']);
  }
  
  // Load .env.secret if exists (secrets - future use)
  final secretFile = File('/.env.secret');
  if (secretFile.existsSync()) {
    env.load(['/.env.secret']);
  }
  
  return Map<String, String>.from(env.map);
}

void _writeError(String message) {
  final errorResponse = {
    'statusCode': 500,
    'headers': {'content-type': 'application/json'},
    'body': {'error': message},
  };
  stdout.writeln(jsonEncode(errorResponse));
}
$importOrEmbed
''';
  }
}

/// Data class for cloud function class info
class _CloudFunctionClassInfo {
  final String name;
  final String code;
  final String allUserCode;
  final String imports;

  _CloudFunctionClassInfo({
    required this.name,
    required this.code,
    required this.allUserCode,
    required this.imports,
  });
}

/// AST visitor to find and collect classes annotated with @cloudFunction
/// Also collects ALL top-level declarations except main() and imports
class _CloudFunctionVisitor extends RecursiveAstVisitor<void> {
  final List<_CloudFunctionClassInfo> cloudFunctionClasses = [];
  final List<String> imports = [];
  final List<String> topLevelDeclarations = []; // All non-import, non-main code

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
    // Collect ALL classes (including CloudDartFunction class)
    topLevelDeclarations.add(node.toSource());

    if (_isCloudFunctionClass(node)) {
      // Note: allUserCode and imports will be populated after full traversal
      // We store just the class info here, full data is assembled in _analyzeFile
      cloudFunctionClasses.add(
        _CloudFunctionClassInfo(
          name: node.name.lexeme,
          code: node.toSource(),
          allUserCode: '', // Will be set after full traversal
          imports: '', // Will be set after full traversal
        ),
      );
    }
    super.visitClassDeclaration(node);
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    // Collect extension declarations
    topLevelDeclarations.add(node.toSource());
    super.visitExtensionDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Collect all functions EXCEPT main()
    if (node.name.lexeme != 'main') {
      topLevelDeclarations.add(node.toSource());
    }
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    // Collect top-level variables
    topLevelDeclarations.add(node.toSource());
    super.visitTopLevelVariableDeclaration(node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    // Collect typedef declarations
    topLevelDeclarations.add(node.toSource());
    super.visitGenericTypeAlias(node);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    // Collect old-style typedef declarations
    topLevelDeclarations.add(node.toSource());
    super.visitFunctionTypeAlias(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    // Collect mixin declarations
    topLevelDeclarations.add(node.toSource());
    super.visitMixinDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    // Collect enum declarations
    topLevelDeclarations.add(node.toSource());
    super.visitEnumDeclaration(node);
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
