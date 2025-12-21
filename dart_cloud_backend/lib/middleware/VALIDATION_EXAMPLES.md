# Zard-Based Validation Middleware Examples

## Quick Start

```dart
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:zard/zard.dart';
import 'package:dart_cloud_backend/middleware/input_validation_middleware.dart';

final router = Router();
```

## Built-in Validators

### UUID Validation

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

### Email Validation

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

## Custom Zard Schemas

### String Validation

```dart
// Min/max length
router.post(
  '/users',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'username',
        source: ValidationSource.body,
        schema: z.string().min(3).max(20) as ZardType<dynamic>,
      ),
      ValidationRule(
        key: 'password',
        source: ValidationSource.body,
        schema: z.string().min(8) as ZardType<dynamic>,
      ),
    ]))
    .addHandler(_createUser),
);

// URL validation
router.post(
  '/webhooks',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'url',
        source: ValidationSource.body,
        schema: z.string().url() as ZardType<dynamic>,
      ),
    ]))
    .addHandler(_createWebhook),
);

// HTTP URL only
router.post(
  '/api-endpoints',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'endpoint',
        source: ValidationSource.body,
        schema: z.string().httpUrl() as ZardType<dynamic>,
      ),
    ]))
    .addHandler(_addEndpoint),
);
```

### Number Validation

```dart
router.post(
  '/products',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'price',
        source: ValidationSource.body,
        schema: z.number().positive() as ZardType<dynamic>,
      ),
      ValidationRule(
        key: 'quantity',
        source: ValidationSource.body,
        schema: z.number().int().min(0) as ZardType<dynamic>,
      ),
      ValidationRule(
        key: 'discount',
        source: ValidationSource.body,
        schema: z.number().min(0).max(100) as ZardType<dynamic>,
        required: false,
      ),
    ]))
    .addHandler(_createProduct),
);
```

### Boolean Validation

```dart
router.post(
  '/settings',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'enabled',
        source: ValidationSource.body,
        schema: z.boolean() as ZardType<dynamic>,
      ),
    ]))
    .addHandler(_updateSettings),
);

// String to boolean conversion
router.post(
  '/toggle',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'active',
        source: ValidationSource.query,
        schema: z.stringbool() as ZardType<dynamic>,
      ),
    ]))
    .addHandler(_toggleFeature),
);
```

### Network Validators

```dart
// IPv4 address
router.post(
  '/whitelist',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'ip_address',
        source: ValidationSource.body,
        schema: z.string().ipv4() as ZardType<dynamic>,
      ),
    ]))
    .addHandler(_addToWhitelist),
);

// IPv6 address
router.post(
  '/ipv6-config',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'address',
        source: ValidationSource.body,
        schema: z.string().ipv6() as ZardType<dynamic>,
      ),
    ]))
    .addHandler(_configureIPv6),
);

// MAC address
router.post(
  '/devices',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'mac_address',
        source: ValidationSource.body,
        schema: z.string().mac() as ZardType<dynamic>,
      ),
    ]))
    .addHandler(_registerDevice),
);

// CIDR notation
router.post(
  '/subnets',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'cidr',
        source: ValidationSource.body,
        schema: z.string().cidrv4() as ZardType<dynamic>,
      ),
    ]))
    .addHandler(_createSubnet),
);
```

### Hash and Encoding Validators

```dart
// Base64
router.post(
  '/upload',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'data',
        source: ValidationSource.body,
        schema: z.string().base64() as ZardType<dynamic>,
      ),
    ]))
    .addHandler(_uploadData),
);

// Hexadecimal
router.post(
  '/colors',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'color',
        source: ValidationSource.body,
        schema: z.string().hex() as ZardType<dynamic>,
      ),
    ]))
    .addHandler(_setColor),
);

// SHA256 hash
router.post(
  '/verify',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'hash',
        source: ValidationSource.body,
        schema: z.string().hash('sha256') as ZardType<dynamic>,
      ),
    ]))
    .addHandler(_verifyHash),
);

// JWT token
router.post(
  '/validate-token',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'token',
        source: ValidationSource.body,
        schema: z.string().jwt() as ZardType<dynamic>,
      ),
    ]))
    .addHandler(_validateToken),
);
```

### String Transformations

