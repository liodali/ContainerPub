import 'dart:io';
import 'package:path/path.dart' as path;

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

  /// Analyze a Dart file to find @cloudFunction annotated class using regex
  /// This avoids dependency on Dart SDK internal files which aren't available in compiled binaries
  static Future<CloudFunctionInfo?> _analyzeFile(
    String filePath,
    String functionPath,
  ) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return null;
      }

      final content = file.readAsStringSync();
      final result = _RegexDartParser.parse(content);

      // Validate: exactly one cloud function class
      if (result.cloudFunctionClasses.isEmpty) {
        return null;
      }

      if (result.cloudFunctionClasses.length > 1) {
        throw Exception(
          'Multiple @cloudFunction annotated classes found in ${path.basename(filePath)}: '
          '${result.cloudFunctionClasses.map((c) => c.name).join(", ")}. '
          'Only one cloud function class is allowed.',
        );
      }

      final cloudFunction = result.cloudFunctionClasses.first;

      return (
        className: cloudFunction.name,
        filePath: filePath,
        classCode: cloudFunction.code,
        imports: result.imports.join('\n'),
        allUserCode: result.topLevelDeclarations.join('\n\n'),
      );
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
import 'package:dart_cloud_logger/dart_cloud_logger.dart';
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
/// It reads the request from the current working directory, invokes the cloud function,
/// and writes the response to the current working directory.
///
/// The container's working directory is set to the shared volume path by the runtime,
/// so all file operations use relative paths (./logs.json, ./result.json, etc.)
///
/// Environment loading strategy:
/// 1. Load .env.config from current directory (injected by container runtime)
/// 2. Load .env.secret (for secrets, will be injected in future)
/// 3. Merge with system environment as fallback
void main() async {
  // Load environment from current working directory
  final env = _loadEnvironment();
  
  // Create logger for container execution (writes to current directory)
  final logger = CloudLogger.forContainer();
  
  // Create logs.json and result.json files in current directory
  await _initializeOutputFiles();
  
  try {
    logger.info('Function execution started');

    // Read request from current working directory
    final requestFile = File('./request.json');
    if (!await requestFile.exists()) {
      logger.error('request.json not found in current directory');
      await _flushLogsAndWriteError(logger, 'request.json not found');
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

    // Execute the function with logger
    final response = await function.handle(
      request: request,
      logger: logger,
      env: env,
    );

    logger.info('Function execution completed', metadata: {'statusCode': response.statusCode});

    // Write response to result.json in current working directory
    final responseJson = {
      'statusCode': response.statusCode,
      'headers': response.headers,
      'body': response.body,
    };

    final resultFile = File('./result.json');
    await resultFile.writeAsString(jsonEncode(responseJson));
    
    // Flush logs to shared volume before exit
    await logger.flush();
    
    stdout.writeln(jsonEncode(responseJson));
    exit(0);
  } catch (e, stackTrace) {
    logger.error('Function execution failed: \$e', metadata: {'stackTrace': '\$stackTrace'});
    await _flushLogsAndWriteError(logger, 'Function execution failed: \$e\\n\$stackTrace');
    exit(1);
  }
}

/// Initialize output files (logs.json and result.json) in current working directory
Future<void> _initializeOutputFiles() async {
  final logsFile = File('./logs.json');
  final resultFile = File('./result.json');
  
  // Create empty files if they don't exist
  if (!await logsFile.exists()) {
    await logsFile.writeAsString('{}');
  }
  if (!await resultFile.exists()) {
    await resultFile.writeAsString('{}');
  }
}

/// Flush logs and write error response
Future<void> _flushLogsAndWriteError(CloudLogger logger, String message) async {
  await logger.flush();
  await _writeError(message);
}

/// Load environment variables from .env files using DotEnv package
/// 
/// Priority (highest to lowest):
/// 1. .env.secret - For sensitive data (API keys, passwords)
/// 2. .env.config - For configuration (injected by runtime)
///
/// Files are loaded from the current working directory
Map<String, String> _loadEnvironment() {
  final env = dotenv.DotEnv();
  
  // Load .env.config from current working directory
  final configFile = File('./.env.config');
  if (configFile.existsSync()) {
    env.load(['./.env.config']);
  }
  
  // Load .env.secret if exists (secrets - future use)
  final secretFile = File('./.env.secret');
  if (secretFile.existsSync()) {
    env.load(['./.env.secret']);
  }
  
  return Map<String, String>.from(env.map);
}

Future<void> _writeError(String message) async {
  final errorResponse = {
    'statusCode': 500,
    'headers': {'content-type': 'application/json'},
    'body': {'error': message},
  };
  final resultFile = File('./result.json');
  await resultFile.writeAsString(jsonEncode(errorResponse));
}

// ============================================================================
// CloudLogger - Embedded logging utility for cloud functions
// ============================================================================

/// Log entry with timestamp and optional metadata
class _LogEntry {
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final LoggerTypeAction level;

  _LogEntry({
    required this.message,
    required this.timestamp,
    required this.level,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        if (metadata != null && metadata!.isNotEmpty) 'metadata': metadata,
      };
}

/// Cloud logger that writes logs to a JSON file in the current working directory
/// Logs are structured into three sections: error, debug, info
class CloudLogger extends CloudDartFunctionLogger {
  final String _logFilePath;
  final List<_LogEntry> _errors = [];
  final List<_LogEntry> _debugLogs = [];
  final List<_LogEntry> _infoLogs = [];

  CloudLogger({String logFilePath = './logs.json'}) : _logFilePath = logFilePath;

  factory CloudLogger.forContainer() => 
      CloudLogger(logFilePath: './logs.json');

  @override
  void printLog(LoggerTypeAction level, String message, {Map<String, dynamic>? metadata}) {
    final entry = _LogEntry(
      message: message,
      timestamp: DateTime.now(),
      level: level,
      metadata: metadata,
    );
    switch (level) {
      case LoggerTypeAction.error:
        _errors.add(entry);
        break;
      case LoggerTypeAction.debug:
        _debugLogs.add(entry);
        break;
      case LoggerTypeAction.info:
        _infoLogs.add(entry);
        break;
    }
  }

  Map<String, dynamic> toJson() => {
        'error': _errors.map((e) => e.toJson()).toList(),
        'debug': _debugLogs.map((e) => e.toJson()).toList(),
        'info': _infoLogs.map((e) => e.toJson()).toList(),
      };

  Future<void> flush() async {
    final file = File(_logFilePath);
    await file.writeAsString(jsonEncode(toJson()));
  }

  void flushSync() {
    final file = File(_logFilePath);
    file.writeAsStringSync(jsonEncode(toJson()));
  }
}

$importOrEmbed
''';
  }
}

/// Data class for cloud function class info
class _CloudFunctionClassInfo {
  final String name;
  final String code;

  _CloudFunctionClassInfo({
    required this.name,
    required this.code,
  });
}

/// Result of regex-based Dart file parsing
class _RegexParseResult {
  final List<_CloudFunctionClassInfo> cloudFunctionClasses;
  final List<String> imports;
  final List<String> topLevelDeclarations;

  _RegexParseResult({
    required this.cloudFunctionClasses,
    required this.imports,
    required this.topLevelDeclarations,
  });
}

/// Regex-based Dart file parser
///
/// This parser extracts:
/// - Import statements
/// - Classes with @cloudFunction annotation that extend CloudDartFunction
/// - All top-level declarations (classes, functions, enums, mixins, extensions, typedefs, variables)
/// - Excludes main() function from top-level declarations
class _RegexDartParser {
  // Regex patterns
  static final _importPattern = RegExp(
    r'''import\s+['"]([^'"]+)['"](?:\s+as\s+\w+)?(?:\s+show\s+[^;]+)?(?:\s+hide\s+[^;]+)?\s*;''',
    multiLine: true,
  );

  static final _exportPattern = RegExp(
    r'''export\s+['"]([^'"]+)['"](?:\s+show\s+[^;]+)?(?:\s+hide\s+[^;]+)?\s*;''',
    multiLine: true,
  );

  static final _partPattern = RegExp(
    r'''part\s+['"]([^'"]+)['"]\s*;''',
    multiLine: true,
  );

  static final _partOfPattern = RegExp(
    r'''part\s+of\s+['"]?([^'"\s;]+)['"]?\s*;''',
    multiLine: true,
  );

  /// Parse Dart source code and extract relevant information
  static _RegexParseResult parse(String source) {
    // Remove comments to avoid false matches
    final cleanSource = _removeComments(source);

    final imports = <String>[];
    final topLevelDeclarations = <String>[];
    final cloudFunctionClasses = <_CloudFunctionClassInfo>[];

    // Extract imports (excluding dart_cloud_function)
    for (final match in _importPattern.allMatches(source)) {
      final importUri = match.group(1) ?? '';
      if (!importUri.contains('dart_cloud_function')) {
        imports.add(match.group(0)!);
      }
    }

    // Extract exports
    for (final match in _exportPattern.allMatches(source)) {
      topLevelDeclarations.add(match.group(0)!);
    }

    // Extract part directives
    for (final match in _partPattern.allMatches(source)) {
      topLevelDeclarations.add(match.group(0)!);
    }

    // Extract part of directives
    for (final match in _partOfPattern.allMatches(source)) {
      topLevelDeclarations.add(match.group(0)!);
    }

    // Find all top-level declarations using brace matching
    final declarations = _extractTopLevelDeclarations(cleanSource);

    for (final decl in declarations) {
      final trimmed = decl.trim();
      if (trimmed.isEmpty) continue;

      // Check if it's a main function - skip it
      if (_isMainFunction(trimmed)) {
        continue;
      }

      // Check if it's a cloud function class
      final cloudFunctionInfo = _extractCloudFunctionClass(trimmed);
      if (cloudFunctionInfo != null) {
        cloudFunctionClasses.add(cloudFunctionInfo);
      }

      // Add to top-level declarations (all declarations except main)
      topLevelDeclarations.add(trimmed);
    }

    return _RegexParseResult(
      cloudFunctionClasses: cloudFunctionClasses,
      imports: imports,
      topLevelDeclarations: topLevelDeclarations,
    );
  }

  /// Remove single-line and multi-line comments from source
  static String _removeComments(String source) {
    // Remove multi-line comments /* ... */
    var result = source.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
    // Remove single-line comments // ...
    result = result.replaceAll(RegExp(r'//[^\n]*'), '');
    return result;
  }

  /// Check if a declaration is the main() function
  static bool _isMainFunction(String declaration) {
    // Match: void main(...) or main(...) or Future<void> main(...) etc.
    final mainPattern = RegExp(
      r'^(?:(?:void|Future<void>|FutureOr<void>)\s+)?main\s*\(',
      multiLine: true,
    );
    return mainPattern.hasMatch(declaration);
  }

  /// Extract cloud function class info if the declaration is a @cloudFunction class
  static _CloudFunctionClassInfo? _extractCloudFunctionClass(String declaration) {
    // Pattern to match @cloudFunction or @CloudFunction annotation followed by class
    // that extends CloudDartFunction
    final pattern = RegExp(
      r'@(?:cloudFunction|CloudFunction)(?:\([^)]*\))?\s*'
      r'class\s+(\w+)\s+extends\s+CloudDartFunction',
      multiLine: true,
      dotAll: true,
    );

    final match = pattern.firstMatch(declaration);
    if (match != null) {
      return _CloudFunctionClassInfo(
        name: match.group(1)!,
        code: declaration,
      );
    }
    return null;
  }

  /// Extract all top-level declarations from source code
  /// Uses brace matching to correctly handle nested structures
  static List<String> _extractTopLevelDeclarations(String source) {
    final declarations = <String>[];
    final lines = source.split('\n');

    var currentDeclaration = StringBuffer();
    var braceCount = 0;
    var inDeclaration = false;
    var inString = false;
    String? stringDelimiter;
    var isRawString = false;
    var isMultilineString = false;

    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      final trimmedLine = line.trim();

      // Skip empty lines when not in a declaration
      if (!inDeclaration && trimmedLine.isEmpty) continue;

      // Skip import/export/part/library directives (handled separately)
      if (!inDeclaration && _isDirective(trimmedLine)) continue;

      // Check if this line starts a new top-level declaration
      if (!inDeclaration && _startsTopLevelDeclaration(trimmedLine)) {
        inDeclaration = true;
        currentDeclaration = StringBuffer();
        braceCount = 0;
      }

      if (inDeclaration) {
        currentDeclaration.writeln(line);

        // Count braces, handling strings properly
        for (var i = 0; i < line.length; i++) {
          final char = line[i];
          final prevChar = i > 0 ? line[i - 1] : '';
          final nextChar = i < line.length - 1 ? line[i + 1] : '';
          final nextNextChar = i < line.length - 2 ? line[i + 2] : '';

          // Handle string detection
          if (!inString) {
            // Check for raw string
            if (char == 'r' && (nextChar == '"' || nextChar == "'")) {
              isRawString = true;
              continue;
            }

            // Check for multiline string
            if ((char == '"' && nextChar == '"' && nextNextChar == '"') ||
                (char == "'" && nextChar == "'" && nextNextChar == "'")) {
              inString = true;
              isMultilineString = true;
              stringDelimiter = char;
              i += 2; // Skip the next two quotes
              continue;
            }

            // Check for regular string
            if (char == '"' || char == "'") {
              inString = true;
              stringDelimiter = char;
              isMultilineString = false;
              continue;
            }
          } else {
            // We're in a string - check for end
            if (!isRawString && prevChar == '\\') {
              // Escaped character, skip
              continue;
            }

            if (isMultilineString) {
              if (char == stringDelimiter &&
                  nextChar == stringDelimiter &&
                  nextNextChar == stringDelimiter) {
                inString = false;
                isMultilineString = false;
                isRawString = false;
                i += 2;
              }
            } else {
              if (char == stringDelimiter) {
                inString = false;
                isRawString = false;
              }
            }
            continue;
          }

          // Count braces only when not in string
          if (char == '{') {
            braceCount++;
          } else if (char == '}') {
            braceCount--;
          }
        }

        // Check if declaration is complete
        // A declaration is complete when braces are balanced and we've seen at least one brace
        // OR when we hit a semicolon at top level (for simple declarations like typedefs)
        if (braceCount == 0 && currentDeclaration.isNotEmpty) {
          final declStr = currentDeclaration.toString().trim();

          // Check if it's a complete declaration
          // - Has balanced braces (class, function with body, enum, etc.)
          // - Or ends with semicolon (typedef, top-level variable, abstract class method)
          if (declStr.contains('{') || declStr.endsWith(';')) {
            if (declStr.isNotEmpty && !_isDirective(declStr)) {
              declarations.add(declStr);
            }
            inDeclaration = false;
            currentDeclaration = StringBuffer();
          }
        }
      }
    }

    // Handle any remaining declaration
    if (currentDeclaration.isNotEmpty) {
      final declStr = currentDeclaration.toString().trim();
      if (declStr.isNotEmpty && !_isDirective(declStr)) {
        declarations.add(declStr);
      }
    }

    return declarations;
  }

  /// Check if a line is an import/export/part/library directive
  static bool _isDirective(String line) {
    final trimmed = line.trim();
    return trimmed.startsWith('import ') ||
        trimmed.startsWith('export ') ||
        trimmed.startsWith('part ') ||
        trimmed.startsWith('library ');
  }

  /// Check if a line starts a top-level declaration
  static bool _startsTopLevelDeclaration(String line) {
    final trimmed = line.trim();

    // Skip directives
    if (_isDirective(trimmed)) return false;

    // Check for annotations (may precede a declaration)
    if (trimmed.startsWith('@')) return true;

    // Check for class, enum, mixin, extension, typedef
    if (trimmed.startsWith('class ') ||
        trimmed.startsWith('abstract class ') ||
        trimmed.startsWith('abstract interface class ') ||
        trimmed.startsWith('abstract base class ') ||
        trimmed.startsWith('abstract final class ') ||
        trimmed.startsWith('base class ') ||
        trimmed.startsWith('final class ') ||
        trimmed.startsWith('sealed class ') ||
        trimmed.startsWith('interface class ') ||
        trimmed.startsWith('mixin class ') ||
        trimmed.startsWith('mixin ') ||
        trimmed.startsWith('enum ') ||
        trimmed.startsWith('extension ') ||
        trimmed.startsWith('typedef ')) {
      return true;
    }

    // Check for top-level functions and variables
    // These typically start with a type or 'void', 'dynamic', 'var', 'final', 'const', 'late'
    final topLevelPattern = RegExp(
      r'^(?:void|dynamic|var|final|const|late|Future|FutureOr|Stream|[A-Z]\w*(?:<[^>]+>)?|\w+)\s+\w+',
    );
    if (topLevelPattern.hasMatch(trimmed)) {
      return true;
    }

    return false;
  }
}
