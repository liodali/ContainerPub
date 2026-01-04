import 'dart:io';
import 'package:path/path.dart' as path;

/// Result of function analysis
class AnalysisResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final bool hasFunctionAnnotation;
  final List<String> detectedRisks;

  AnalysisResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.hasFunctionAnnotation,
    required this.detectedRisks,
  });

  Map<String, dynamic> toJson() => {
    'isValid': isValid,
    'errors': errors,
    'warnings': warnings,
    'hasFunctionAnnotation': hasFunctionAnnotation,
    'detectedRisks': detectedRisks,
  };
}

/// Analyzes Dart functions for security and compliance
class FunctionAnalyzer {
  final String functionDir;

  FunctionAnalyzer(this.functionDir);

  /// Analyze the function for security and compliance
  /// Uses regex-based parsing to avoid dependency on Dart SDK internal files
  Future<AnalysisResult> analyze() async {
    final errors = <String>[];
    final warnings = <String>[];
    final risks = <String>[];
    bool hasFunctionAnnotation = false;

    try {
      // Find main.dart file
      String? mainFile;
      final mainDartFile = File(path.join(functionDir, 'main.dart'));
      final binMainDartFile = File(path.join(functionDir, 'bin', 'main.dart'));

      if (await mainDartFile.exists()) {
        mainFile = mainDartFile.path;
      } else if (await binMainDartFile.exists()) {
        mainFile = binMainDartFile.path;
      } else {
        errors.add('No main.dart or bin/main.dart found');
        return AnalysisResult(
          isValid: false,
          errors: errors,
          warnings: warnings,
          hasFunctionAnnotation: false,
          detectedRisks: risks,
        );
      }

      // Read the file content
      final content = await File(mainFile).readAsString();

      // Perform regex-based security analysis
      final securityResult = _RegexSecurityAnalyzer.analyze(content);

      hasFunctionAnnotation = securityResult.hasFunctionAnnotation;
      risks.addAll(securityResult.risks);
      warnings.addAll(securityResult.warnings);

      // Check for @function annotation
      if (!hasFunctionAnnotation) {
        errors.add(
          'Missing @function annotation. Functions must be annotated with @function',
        );
      }

      // Check for risky patterns in code
      _checkRiskyPatterns(content, risks, warnings);

      // Validate function signature using regex
      _validateFunctionSignatureRegex(content, errors, warnings);

      final isValid = errors.isEmpty && hasFunctionAnnotation;

      return AnalysisResult(
        isValid: isValid,
        errors: errors,
        warnings: warnings,
        hasFunctionAnnotation: hasFunctionAnnotation,
        detectedRisks: risks,
      );
    } catch (e) {
      errors.add('Analysis failed: $e');
      return AnalysisResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
        hasFunctionAnnotation: false,
        detectedRisks: risks,
      );
    }
  }

  /// Check for risky patterns in the code
  void _checkRiskyPatterns(
    String content,
    List<String> risks,
    List<String> warnings,
  ) {
    // Check for dangerous Process.run patterns
    if (content.contains('Process.run') ||
        content.contains('Process.start') ||
        content.contains('Process.runSync')) {
      risks.add('Detected Process execution - command execution is not allowed');
    }

    // Check for shell execution
    if (content.contains('Shell') || content.contains('bash')) {
      risks.add('Detected shell execution - not allowed');
    }

    // Check for file system write operations (except allowed patterns)
    if (content.contains('File(') && content.contains('.writeAs')) {
      warnings.add(
        'File write operations detected - ensure they are within function scope',
      );
    }

    // Check for dangerous dart:io operations
    if (content.contains('Platform.executable') || content.contains('Platform.script')) {
      risks.add('Detected platform script access - not allowed');
    }

    // Check for eval-like patterns
    if (content.contains('dart:mirrors')) {
      risks.add('Reflection (dart:mirrors) is not allowed');
    }

    // Check for network operations (allow http client)
    if (content.contains('Socket') || content.contains('ServerSocket')) {
      risks.add('Raw socket operations are not allowed');
    }

    // Check for dart:ffi usage
    if (content.contains('dart:ffi')) {
      risks.add('FFI (Foreign Function Interface) is not allowed');
    }

    // Check for isolate spawning
    if (content.contains('Isolate.spawn')) {
      warnings.add('Isolate spawning detected - may impact performance');
    }
  }

  /// Validate function signature requirements using regex
  void _validateFunctionSignatureRegex(
    String content,
    List<String> errors,
    List<String> warnings,
  ) {
    // Pattern to match handler or main function with parameters
    // Matches: void handler(...), Future<void> handler(...), handler(...), main(...), etc.
    final handlerPattern = RegExp(
      r'(?:void|Future<void>|FutureOr<void>|\w+)?\s*(?:handler|main)\s*\([^)]+\)',
      multiLine: true,
    );

    final hasValidHandler = handlerPattern.hasMatch(content);

    if (!hasValidHandler) {
      warnings.add(
        'No valid handler function found. Expected a function that accepts request parameters',
      );
    }
  }
}

