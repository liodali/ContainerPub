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
  final int cloudFunctionCount;
  final bool hasMainFunction;

  AnalysisResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.hasFunctionAnnotation,
    required this.detectedRisks,
    required this.cloudFunctionCount,
    required this.hasMainFunction,
  });

  Map<String, dynamic> toJson() => {
        'isValid': isValid,
        'errors': errors,
        'warnings': warnings,
        'hasFunctionAnnotation': hasFunctionAnnotation,
        'detectedRisks': detectedRisks,
        'cloudFunctionCount': cloudFunctionCount,
        'hasMainFunction': hasMainFunction,
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
    int cloudFunctionCount = 0;
    bool hasMainFunction = false;

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
          cloudFunctionCount: 0,
          hasMainFunction: false,
        );
      }

      // Read the file content
      final content = await File(mainFile).readAsString();

      // Perform static analysis
      final collection = AnalysisContextCollection(
        includedPaths: [path.absolute(functionDir)],
      );

      final context = collection.contextFor(mainFile);
      final result = await context.currentSession.getResolvedUnit(mainFile);

      if (result is ResolvedUnitResult) {
        final visitor = SecurityVisitor();
        result.unit.visitChildren(visitor);

        hasFunctionAnnotation = visitor.hasFunctionAnnotation;
        cloudFunctionCount = visitor.cloudFunctionCount;
        hasMainFunction = visitor.hasMainFunction;
        risks.addAll(visitor.risks);
        warnings.addAll(visitor.warnings);

        // Validate CloudDartFunction requirements
        _validateCloudFunctionRequirements(
          cloudFunctionCount,
          hasMainFunction,
          hasFunctionAnnotation,
          errors,
        );

        // Check for risky patterns in code
        _checkRiskyPatterns(content, risks, warnings);
      }

      final isValid = errors.isEmpty &&
          hasFunctionAnnotation &&
          cloudFunctionCount == 1 &&
          !hasMainFunction;

      return AnalysisResult(
        isValid: isValid,
        errors: errors,
        warnings: warnings,
        hasFunctionAnnotation: hasFunctionAnnotation,
        detectedRisks: risks,
        cloudFunctionCount: cloudFunctionCount,
        hasMainFunction: hasMainFunction,
      );
    } catch (e,trace) {
      errors.add('Analysis failed: $e');
      print(trace);
      return AnalysisResult(
        isValid: false,
        errors: errors,
        warnings: warnings,
        hasFunctionAnnotation: false,
        detectedRisks: risks,
        cloudFunctionCount: 0,
        hasMainFunction: false,
      );
    }
  }

  /// Validate CloudDartFunction requirements
  void _validateCloudFunctionRequirements(
    int cloudFunctionCount,
    bool hasMainFunction,
    bool hasFunctionAnnotation,
    List<String> errors,
  ) {
    // Check for exactly one CloudDartFunction class
    if (cloudFunctionCount == 0) {
      errors.add(
        'No CloudDartFunction class found. You must have exactly one class extending CloudDartFunction',
      );
    } else if (cloudFunctionCount > 1) {
      errors.add(
        'Multiple CloudDartFunction classes found ($cloudFunctionCount). Only one class extending CloudDartFunction is allowed',
      );
    }

    // Check for main function
    if (hasMainFunction) {
      errors.add(
        'main() function is not allowed. Remove the main function from your code',
      );
    }

    // Check for @cloudFunction annotation
    if (cloudFunctionCount == 1 && !hasFunctionAnnotation) {
      errors.add(
        'Missing @cloudFunction annotation. The CloudDartFunction class must be annotated with @cloudFunction',
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
      risks
          .add('Detected Process execution - command execution is not allowed');
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
}

/// AST visitor to detect security issues and validate structure
class SecurityVisitor extends RecursiveAstVisitor<void> {
  bool hasFunctionAnnotation = false;
  int cloudFunctionCount = 0;
  bool hasMainFunction = false;
  final List<String> risks = [];
  final List<String> warnings = [];

  @override
  void visitAnnotation(Annotation node) {
    final name = node.name.toString();
    if (name == 'cloudFunction' || name == 'CloudFunction') {
      hasFunctionAnnotation = true;
    }
    super.visitAnnotation(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // Check if class extends CloudDartFunction
    final extendsClause = node.extendsClause;
    if (extendsClause != null) {
      final superclassType = extendsClause.superclass;
      final superclass = superclassType.toString();
      if (superclass == 'CloudDartFunction') {
        cloudFunctionCount++;
      }
    }
    super.visitClassDeclaration(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Check for main function
    if (node.name.lexeme == 'main') {
      hasMainFunction = true;
    }
    super.visitFunctionDeclaration(node);
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
      warnings.add(
        'dart:io import detected - ensure only HTTP operations are used',
      );
    }

    super.visitImportDirective(node);
  }
}
