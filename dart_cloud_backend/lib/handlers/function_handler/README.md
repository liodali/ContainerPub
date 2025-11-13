# Function Handler Module

This directory contains the modular implementation of function management operations for the ContainerPub backend.

## Structure

The function handler is split into specialized modules for better organization and maintainability:

```
function_handler/
├── deployment_handler.dart    # Function deployment and updates
├── crud_handler.dart           # List, get, delete operations
├── execution_handler.dart      # Function invocation
├── logs_handler.dart           # Log retrieval
├── versioning_handler.dart     # Deployment history and rollback
├── utils.dart                  # Shared utilities
└── README.md                   # This file
```

## Modules

### deployment_handler.dart

**Purpose**: Handles function deployment and updates

**Responsibilities**:

- Parse multipart upload requests
- Check if function exists (new vs update)
- Upload archives to S3 with versioning
- Extract archives locally
- Build Docker images
- Create deployment records
- Manage deployment history

**Key Functions**:

- `deploy(Request)` - Deploy new or update existing function
- `initializeS3()` - Initialize S3 client

**Comments**: Comprehensive inline comments explain each step of the deployment workflow

---

### crud_handler.dart

**Purpose**: Basic CRUD operations for functions

**Responsibilities**:

- List all functions for a user
- Get details of specific function
- Delete functions and associated resources
- Verify function ownership

**Key Functions**:

- `list(Request)` - List all user's functions
- `get(Request, String id)` - Get function details
- `delete(Request, String id)` - Delete function

**Comments**: Each function includes detailed documentation on query logic and response format

---

### execution_handler.dart

**Purpose**: Function invocation and execution

**Responsibilities**:

- Validate request size limits (5MB default)
- Verify function ownership
- Execute functions in Docker containers
- Track execution metrics
- Log invocation results

**Key Functions**:

- `invoke(Request, String id)` - Execute function with input

**Comments**: Detailed comments explain validation, execution flow, and error handling

---

### logs_handler.dart

**Purpose**: Function logging and monitoring

**Responsibilities**:

- Retrieve function logs
- Filter by function ID
- Limit log entries (100 max)
- Format timestamps

**Key Functions**:

- `getLogs(Request, String id)` - Retrieve function logs

**Comments**: Documents log levels and response format

---

### versioning_handler.dart

**Purpose**: Deployment versioning and rollback

**Responsibilities**:

- View complete deployment history
- Track active deployments
- Perform instant rollbacks
- Manage version lifecycle

**Key Functions**:

- `getDeployments(Request, String id)` - Get deployment history
- `rollback(Request, String id)` - Rollback to specific version

**Comments**: Extensive documentation on rollback process and version management

---

### utils.dart

**Purpose**: Shared utility functions

**Responsibilities**:

- Function logging
- Common validation
- Shared helpers

**Key Functions**:

- `logFunction(String, String, String)` - Log function events

**Comments**: Documents utility functions and their usage

## Design Principles

### 1. Single Responsibility

Each handler focuses on one domain:

- Deployment handler only handles deployments
- CRUD handler only handles basic operations
- Execution handler only handles invocations

### 2. Comprehensive Comments

Every file includes:

- Module-level documentation
- Function-level documentation
- Inline comments for complex logic
- Parameter descriptions
- Response format examples

### 3. Consistent Patterns

All handlers follow the same structure:

- Import statements
- Class documentation
- Static methods
- Error handling
- Response formatting

### 4. Error Handling

All handlers:

- Use try-catch blocks
- Return appropriate HTTP status codes
- Provide descriptive error messages
- Log errors for debugging

### 5. Security

All handlers verify:

- User authentication (via middleware)
- Function ownership
- Request size limits
- Input validation

## Usage

### Import Main Handler

```dart
import 'package:dart_cloud_backend/handlers/function_handler.dart';

// Use in routes
router.post('/api/functions/deploy', FunctionHandler.deploy);
router.get('/api/functions', FunctionHandler.list);
router.post('/api/functions/:id/invoke', FunctionHandler.invoke);
```

### Import Specific Handler

```dart
import 'package:dart_cloud_backend/handlers/function_handler/deployment_handler.dart';

// Use directly
router.post('/api/functions/deploy', DeploymentHandler.deploy);
```

## Adding New Handlers

To add a new handler:

1. Create new file: `new_handler.dart`
2. Follow the existing pattern:
   ```dart
   /// Handler documentation
   class NewHandler {
     /// Function documentation
     static Future<Response> operation(Request request) async {
       try {
         // Implementation with comments
       } catch (e) {
         // Error handling
       }
     }
   }
   ```
3. Export in `function_handler.dart`:
   ```dart
   export 'function_handler/new_handler.dart';
   ```
4. Add delegation method in `FunctionHandler` class
5. Update this README

## Testing

Each handler can be tested independently:

```dart
import 'package:test/test.dart';
import 'package:dart_cloud_backend/handlers/function_handler/deployment_handler.dart';

void main() {
  test('deploy creates new function', () async {
    // Test deployment logic
  });
}
```

## Maintenance

### Code Review Checklist

- [ ] Comprehensive comments added
- [ ] Error handling implemented
- [ ] Ownership verification included
- [ ] Response format documented
- [ ] Follows existing patterns
- [ ] README updated

### Refactoring Guidelines

- Keep handlers focused on single responsibility
- Extract common logic to utils.dart
- Maintain consistent error handling
- Update comments when logic changes
- Keep functions under 100 lines when possible

## Benefits of This Structure

1. **Maintainability**: Easy to find and update specific functionality
2. **Testability**: Each handler can be tested independently
3. **Readability**: Clear separation of concerns
4. **Scalability**: Easy to add new handlers without affecting existing code
5. **Documentation**: Comprehensive comments make code self-documenting
6. **Collaboration**: Multiple developers can work on different handlers simultaneously

## Related Documentation

- [Deployment Versioning](../../../docs/deployment/deployment-versioning.md)
- [Docker & S3 Deployment](../../../docs/deployment/docker-s3-deployment.md)
- [Request Size Limits](../../../docs/deployment/request-size-limits.md)
