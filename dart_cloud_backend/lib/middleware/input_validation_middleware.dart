import 'dart:convert';
import 'package:dart_cloud_backend/handlers/logs_utils/log_utils.dart';
import 'package:dart_cloud_backend/utils/commons.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:zard/zard.dart';

enum ValidationSource {
  body,
  query,
  url,
}

class ValidationRule {
  final String key;
  final ValidationSource source;
  final Schema schema;
  final bool required;

  ValidationRule({
    required this.key,
    required this.source,
    required this.schema,
    this.required = true,
  });
}

class InputValidationMiddleware {
  final List<ValidationRule> rules;

  InputValidationMiddleware(this.rules);

  Handler call(Handler innerHandler) {
    return (Request request) async {
      final errors = <String>[];
      String? cachedBody;

      for (final rule in rules) {
        final error = await _validateRule(request, rule, cachedBody: cachedBody);
        if (error != null) {
          errors.addAll(error);
        }
        if (cachedBody == null && rule.source == ValidationSource.body) {
          cachedBody = await _getCachedBody(request);
        }
      }

      if (errors.isNotEmpty) {
        LogsUtils.log(LogLevels.error.name, 'InputValidationMiddleware', {
          'errors': errors.toString(),
        });
        return Response(
          400,
          body: jsonEncode({
            'error': 'Validation failed',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (cachedBody != null) {
        request = request.change(
          context: {
            ...request.context,
            'cachedBody': cachedBody,
          },
        );
      }

      return innerHandler(request);
    };
  }

  Future<List<String>?> _validateRule(
    Request request,
    ValidationRule rule, {
    String? cachedBody,
  }) async {
    dynamic value;

    switch (rule.source) {
      case ValidationSource.body:
        value = await _getBodyValue(request, rule.key, cachedBody: cachedBody);
        break;
      case ValidationSource.query:
        value = request.url.queryParameters[rule.key];
        break;
      case ValidationSource.url:
        value = request.params[rule.key];
        break;
    }

    if (value == null || (value is String && value.isEmpty)) {
      if (rule.required) {
        return ['${rule.key} is required in ${rule.source.name}'];
      }
      return null;
    }

    try {
      rule.schema.parse(value);
      return null;
    } catch (e) {
      return ['${rule.key}: ${e.toString()}'];
    }
  }

  Future<String> _getCachedBody(Request request) async {
    try {
      return await request.readAsString();
    } catch (e) {
      return '';
    }
  }

  Future<dynamic> _getBodyValue(
    Request request,
    String key, {
    String? cachedBody,
  }) async {
    try {
      final body = cachedBody ?? await request.readAsString();
      if (body.isEmpty) return null;

      final json = jsonDecode(body) as Map<String, dynamic>;
      return json[key];
    } catch (e) {
      return null;
    }
  }
}

class UuidValidationMiddleware extends InputValidationMiddleware {
  UuidValidationMiddleware({
    required String key,
    ValidationSource source = ValidationSource.query,
    bool required = true,
  }) : super([
         ValidationRule(
           key: key,
           source: source,
           schema: z.string().uuidv4(),
           required: required,
         ),
       ]);
}

class EmailValidationMiddleware extends InputValidationMiddleware {
  EmailValidationMiddleware({
    required String key,
    ValidationSource source = ValidationSource.body,
    bool required = true,
  }) : super([
         ValidationRule(
           key: key,
           source: source,
           schema: z.string().email(),
           required: required,
         ),
       ]);
}

class NameValidationMiddleware extends InputValidationMiddleware {
  NameValidationMiddleware({
    required String key,
    ValidationSource source = ValidationSource.body,
    bool required = true,
    int minLength = 2,
    int maxLength = 100,
  }) : super([
         ValidationRule(
           key: key,
           source: source,
           schema: z.string().min(minLength).max(maxLength).trim(),
           required: required,
         ),
       ]);
}

Middleware validateInput(List<ValidationRule> rules) {
  return (Handler innerHandler) => InputValidationMiddleware(rules).call(innerHandler);
}

Middleware validateUuid({
  required String key,
  ValidationSource source = ValidationSource.url,
  bool required = true,
}) {
  return (Handler innerHandler) => UuidValidationMiddleware(
    key: key,
    source: source,
    required: required,
  ).call(innerHandler);
}

Middleware validateEmail({
  required String key,
  ValidationSource source = ValidationSource.body,
  bool required = true,
}) {
  return (Handler innerHandler) => EmailValidationMiddleware(
    key: key,
    source: source,
    required: required,
  ).call(innerHandler);
}

Middleware validateName({
  required String key,
  ValidationSource source = ValidationSource.body,
  bool required = true,
  int minLength = 2,
  int maxLength = 100,
}) {
  return (Handler innerHandler) => NameValidationMiddleware(
    key: key,
    source: source,
    required: required,
    minLength: minLength,
    maxLength: maxLength,
  ).call(innerHandler);
}

/// Retrieve cached request body from context
/// Use this in handlers to access the body that was already read by validation middleware
String? getCachedBody(Request request) {
  return request.context['cachedBody'] as String?;
}

/// Parse cached body as JSON
/// Returns null if body is not cached or cannot be parsed
Map<String, dynamic>? getCachedBodyAsJson(Request request) {
  final body = getCachedBody(request);
  if (body == null || body.isEmpty) return null;

  try {
    return jsonDecode(body) as Map<String, dynamic>;
  } catch (e) {
    return null;
  }
}
