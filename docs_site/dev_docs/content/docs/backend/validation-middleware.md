# Input Validation Middleware

The input validation middleware provides a powerful, schema-based validation system for request inputs using **Zard** (Dart's Zod implementation). It validates data from request bodies, query parameters, and URL path parameters with clear error messages and type safety.

## Overview

The validation middleware:

- **Validates multiple sources** - Body JSON, query parameters, and URL path parameters
- **Uses Zard schemas** - Leverages Zard's powerful validation library
- **Caches request body** - Prevents stream consumption issues in handlers
- **Provides helper functions** - Easy access to validated and cached data
- **Logs validation errors** - Automatic error logging for debugging
- **Type-safe** - Compile-time type checking with Dart's type system

## Core Components

### ValidationSource Enum

Specifies where to extract the value from the request:

```dart
enum ValidationSource {
  body,    // JSON request body
  query,   // Query string parameters
  url,     // URL path parameters (e.g., /api/users/<id>)
}
```

### ValidationRule Class

Defines a single validation rule:

```dart
class ValidationRule {
  final String key;                    // Field name to validate
  final ValidationSource source;       // Where to get the value
  final Schema schema;                 // Zard validation schema
  final bool required;                 // Whether field is required
}
```

### Built-in Validators

#### UUID Validation

Validates UUID v4 format in URL parameters:

```dart
router.get(
  '/api/functions/<function_id>',
  Pipeline()
    .addMiddleware(validateUuid(
      key: 'function_id',
      source: ValidationSource.url,  // Default
    ))
    .addHandler(_getFunction),
);
```

#### Email Validation

Validates email format in request body:

```dart
router.post(
  '/api/users',
  Pipeline()
    .addMiddleware(validateEmail(
      key: 'email',
      source: ValidationSource.body,  // Default
    ))
    .addHandler(_createUser),
);
```

#### Name Validation

Validates name fields with configurable length:

```dart
router.post(
  '/api/users',
  Pipeline()
    .addMiddleware(validateName(
      key: 'username',
      source: ValidationSource.body,
      minLength: 3,
      maxLength: 50,
    ))
    .addHandler(_createUser),
);
```

## Custom Validation Rules

Use `validateInput()` to create custom validation rules with Zard schemas:

### String Validation

```dart
router.post(
  '/api/products',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'name',
        source: ValidationSource.body,
        schema: z.string().min(3).max(100).trim(),
        required: true,
      ),
      ValidationRule(
        key: 'description',
        source: ValidationSource.body,
        schema: z.string().max(1000),
        required: false,
      ),
    ]))
    .addHandler(_createProduct),
);
```

### URL Validation

```dart
ValidationRule(
  key: 'website',
  source: ValidationSource.body,
  schema: z.string().url(),
  required: false,
)
```

### Number Validation

```dart
ValidationRule(
  key: 'price',
  source: ValidationSource.body,
  schema: z.number().positive().min(0.01),
  required: true,
)
```

### Network Validators

```dart
// IPv4 address
ValidationRule(
  key: 'ip_address',
  source: ValidationSource.body,
  schema: z.string().ipv4(),
)

// IPv6 address
ValidationRule(
  key: 'ipv6_address',
  source: ValidationSource.body,
  schema: z.string().ipv6(),
)

// MAC address
ValidationRule(
  key: 'mac',
  source: ValidationSource.body,
  schema: z.string().mac(),
)
```

### Hash and Encoding Validators

```dart
// Base64
ValidationRule(
  key: 'data',
  source: ValidationSource.body,
  schema: z.string().base64(),
)

// Hexadecimal
ValidationRule(
  key: 'color',
  source: ValidationSource.body,
  schema: z.string().hex(),
)

// SHA256 hash
ValidationRule(
  key: 'hash',
  source: ValidationSource.body,
  schema: z.string().hash('sha256'),
)

// JWT token
ValidationRule(
  key: 'token',
  source: ValidationSource.body,
  schema: z.string().jwt(),
)
```

### Date/Time Validation (ISO 8601)

```dart
// ISO date (YYYY-MM-DD)
ValidationRule(
  key: 'date',
  source: ValidationSource.body,
  schema: z.iso.date(),
)

// ISO datetime
ValidationRule(
  key: 'timestamp',
  source: ValidationSource.body,
  schema: z.iso.datetime(),
)

// ISO duration (P1DT2H3M4S)
ValidationRule(
  key: 'duration',
  source: ValidationSource.body,
  schema: z.iso.duration(),
)
```

### String Transformations

```dart
// Trim whitespace
ValidationRule(
  key: 'username',
  source: ValidationSource.body,
  schema: z.string().trim().min(1),
)

// Convert to lowercase
ValidationRule(
  key: 'email',
  source: ValidationSource.body,
  schema: z.string().toLowerCase().email(),
)

// Normalize (remove accents, trim, collapse whitespace)
ValidationRule(
  key: 'name',
  source: ValidationSource.body,
  schema: z.string().normalize(),
)
```

## Multiple Validations

Combine multiple rules in a single middleware:

```dart
router.post(
  '/api/functions/deploy',
  Pipeline()
    .addMiddleware(validateInput([
      // URL parameter validation
      ValidationRule(
        key: 'function_id',
        source: ValidationSource.url,
        schema: z.string().uuidv4(),
        required: true,
      ),
      // Body validations
      ValidationRule(
        key: 'name',
        source: ValidationSource.body,
        schema: z.string().min(3).max(50).trim(),
        required: true,
      ),
      ValidationRule(
        key: 'memory',
        source: ValidationSource.body,
        schema: z.number().int().min(128).max(4096),
        required: false,
      ),
      // Query validations
      ValidationRule(
        key: 'force',
        source: ValidationSource.query,
        schema: z.stringbool(),
        required: false,
      ),
    ]))
    .addHandler(_deployFunction),
);
```

## Accessing Validated Data in Handlers

The middleware caches the request body in the request context, making it available to handlers:

```dart
Future<Response> _createUser(Request request) async {
  // Get cached body as JSON
  final body = getCachedBodyAsJson(request);

  if (body == null) {
    return Response.badRequest();
  }

  final username = body['username'] as String;
  final email = body['email'] as String;

  // Process validated data
  return Response.ok('User created');
}

// Or get raw body string
Future<Response> _processData(Request request) async {
  final bodyString = getCachedBody(request);
  // Use the cached body string
}
```

## Error Response Format

When validation fails, the middleware returns a 400 response with error details:

```json
{
  "error": "Validation failed"
}
```

Errors are automatically logged with the `LogsUtils` system for debugging:

```
[ERROR] InputValidationMiddleware: {
  "errors": "[username: String must be at least 3 characters, email: Invalid email format]"
}
```

## Real-World Examples

### User Registration

```dart
router.post(
  '/api/auth/register',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'username',
        source: ValidationSource.body,
        schema: z.string().min(3).max(20).trim(),
        required: true,
      ),
      ValidationRule(
        key: 'email',
        source: ValidationSource.body,
        schema: z.string().email(),
        required: true,
      ),
      ValidationRule(
        key: 'password',
        source: ValidationSource.body,
        schema: z.string().min(8),
        required: true,
      ),
    ]))
    .addHandler(_register),
);
```

### API Key Management

```dart
router.get(
  '/api/apikey/<function_id>',
  Pipeline()
    .addMiddleware(authMiddleware)
    .addMiddleware(validateUuid(
      key: 'function_id',
      source: ValidationSource.url,
    ))
    .addHandler((req) => ApiKeyHandler.getApiKeyInfo(
      req,
      req.params['function_id']!,
    )),
);
```

### Function Deployment

```dart
router.post(
  '/api/functions/deploy',
  Pipeline()
    .addMiddleware(authMiddleware)
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'function_id',
        source: ValidationSource.body,
        schema: z.string().uuidv4(),
        required: true,
      ),
      ValidationRule(
        key: 'name',
        source: ValidationSource.body,
        schema: z.string().min(3).max(100).trim(),
        required: true,
      ),
      ValidationRule(
        key: 'memory',
        source: ValidationSource.body,
        schema: z.number().int().min(128).max(4096),
        required: false,
      ),
    ]))
    .addHandler(_deployFunction),
);
```

## Available Zard Validators

### String Validators

- `z.string()` - Basic string
- `.min(n)` - Minimum length
- `.max(n)` - Maximum length
- `.email()` - Email format
- `.url()` - URL format
- `.httpUrl()` - HTTP/HTTPS URL only
- `.uuidv4()` - UUID v4 format
- `.guid()` - GUID format
- `.nanoid()` - Nano ID (21 chars)
- `.ulid()` - ULID format
- `.hostname()` - Valid hostname
- `.ipv4()` - IPv4 address
- `.ipv6()` - IPv6 address
- `.mac()` - MAC address
- `.cidrv4()` - CIDR IPv4 notation
- `.cidrv6()` - CIDR IPv6 notation
- `.base64()` - Base64 encoded
- `.base64url()` - Base64 URL-safe
- `.hex()` - Hexadecimal
- `.hash(algorithm)` - Hash (sha1, sha256, sha384, sha512, md5)
- `.jwt()` - JSON Web Token
- `.emoji()` - Single emoji character

### String Transformations

- `.trim()` - Remove leading/trailing whitespace
- `.toLowerCase()` - Convert to lowercase
- `.toUpperCase()` - Convert to uppercase
- `.normalize()` - Remove accents, trim, collapse whitespace

### Number Validators

- `z.number()` - Any number
- `.int()` - Integer only
- `.positive()` - Greater than 0
- `.negative()` - Less than 0
- `.min(n)` - Minimum value
- `.max(n)` - Maximum value

### Boolean Validators

- `z.boolean()` - Boolean value
- `z.stringbool()` - String to boolean (accepts: 1, true, yes, on, y, enabled / 0, false, no, off, n, disabled)

### Date/Time Validators (ISO 8601)

- `z.iso.date()` - ISO date (YYYY-MM-DD)
- `z.iso.time()` - ISO time (HH:mm:ss)
- `z.iso.datetime()` - ISO datetime
- `z.iso.duration()` - ISO duration (P1DT2H3M4S)

## Best Practices

1. **Validate early** - Add validation middleware before business logic handlers
2. **Use specific validators** - Leverage built-in validators for common patterns (UUID, email, etc.)
3. **Chain validators** - Combine multiple validations (e.g., `.min(3).max(50).trim()`)
4. **Mark optional fields** - Set `required: false` for optional fields
5. **Transform data** - Use transformations like `.trim()`, `.toLowerCase()` for cleaner data
6. **Separate concerns** - Keep validation middleware separate from business logic
7. **Log errors** - Validation errors are automatically logged for debugging
8. **Cache body** - Use `getCachedBodyAsJson()` in handlers to access validated data

## Implementation Details

### Body Caching

The middleware caches the request body on first read to prevent stream consumption issues:

```dart
// Middleware caches body
if (cachedBody == null && rule.source == ValidationSource.body) {
  cachedBody = await _getCachedBody(request);
}

// Attach to request context
request = request.change(context: {
  ...request.context,
  'cachedBody': cachedBody,
});
```

### Error Logging

Validation errors are automatically logged:

```dart
LogsUtils.log(LogLevels.error.name, 'InputValidationMiddleware', {
  'errors': errors.toString(),
});
```

### URL Parameter Validation

URL parameters are extracted using Shelf Router's `request.params`:

```dart
case ValidationSource.url:
  value = request.params[rule.key];
  break;
```

## Files

- **Implementation**: `lib/middleware/input_validation_middleware.dart`
- **Routes using validation**: `lib/routers/api_key_routes.dart`
- **Helper functions**: `getCachedBody()`, `getCachedBodyAsJson()`

## See Also

- [Zard Documentation](https://pub.dev/packages/zard) - Complete Zard schema validation library
- [Shelf Router Documentation](https://pub.dev/packages/shelf_router) - HTTP routing
- [Backend Architecture](./architecture.md) - System architecture overview