```dart
// Trim whitespace
router.post(
  '/search',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'query',
        source: ValidationSource.body,
        schema: z.string().trim().min(1) as ZardType<dynamic>,
      ),
    ]))
    .addHandler(_search),
);

// Convert to lowercase
router.post(
  '/tags',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'tag',
        source: ValidationSource.body,
        schema: z.string().toLowerCase() as ZardType<dynamic>,
      ),
    ]))
    .addHandler(_addTag),
);

// Normalize (remove accents, trim, collapse whitespace)
router.post(
  '/normalize',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'text',
        source: ValidationSource.body,
        schema: z.string().normalize() as ZardType<dynamic>,
      ),
    ]))
    .addHandler(_normalizeText),
);
```

### Date/Time Validation (ISO 8601)

```dart
// ISO date (YYYY-MM-DD)
router.post(
  '/events',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'date',
        source: ValidationSource.body,
        schema: z.iso.date() as ZardType<dynamic>,
      ),
    ]))
    .addHandler(_createEvent),
);

// ISO time (HH:mm:ss)
router.post(
  '/schedule',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'time',
        source: ValidationSource.body,
        schema: z.iso.time() as ZardType<dynamic>,
      ),
    ]))
    .addHandler(_scheduleTask),
);

// ISO datetime
router.post(
  '/appointments',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'datetime',
        source: ValidationSource.body,
        schema: z.iso.datetime() as ZardType<dynamic>,
      ),
    ]))
    .addHandler(_bookAppointment),
);

// ISO duration (P1DT2H3M4S)
router.post(
  '/timers',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'duration',
        source: ValidationSource.body,
        schema: z.iso.duration() as ZardType<dynamic>,
      ),
    ]))
    .addHandler(_setTimer),
);
```

### Complex Validation

```dart
// Multiple fields with different sources
router.post(
  '/api/functions/deploy',
  Pipeline()
    .addMiddleware(validateInput([
      // Body validations
      ValidationRule(
        key: 'function_id',
        source: ValidationSource.body,
        schema: z.string().uuid() as ZardType<dynamic>,
      ),
      ValidationRule(
        key: 'name',
        source: ValidationSource.body,
        schema: z.string().min(3).max(50) as ZardType<dynamic>,
      ),
      ValidationRule(
        key: 'memory',
        source: ValidationSource.body,
        schema: z.number().int().min(128).max(4096) as ZardType<dynamic>,
        required: false,
      ),
      // Query validations
      ValidationRule(
        key: 'force',
        source: ValidationSource.query,
        schema: z.stringbool() as ZardType<dynamic>,
        required: false,
      ),
    ]))
    .addHandler(_deployFunction),
);
```

### Optional Fields

```dart
router.post(
  '/profiles',
  Pipeline()
    .addMiddleware(validateInput([
      ValidationRule(
        key: 'username',
        source: ValidationSource.body,
        schema: z.string().min(3) as ZardType<dynamic>,
        required: true,
      ),
      ValidationRule(
        key: 'bio',
        source: ValidationSource.body,
        schema: z.string().max(500) as ZardType<dynamic>,
        required: false, // Optional field
      ),
      ValidationRule(
        key: 'website',
        source: ValidationSource.body,
        schema: z.string().url() as ZardType<dynamic>,
        required: false,
      ),
    ]))
    .addHandler(_createProfile),
);
```

## Error Response Format

When validation fails, the middleware returns a 400 response:

```json
{
  "error": "Validation failed",
  "details": [
    "username: String must be at least 3 characters",
    "email: Invalid email format",
    "price: Number must be positive"
  ]
}
```

## Available Zard Validators

### String Validators

- `z.string()` - Basic string
- `.min(n)` - Minimum length
- `.max(n)` - Maximum length
- `.email()` - Email format
- `.url()` - URL format
- `.httpUrl()` - HTTP/HTTPS URL only
- `.uuid()` - UUID format
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

1. **Use specific validators** - Leverage Zard's built-in validators for common patterns
2. **Chain validators** - Combine multiple validations (e.g., `.min(3).max(50).trim()`)
3. **Mark optional fields** - Set `required: false` for optional fields
4. **Transform data** - Use transformations like `.trim()`, `.toLowerCase()` for cleaner data
5. **Validate early** - Add validation middleware before business logic
6. **Type casting** - Always cast Zard schemas to `ZardType<dynamic>` when using in ValidationRule

## Notes

- All Zard schemas must be cast to `ZardType<dynamic>` due to type system requirements
- Query parameters are always strings; use appropriate parsers (e.g., `z.stringbool()` for booleans)
- Empty strings are treated as null for validation purposes
- Validation errors are automatically formatted with field names