/// Result of regex-based security analysis
class _SecurityAnalysisResult {
  final bool hasFunctionAnnotation;
  final List<String> risks;
  final List<String> warnings;

  _SecurityAnalysisResult({
    required this.hasFunctionAnnotation,
    required this.risks,
    required this.warnings,
  });
}

/// Regex-based security analyzer
/// Replaces AST-based SecurityVisitor to avoid dependency on Dart SDK internal files
class _RegexSecurityAnalyzer {
  /// Analyze source code for security issues using regex
  static _SecurityAnalysisResult analyze(String content) {
    final risks = <String>[];
    final warnings = <String>[];

    // Check for @function or @Function annotation
    final functionAnnotationPattern = RegExp(
      r'@(?:function|Function)(?:\([^)]*\))?',
      multiLine: true,
    );
    final hasFunctionAnnotation = functionAnnotationPattern.hasMatch(content);

    // Check for dangerous imports
    _checkDangerousImports(content, risks, warnings);

    // Check for dangerous method calls
    _checkDangerousMethodCalls(content, risks, warnings);

    return _SecurityAnalysisResult(
      hasFunctionAnnotation: hasFunctionAnnotation,
      risks: risks,
      warnings: warnings,
    );
  }

  /// Check for dangerous imports using regex
  static void _checkDangerousImports(
    String content,
    List<String> risks,
    List<String> warnings,
  ) {
    // Pattern to match import statements
    final importPattern = RegExp(
      r'''import\s+['"]([^'"]+)['"]''',
      multiLine: true,
    );

    for (final match in importPattern.allMatches(content)) {
      final uri = match.group(1) ?? '';

      // Check for dangerous imports
      if (uri == 'dart:mirrors') {
        risks.add('dart:mirrors import is not allowed');
      }

      if (uri == 'dart:ffi') {
        risks.add('dart:ffi import is not allowed');
      }

      if (uri.contains('dart:io') && !uri.contains('dart:io/http')) {
        // Allow dart:io but warn about usage
        warnings.add('dart:io import detected - ensure only HTTP operations are used');
      }
    }
  }

  /// Check for dangerous method calls using regex
  static void _checkDangerousMethodCalls(
    String content,
    List<String> risks,
    List<String> warnings,
  ) {
    // Check for Process.run, Process.start patterns
    final processRunPattern = RegExp(
      r'Process\s*\.\s*(run|start|runSync)\s*\(',
      multiLine: true,
    );
    for (final match in processRunPattern.allMatches(content)) {
      risks.add('Process execution detected: Process.${match.group(1)}');
    }

    // Check for eval-like patterns
    final evalPattern = RegExp(
      r'\.(eval|execute)\s*\(',
      multiLine: true,
    );
    for (final match in evalPattern.allMatches(content)) {
      warnings.add('Dynamic code execution detected: ${match.group(1)}()');
    }
  }
}
