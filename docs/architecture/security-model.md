# Security Model

## Authentication
- JWT-based token authentication
- Tokens issued on login with user ID and email
- Tokens required for all function operations

## Authorization
- Functions are user-scoped
- Users can only access their own functions
- Database queries include user_id filtering

## Function Isolation
- Each function runs in a separate process
- Configurable execution timeout (default: 5 seconds)
- Memory limits enforced (default: 128 MB)
- Concurrent execution limits (default: 10)
- Environment variable-based input (no direct stdin)
- Process killed on timeout (SIGKILL)
- Database connection pooling with timeout protection
