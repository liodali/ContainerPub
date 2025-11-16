import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

final plugin = DartCloudFunctionAnalyzerPlugin();

class DartCloudFunctionAnalyzerPlugin extends Plugin {
  @override
  void register(PluginRegistry registry) {
    registry.registerLintRule(MissingCloudFunctionAnnotationRule());
    registry.registerLintRule(MultipleCloudFunctionAnnotationRule());
    registry.registerLintRule(NoMainFunctionRule());
  }

  @override
  String get name => 'dart_cloud_function_analyzer_plugin';
}

/// Rule to detect missing @cloudFunction annotation on CloudDartFunction classes
class MissingCloudFunctionAnnotationRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'missing_cloud_function_annotation',
    'Classes extending CloudDartFunction must be annotated with @cloudFunction',
    correctionMessage: 'Add @cloudFunction annotation to the class',
  );

  MissingCloudFunctionAnnotationRule()
    : super(
        name: 'missing_cloud_function_annotation',
        description:
            'Detects missing @cloudFunction annotation on CloudDartFunction classes',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _MissingAnnotationVisitor(this, context);
    registry.addClassDeclaration(this, visitor);
  }
}

/// Rule to detect multiple @cloudFunction annotations
class MultipleCloudFunctionAnnotationRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'multiple_cloud_function_annotations',
    'A class cannot have multiple @cloudFunction annotations',
    correctionMessage: 'Remove duplicate @cloudFunction annotations',
  );

  MultipleCloudFunctionAnnotationRule()
    : super(
        name: 'multiple_cloud_function_annotations',
        description:
            'Detects multiple @cloudFunction annotations on the same class',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _MultipleAnnotationVisitor(this, context);
    registry.addClassDeclaration(this, visitor);
  }
}

/// Visitor to detect missing @cloudFunction annotation
class _MissingAnnotationVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final RuleContext context;

  _MissingAnnotationVisitor(this.rule, this.context);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // Check if class extends CloudDartFunction
    if (_extendsCloudDartFunction(node)) {
      // Check if it has @cloudFunction annotation
      if (!_hasCloudFunctionAnnotation(node)) {
        rule.reportAtNode(node);
      }
    }
  }

  /// Check if a class extends CloudDartFunction
  bool _extendsCloudDartFunction(ClassDeclaration node) {
    final extendsClause = node.extendsClause;
    if (extendsClause != null) {
      final superclass = extendsClause.superclass;
      return superclass.name.lexeme == 'CloudDartFunction';
    }
    return false;
  }

  /// Check if a class has @cloudFunction annotation
  bool _hasCloudFunctionAnnotation(ClassDeclaration node) {
    return node.metadata.any((annotation) {
      final name = annotation.name.name;
      return name == 'cloudFunction' || name == 'CloudFunction';
    });
  }
}

/// Visitor to detect multiple @cloudFunction annotations
class _MultipleAnnotationVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final RuleContext context;

  _MultipleAnnotationVisitor(this.rule, this.context);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // Count @cloudFunction annotations
    final cloudFunctionAnnotations = node.metadata.where((annotation) {
      final name = annotation.name.name;
      return name == 'cloudFunction' || name == 'CloudFunction';
    }).toList();

    // Report if more than one
    if (cloudFunctionAnnotations.length > 1) {
      for (var i = 1; i < cloudFunctionAnnotations.length; i++) {
        rule.reportAtNode(cloudFunctionAnnotations[i]);
      }
    }
  }
}

/// Rule to detect main() function in cloud function files
class NoMainFunctionRule extends AnalysisRule {
  static const LintCode code = LintCode(
    'no_main_function_in_cloud_function',
    'Cloud function files should not contain a main() function',
    correctionMessage:
        'Remove the main() function. Cloud functions are invoked by the runtime, not via main().',
  );

  NoMainFunctionRule()
    : super(
        name: 'no_main_function_in_cloud_function',
        description:
            'Detects main() functions in cloud function files which should not have entry points',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _NoMainFunctionVisitor(this, context);
    registry.addFunctionDeclaration(this, visitor);
  }
}

/// Visitor to detect main() function declarations
class _NoMainFunctionVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final RuleContext context;

  _NoMainFunctionVisitor(this.rule, this.context);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Check if this is a main function
    if (node.name.lexeme == 'main') {
      // Check if the file contains a CloudDartFunction class
      if (_fileContainsCloudFunction(node)) {
        rule.reportAtNode(node);
      }
    }
  }

  /// Check if the file contains a class extending CloudDartFunction
  bool _fileContainsCloudFunction(FunctionDeclaration node) {
    // Get the compilation unit by traversing up
    AstNode? current = node;
    while (current != null && current is! CompilationUnit) {
      current = current.parent;
    }

    if (current is CompilationUnit) {
      for (final declaration in current.declarations) {
        if (declaration is ClassDeclaration) {
          final extendsClause = declaration.extendsClause;
          if (extendsClause != null) {
            final superclass = extendsClause.superclass;
            if (superclass.name.lexeme == 'CloudDartFunction') {
              return true;
            }
          }
        }
      }
    }
    return false;
  }
}
