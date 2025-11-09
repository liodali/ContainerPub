# Database Schema

### users
Stores user account information
- Passwords hashed with bcrypt
- Email used as unique identifier

### functions
Stores function metadata
- Links to user via foreign key
- Tracks deployment status
- Timestamps for auditing

### function_logs
Stores execution logs
- Links to function via foreign key
- Supports different log levels
- Timestamped for chronological ordering

### function_invocations
Stores invocation metrics
- Tracks success/failure status
- Records execution duration
- Stores error messages
