import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

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

      // Perform static analysis
      final collection = AnalysisContextCollection(
        includedPaths: [functionDir],
      );

      final context = collection.contextFor(mainFile);
      final result = await context.currentSession.getResolvedUnit(mainFile);

      if (result is ResolvedUnitResult) {
        final visitor = SecurityVisitor();
        result.unit.visitChildren(visitor);

        hasFunctionAnnotation = visitor.hasFunctionAnnotation;
        risks.addAll(visitor.risks);
        warnings.addAll(visitor.warnings);

        // Check for @function annotation
        if (!hasFunctionAnnotation) {
          errors.add(
              'Missing @function annotation. Functions must be annotated with @function');
        }

        // Check for risky patterns in code
        _checkRiskyPatterns(content, risks, warnings);

        // Validate function signature
        _validateFunctionSignature(result.unit, errors, warnings);
      }

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
          'File write operations detected - ensure they are within function scope');
    }

    // Check for dangerous dart:io operations
    if (content.contains('Platform.executable') ||
        content.contains('Platform.script')) {
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

  /// Validate function signature requirements
  void _validateFunctionSignature(
    CompilationUnit unit,
    List<String> errors,
    List<String> warnings,
  ) {
    bool hasValidHandler = false;

    for (final declaration in unit.declarations) {
      if (declaration is FunctionDeclaration) {
        final name = declaration.name.lexeme;

        // Look for handler function
        if (name == 'handler' || name == 'main') {
          final params = declaration.functionExpression.parameters?.parameters;

          if (params != null && params.isNotEmpty) {
            // Check if it accepts request-like parameters
            hasValidHandler = true;
          }
        }
      }
    }

    if (!hasValidHandler) {
      warnings.add(
          'No valid handler function found. Expected a function that accepts request parameters');
    }
  }
}

/// AST visitor to detect security issues
class SecurityVisitor extends RecursiveAstVisitor<void> {
  bool hasFunctionAnnotation = false;
  final List<String> risks = [];
  final List<String> warnings = [];

  @override
  void visitAnnotation(Annotation node) {
    final name = node.name.toString();
    if (name == 'function' || name == 'Function') {
      hasFunctionAnnotation = true;
    }
    super.visitAnnotation(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;

    // Check for dangerous method calls
    if (methodName == 'run' || methodName == 'start') {
      final target = node.target?.toString() ?? '';
      if (target.contains('Process')) {
        risks.add('Process execution detected: ${node.toString()}');
      }
    }

    // Check for eval-like patterns
    if (methodName == 'eval' || methodName == 'execute') {
      warnings.add('Dynamic code execution detected: ${node.toString()}');
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue ?? '';

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

    super.visitImportDirective(node);
  }
}
