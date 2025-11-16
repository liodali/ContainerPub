import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:dart_cloud_function_analyzer_plugin/src/dart_cloud_function_analyzer_plugin_base.dart';
import 'package:test/test.dart';

void main() {
  group('MissingCloudFunctionAnnotationRule', () {
    test(
      'should report error when class extends CloudDartFunction without annotation',
      () async {
        const code = '''
import 'package:dart_cloud_function/dart_cloud_function.dart';

class TestFunction extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    Map<String, String>? env,
  }) async {
    return CloudResponse.json({'message': 'test'});
  }
}
''';

        final result = parseString(content: code);
        final visitor = _TestMissingAnnotationVisitor();
        result.unit.accept(visitor);

        expect(
          visitor.foundMissingAnnotation,
          isTrue,
          reason: 'Should detect missing @cloudFunction annotation',
        );
      },
    );

    test(
      'should not report error when class has @cloudFunction annotation',
      () async {
        const code = '''
import 'package:dart_cloud_function/dart_cloud_function.dart';

@cloudFunction
class TestFunction extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    Map<String, String>? env,
  }) async {
    return CloudResponse.json({'message': 'test'});
  }
}
''';

        final result = parseString(content: code);
        final visitor = _TestMissingAnnotationVisitor();
        result.unit.accept(visitor);

        expect(
          visitor.foundMissingAnnotation,
          isFalse,
          reason: 'Should not report error when annotation is present',
        );
      },
    );

    test(
      'should not report error for classes not extending CloudDartFunction',
      () async {
        const code = '''
class RegularClass {
  void doSomething() {}
}
''';

        final result = parseString(content: code);
        final visitor = _TestMissingAnnotationVisitor();
        result.unit.accept(visitor);

        expect(
          visitor.foundMissingAnnotation,
          isFalse,
          reason:
              'Should not check classes that do not extend CloudDartFunction',
        );
      },
    );
  });

  group('MultipleCloudFunctionAnnotationRule', () {
    test(
      'should report error when class has multiple @cloudFunction annotations',
      () async {
        const code = '''
import 'package:dart_cloud_function/dart_cloud_function.dart';

@cloudFunction
@cloudFunction
class TestFunction extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    Map<String, String>? env,
  }) async {
    return CloudResponse.json({'message': 'test'});
  }
}
''';

        final result = parseString(content: code);
        final visitor = _TestMultipleAnnotationVisitor();
        result.unit.accept(visitor);

        expect(
          visitor.duplicateAnnotationCount,
          equals(1),
          reason: 'Should detect one duplicate annotation',
        );
      },
    );

    test(
      'should not report error when class has single @cloudFunction annotation',
      () async {
        const code = '''
import 'package:dart_cloud_function/dart_cloud_function.dart';

@cloudFunction
class TestFunction extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    Map<String, String>? env,
  }) async {
    return CloudResponse.json({'message': 'test'});
  }
}
''';

        final result = parseString(content: code);
        final visitor = _TestMultipleAnnotationVisitor();
        result.unit.accept(visitor);

        expect(
          visitor.duplicateAnnotationCount,
          equals(0),
          reason: 'Should not report error for single annotation',
        );
      },
    );
  });

  group('NoMainFunctionRule', () {
    test(
      'should report error when main() exists in cloud function file',
      () async {
        const code = '''
import 'package:dart_cloud_function/dart_cloud_function.dart';

@cloudFunction
class TestFunction extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    Map<String, String>? env,
  }) async {
    return CloudResponse.json({'message': 'test'});
  }
}

void main() {
  print('This should not exist');
}
''';

        final result = parseString(content: code);
        final visitor = _TestNoMainFunctionVisitor();
        result.unit.accept(visitor);

        expect(
          visitor.foundMainFunction,
          isTrue,
          reason: 'Should detect main() function in cloud function file',
        );
      },
    );

    test('should not report error when no main() exists', () async {
      const code = '''
import 'package:dart_cloud_function/dart_cloud_function.dart';

@cloudFunction
class TestFunction extends CloudDartFunction {
  @override
  Future<CloudResponse> handle({
    required CloudRequest request,
    Map<String, String>? env,
  }) async {
    return CloudResponse.json({'message': 'test'});
  }
}
''';

      final result = parseString(content: code);
      final visitor = _TestNoMainFunctionVisitor();
      result.unit.accept(visitor);

      expect(
        visitor.foundMainFunction,
        isFalse,
        reason: 'Should not report error when no main() exists',
      );
    });

    test(
      'should not report error for main() in non-cloud-function files',
      () async {
        const code = '''
class RegularClass {
  void doSomething() {}
}

void main() {
  print('This is fine');
}
''';

        final result = parseString(content: code);
        final visitor = _TestNoMainFunctionVisitor();
        result.unit.accept(visitor);

        expect(
          visitor.foundMainFunction,
          isFalse,
          reason: 'Should not report error for main() in regular files',
        );
      },
    );
  });

  group('Plugin Registration', () {
    test('plugin should have correct name', () {
      expect(plugin.name, equals('dart_cloud_function_analyzer_plugin'));
    });

    test('plugin should be properly instantiated', () {
      expect(plugin, isNotNull);
      expect(plugin, isA<DartCloudFunctionAnalyzerPlugin>());
    });
  });
}

// Test visitors that mimic the actual rule behavior

class _TestMissingAnnotationVisitor extends SimpleAstVisitor<void> {
  bool foundMissingAnnotation = false;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (_extendsCloudDartFunction(node)) {
      if (!_hasCloudFunctionAnnotation(node)) {
        foundMissingAnnotation = true;
      }
    }
    super.visitClassDeclaration(node);
  }

  bool _extendsCloudDartFunction(ClassDeclaration node) {
    final extendsClause = node.extendsClause;
    if (extendsClause != null) {
      final superclass = extendsClause.superclass;
      return superclass.name.lexeme == 'CloudDartFunction';
    }
    return false;
  }

  bool _hasCloudFunctionAnnotation(ClassDeclaration node) {
    return node.metadata.any((annotation) {
      final name = annotation.name.name;
      return name == 'cloudFunction' || name == 'CloudFunction';
    });
  }
}

class _TestMultipleAnnotationVisitor extends SimpleAstVisitor<void> {
  int duplicateAnnotationCount = 0;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final cloudFunctionAnnotations = node.metadata.where((annotation) {
      final name = annotation.name.name;
      return name == 'cloudFunction' || name == 'CloudFunction';
    }).toList();

    if (cloudFunctionAnnotations.length > 1) {
      duplicateAnnotationCount = cloudFunctionAnnotations.length - 1;
    }
    super.visitClassDeclaration(node);
  }
}

class _TestNoMainFunctionVisitor extends SimpleAstVisitor<void> {
  bool foundMainFunction = false;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.name.lexeme == 'main') {
      if (_fileContainsCloudFunction(node)) {
        foundMainFunction = true;
      }
    }
    super.visitFunctionDeclaration(node);
  }

  bool _fileContainsCloudFunction(FunctionDeclaration node) {
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
