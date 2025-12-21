# Input Validation Middleware Usage Guide

## Overview

The input validation middleware provides a flexible, type-safe way to validate request inputs from body and query parameters using **Zard** (Dart's Zod implementation).

## Features

- **Schema-based validation** - Powered by Zard for robust type validation
- **Multiple validation sources** - Body JSON and query parameters
- **Rich validators** - UUID, email, URL, IP addresses, and more
- **String transformations** - Trim, uppercase, lowercase, normalize
- **Multiple rules** - Validate multiple fields at once
- **Clear error messages** - Detailed validation error responses

## Basic Usage

### 1. Simple Body Validation

```dart
import 'package:shelf_router/shelf_router.dart';
import 'package:dart_cloud_backend/middleware/input_validation_middleware.dart';
import 'package:zard/zard.dart';

final router = Router();

router.post(
  '/users',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'username',
        source: ValidationSource.body,
        schema: z.string().min(3).max(50) as ZardType<dynamic>,
        required: true,
      ),
      ValidationRule(
        key: 'email',
        source: ValidationSource.body,
        schema: z.string().email() as ZardType<dynamic>,
        required: true,
      ),
    ]))
    .addHandler(_createUser),
);
```

### 2. Query Parameter Validation

```dart
router.get(
  '/search',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule<String>(
        key: 'query',
        source: ValidationSource.query,
        required: true,
      ),
      ValidationRule<int>(
        key: 'limit',
        source: ValidationSource.query,
        required: false,
      ),
    ]))
    .addHandler(_search),
);
```

### 3. UUID Validation

```dart
// Validate UUID in query parameter
router.get(
  '/functions',
  Pipeline()
    .addMiddleware(validateUuid(
      key: 'function_id',
      source: ValidationSource.query,
    ))
    .addHandler(_getFunction),
);

// Validate UUID in body
router.post(
  '/deploy',
  Pipeline()
    .addMiddleware(validateUuid(
      key: 'function_id',
      source: ValidationSource.body,
    ))
    .addHandler(_deployFunction),
);
```

### 4. Email Validation

```dart
router.post(
  '/register',
  Pipeline()
    .addMiddleware(validateEmail(
      key: 'email',
      source: ValidationSource.body,
    ))
    .addHandler(_register),
);
```

### 5. Custom Validation Logic

```dart
router.post(
  '/products',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule<int>(
        key: 'price',
        source: ValidationSource.body,
        required: true,
        customValidator: (price) => price > 0,
        customErrorMessage: 'Price must be greater than 0',
      ),
      ValidationRule<String>(
        key: 'category',
        source: ValidationSource.body,
        required: true,
        customValidator: (category) =>
          ['electronics', 'clothing', 'food'].contains(category),
        customErrorMessage: 'Invalid category',
      ),
    ]))
    .addHandler(_createProduct),
);
```

### 6. Multiple Validations

```dart
router.post(
  '/functions/deploy',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule<String>(
        key: 'function_id',
        source: ValidationSource.body,
        required: true,
        customValidator: (id) => UuidValidationMiddleware._isValidUuid(id),
        customErrorMessage: 'function_id must be a valid UUID',
      ),
      ValidationRule<String>(
        key: 'name',
        source: ValidationSource.body,
        required: true,
        customValidator: (name) => name.length >= 3 && name.length <= 50,
        customErrorMessage: 'Name must be between 3 and 50 characters',
      ),
      ValidationRule<Map>(
        key: 'config',
        source: ValidationSource.body,
        required: false,
      ),
    ]))
    .addHandler(_deployFunction),
);
```

### 7. Optional Fields

```dart
router.post(
  '/users',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule<String>(
        key: 'username',
        source: ValidationSource.body,
        required: true,
      ),
      ValidationRule<String>(
        key: 'bio',
        source: ValidationSource.body,
        required: false, // Optional field
      ),
    ]))
    .addHandler(_createUser),
);
```

## Type Support

The middleware supports the following types:

- `String` - Text values
- `int` - Integer numbers (auto-parses from string)
- `double` - Decimal numbers (auto-parses from string)
- `bool` - Boolean values (auto-parses "true"/"false" strings)
- `List` - Array values
- `Map` - Object values

## Error Response Format

When validation fails, the middleware returns a 400 response:

```json
{
  "error": "Validation failed",
  "details": [
    "username is required in body",
    "email must be a valid email address"
  ]
}
```

## Advanced Examples

### Combining Multiple Middleware

```dart
router.post(
  '/api/functions/<function_id>',
  Pipeline()
    .addMiddleware(authMiddleware)
    .addMiddleware(validateUuid(
      key: 'function_id',
      source: ValidationSource.query,
    ))
    .addMiddleware(validateInput([
      ValidationRule<String>(
        key: 'action',
        source: ValidationSource.body,
        required: true,
        customValidator: (action) => ['start', 'stop', 'restart'].contains(action),
        customErrorMessage: 'Action must be one of: start, stop, restart',
      ),
    ]))
    .addHandler(_manageFunctionHandler),
);
```

### Custom Validation Middleware

You can create your own specialized validation middleware:

```dart
class PhoneValidationMiddleware extends InputValidationMiddleware {
  PhoneValidationMiddleware({
    required String key,
    ValidationSource source = ValidationSource.body,
    bool required = true,
    String? customErrorMessage,
  }) : super([
          ValidationRule<String>(
            key: key,
            source: source,
            required: required,
            customErrorMessage:
                customErrorMessage ?? '$key must be a valid phone number',
            customValidator: (value) => _isValidPhone(value),
          ),
        ]);

  static bool _isValidPhone(String value) {
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    return phoneRegex.hasMatch(value);
  }
}

Middleware validatePhone({
  required String key,
  ValidationSource source = ValidationSource.body,
  bool required = true,
  String? customErrorMessage,
}) {
  return PhoneValidationMiddleware(
    key: key,
    source: source,
    required: required,
    customErrorMessage: customErrorMessage,
  ).call;
}
```

## Best Practices

1. **Validate early** - Add validation middleware before business logic
2. **Use specific validators** - Use `validateUuid()`, `validateEmail()` for common patterns
3. **Provide clear messages** - Use `customErrorMessage` for user-friendly errors
4. **Combine validations** - Use multiple `ValidationRule` objects in one middleware
5. **Keep it simple** - Don't over-validate; let your business logic handle complex rules
6. **Type safety** - Use generic types for compile-time safety

## Notes

- Route parameters (path segments) should be validated in handlers, not middleware
- The middleware reads the request body, so ensure it's only used once per request
- Query parameters are always strings and will be auto-parsed for numeric types
- Empty strings are treated as null for validation purposes
