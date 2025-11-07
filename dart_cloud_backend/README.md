# Dart Cloud Backend

Backend server for hosting and managing Dart serverless functions.

## Features

- 🚀 Deploy Dart functions via REST API
- 🔐 JWT-based authentication
- 📊 Function execution monitoring
- 📝 Logging and metrics
- 🗄️ PostgreSQL database for metadata
- ⚡ Isolated function execution

## Setup

### Prerequisites

- Dart SDK 3.0+
- PostgreSQL database

### Installation

1. Copy environment configuration:
```bash
cp .env.example .env
```

2. Update `.env` with your configuration:
   - `PORT`: Server port (default: 8080)
   - `FUNCTIONS_DIR`: Directory to store deployed functions
   - `DATABASE_URL`: PostgreSQL connection string
   - `JWT_SECRET`: Secret key for JWT tokens

3. Install dependencies:
```bash
dart pub get
```

4. Run the server:
```bash
dart run bin/server.dart
```

## API Endpoints

### Authentication

#### Register
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword"
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword"
}
```

### Functions (Requires Authentication)

All function endpoints require the `Authorization: Bearer <token>` header.

#### Deploy Function
```http
POST /api/functions/deploy
Authorization: Bearer <token>
Content-Type: multipart/form-data

name: my-function
archive: <function.tar.gz>
```

#### List Functions
```http
GET /api/functions
Authorization: Bearer <token>
```

#### Get Function Details
```http
GET /api/functions/{id}
Authorization: Bearer <token>
```

#### Get Function Logs
```http
GET /api/functions/{id}/logs
Authorization: Bearer <token>
```

#### Invoke Function
```http
POST /api/functions/{id}/invoke
Authorization: Bearer <token>
Content-Type: application/json

{
  "key": "value"
}
```

#### Delete Function
```http
DELETE /api/functions/{id}
Authorization: Bearer <token>
```

## Function Structure

Deployed functions should have the following structure:

```
my-function/
├── pubspec.yaml
├── main.dart (or bin/main.dart)
└── ... other files
```

The function's `main.dart` should:
- Read input from `FUNCTION_INPUT` environment variable
- Print output to stdout (preferably as JSON)
- Exit with code 0 on success

Example function:

```dart
import 'dart:convert';
import 'dart:io';

void main() {
  // Read input
  final inputJson = Platform.environment['FUNCTION_INPUT'] ?? '{}';
  final input = jsonDecode(inputJson) as Map<String, dynamic>;
  
  // Process
  final result = {
    'message': 'Hello, ${input['name'] ?? 'World'}!',
    'timestamp': DateTime.now().toIso8601String(),
  };
  
  // Output result
  print(jsonEncode(result));
}
```

## Database Schema

### users
- `id` (UUID, PK)
- `email` (VARCHAR, UNIQUE)
- `password_hash` (VARCHAR)
- `created_at` (TIMESTAMP)

### functions
- `id` (UUID, PK)
- `user_id` (UUID, FK → users.id)
- `name` (VARCHAR)
- `status` (VARCHAR)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

### function_logs
- `id` (UUID, PK)
- `function_id` (UUID, FK → functions.id)
- `level` (VARCHAR)
- `message` (TEXT)
- `timestamp` (TIMESTAMP)

### function_invocations
- `id` (UUID, PK)
- `function_id` (UUID, FK → functions.id)
- `status` (VARCHAR)
- `duration_ms` (INTEGER)
- `error` (TEXT)
- `timestamp` (TIMESTAMP)

## Development

### Running Tests
```bash
dart test
```

### Linting
```bash
dart analyze
```

## Production Deployment

1. Set strong `JWT_SECRET` in production
2. Use SSL/TLS for database connections
3. Configure proper CORS settings
4. Set up monitoring and logging
5. Use a reverse proxy (nginx/Caddy) for HTTPS
6. Implement rate limiting
7. Set up database backups
