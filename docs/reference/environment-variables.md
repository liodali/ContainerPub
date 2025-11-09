# Environment Variables Reference

This document lists all environment variables used to configure the ContainerPub backend.

## Main Configuration

These are the core variables required for the backend to run.

- **`DATABASE_URL`**: The full URL for connecting to your main PostgreSQL database.
  - **Example**: `postgres://dart_cloud:your_secure_password@localhost:5432/dart_cloud`

- **`PORT`**: The port the backend server will listen on.
  - **Default**: `8080`

- **`JWT_SECRET`**: The secret key used for signing JWTs. Must be long and random.
  - **Example**: `your-super-long-and-random-secret-key-here`

- **`FUNCTIONS_DIR`**: The directory where deployed functions are stored.
  - **Default**: `./functions`

## Function Execution Limits

These variables control the resource limits for function execution.

- **`FUNCTION_TIMEOUT_SECONDS`**: The maximum time a function can run before being terminated.
  - **Default**: `5`

- **`FUNCTION_MAX_MEMORY_MB`**: The maximum amount of memory a function can use (in MB).
  - **Default**: `128`

- **`FUNCTION_MAX_CONCURRENT`**: The maximum number of functions that can run concurrently.
  - **Default**: `10`

## Database Access for Functions

These variables configure a separate, dedicated database connection pool for functions. This is optional but recommended for security.

- **`FUNCTION_DATABASE_URL`**: The URL for the functions' database. Use a separate, more restricted user if possible.
  - **Example**: `postgres://function_user:function_password@localhost:5432/functions_db`

- **`FUNCTION_DB_MAX_CONNECTIONS`**: The maximum number of connections in the function database pool.
  - **Default**: `5`

- **`FUNCTION_DB_TIMEOUT_MS`**: The timeout for acquiring a connection from the pool (in milliseconds).
  - **Default**: `5000`
