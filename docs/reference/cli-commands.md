# CLI Command Reference

This document provides a complete reference for all `dart_cloud` CLI commands.

## Global Options

- `--help`: Show help for any command.
- `--version`: Show the CLI version.

## `dart_cloud login`

Authenticates the user and saves the session token.

**Usage:**
```bash
dart_cloud login
```

**Prompts:**
- `Email`: Your registered email address.
- `Password`: Your password.

**Behavior:**
- Sends credentials to the backend `/api/auth/login` endpoint.
- On success, saves the JWT to `~/.dart_cloud/config.json`.

## `dart_cloud logout`

Logs the user out by deleting the session token.

**Usage:**
```bash
dart_cloud logout
```

**Behavior:**
- Deletes the `~/.dart_cloud/config.json` file.

## `dart_cloud deploy <function-path>`

Deploys a Dart function to the ContainerPub platform.

**Usage:**
```bash
dart_cloud deploy ./my-function
```

**Arguments:**
- `<function-path>`: The path to the directory containing your function code and `pubspec.yaml`.

**Behavior:**
1.  Performs client-side static analysis on the function code.
2.  If analysis passes, it packages the function directory into a `.tar.gz` archive.
3.  Sends a multipart/form-data request to the `/api/functions/deploy` endpoint.
4.  The backend unpacks, stores, and prepares the function for execution.

## `dart_cloud list`

Lists all deployed functions for the authenticated user.

**Usage:**
```bash
dart_cloud list
```

**Output:**
- A table of your functions, including ID, name, status, and creation date.

## `dart_cloud logs <function-id>`

Retrieves logs for a specific function.

**Usage:**
```bash
dart_cloud logs <function-id>
```

**Arguments:**
- `<function-id>`: The ID of the function to retrieve logs for.

**Options:**
- `--follow`: Stream logs in real-time.
- `--tail <n>`: Show the last `n` log entries.

## `dart_cloud invoke <function-id>`

Invokes a deployed function.

**Usage:**
```bash
dart_cloud invoke <function-id> --data '{"name": "World"}'
```

**Arguments:**
- `<function-id>`: The ID of the function to invoke.

**Options:**
- `--data <json>`: A JSON string to be sent as the request body.

## `dart_cloud delete <function-id>`

Deletes a deployed function.

**Usage:**
```bash
dart_cloud delete <function-id>
```

**Arguments:**
- `<function-id>`: The ID of the function to delete.
