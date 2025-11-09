# ContainerPub Architecture

## Overview

ContainerPub is a Dart-based serverless platform that allows developers to deploy and execute Dart functions in a managed environment.

## System Components

### 1. CLI (dart_cloud_cli)
**Purpose**: Command-line interface for developers to interact with the platform

**Key Features**:
- User authentication (login/logout)
- Function deployment
- **Client-side function analysis and validation**
- Function management (list, delete)
- Function invocation
- Log viewing

**Technology Stack**:
- Dart SDK
- HTTP client for API communication
- Archive library for packaging functions
- **Dart Analyzer for static code analysis**
- Local configuration storage

### 2. Backend (dart_cloud_backend)
**Purpose**: Server platform for hosting and executing functions

**Key Features**:
- RESTful API for function management
- JWT-based authentication
- Function storage and execution
- Logging and monitoring
- Database integration

**Technology Stack**:
- Shelf (HTTP server framework)
- PostgreSQL (metadata storage)
- JWT for authentication
- Process isolation for function execution
- **Note**: Function analysis moved to CLI (client-side)

## Architecture Diagram

```
┌─────────────────┐
│   Developer     │
└────────┬────────┘
         │
         │ CLI Commands
         ▼
┌─────────────────┐
│  dart_cloud_cli │
│                 │
│  - Login        │
│  - Deploy       │
│  - Invoke       │
│  - Manage       │
└────────┬────────┘
         │
         │ HTTPS/REST API
         ▼
┌─────────────────────────────────────┐
│     dart_cloud_backend              │
│                                     │
│  ┌──────────────────────────────┐  │
│  │   API Layer (Shelf Router)   │  │
│  └──────────┬───────────────────┘  │
│             │                       │
│  ┌──────────▼───────────────────┐  │
│  │   Auth Middleware (JWT)      │  │
│  └──────────┬───────────────────┘  │
│             │                       │
│  ┌──────────▼───────────────────┐  │
│  │   Handlers                   │  │
│  │   - AuthHandler              │  │
│  │   - FunctionHandler          │  │
│  └──────────┬───────────────────┘  │
│             │                       │
│  ┌──────────▼───────────────────┐  │
│  │   Services                   │  │
│  │   - FunctionExecutor         │  │
│  │   (Analysis removed)         │  │
│  └──────────┬───────────────────┘  │
│             │                       │
│  ┌──────────▼───────────────────┐  │
│  │   Database Layer             │  │
│  │   - PostgreSQL               │  │
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │   File System                │  │
│  │   - Function Storage         │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

## Data Flow

### Function Deployment Flow

1. **Developer** creates a Dart function with `pubspec.yaml`
2. **CLI** performs static analysis and security validation (client-side)
   - Checks for `@function` annotation
   - Scans for risky code patterns
   - Validates function signature
   - Displays warnings and errors to developer
3. **CLI** packages the function into a tar.gz archive (only if analysis passes)
4. **CLI** sends multipart request to `/api/functions/deploy`
5. **Backend** authenticates the request via JWT
6. **Backend** generates unique function ID
7. **Backend** extracts archive to function storage directory
8. **Backend** stores metadata in PostgreSQL
9. **Backend** returns function details to CLI

### Function Invocation Flow

1. **Developer** invokes function via CLI or direct API call
2. **Backend** authenticates the request
3. **Backend** verifies function ownership
4. **Backend** creates isolated process for function execution
5. **FunctionExecutor** runs `dart run` with input as environment variable
6. **Function** processes input and outputs result to stdout
7. **Backend** captures output and returns to caller
8. **Backend** logs invocation metrics to database
