---
title: Development Roadmap
description: Future development plans and roadmap for ContainerPub
---

# Development Roadmap

This document outlines the future development plans and roadmap for ContainerPub.

## Current Status

**Version:** Pre-release (Development)

### Completed Features

- **CLI Tool** - `dart_cloud_cli` with deploy, list, invoke, delete commands
- **Backend Server** - `dart_cloud_backend` with REST API
- **Authentication** - Dual-token JWT system (access + refresh tokens)
- **Function Deployment** - Archive upload and container building
- **Function Execution** - Isolated container execution with Podman
- **Code Analysis** - Static analysis and security validation
- **Main Injection** - Automatic main.dart generation
- **Token Service** - Encrypted Hive storage with whitelist approach
- **Documentation Site** - Jaspr-based docs with jaspr_content

---

## Phase 1: Core Stability (Current)

### Priority: High

| Task                  | Status  | Description                                                      |
| --------------------- | ------- | ---------------------------------------------------------------- |
| Fix Analyzer Mismatch | Pending | Align CLI analyzer with backend's FunctionMainInjection scanning |
| Error Handling        | Pending | Improve error messages and recovery                              |
| Logging System        | Pending | Structured logging with levels                                   |
| Unit Tests            | Pending | Comprehensive test coverage for core services                    |
| Integration Tests     | Pending | End-to-end deployment and execution tests                        |

### Analyzer Fix Details

The CLI analyzer currently only checks `main.dart`, but `FunctionMainInjection` scans all `.dart` files. Need to:

1. Update analyzer to scan all `.dart` files in function directory
2. Find `@cloudFunction` annotated class anywhere in project
3. Validate it exists and is unique
4. Allow deployment regardless of file location

---

## Phase 2: Developer Experience

### Priority: High

| Task               | Status  | Description                                          |
| ------------------ | ------- | ---------------------------------------------------- |
| Local Testing      | Planned | `dart_cloud test` command for local function testing |
| Function Templates | Planned | `dart_cloud create` with starter templates           |
| Hot Reload         | Planned | Update functions without full rebuild                |
| IDE Plugin         | Planned | VS Code extension for ContainerPub                   |
| Better Logs        | Planned | Real-time log streaming with `--follow`              |

### Local Testing Details

```dart
# Run function locally without deployment
dart_cloud test ./my-function --data '{"key": "value"}'

# Watch mode for development
dart_cloud test ./my-function --watch
```

---

## Phase 3: Platform Features

### Priority: Medium

| Task                  | Status  | Description                                |
| --------------------- | ------- | ------------------------------------------ |
| Environment Variables | Planned | Per-function environment configuration     |
| Secrets Management    | Planned | Secure secret storage and injection        |
| Custom Domains        | Planned | Map custom domains to functions            |
| Scheduled Functions   | Planned | Cron-based function execution              |
| Event Triggers        | Planned | Webhook and event-based invocation         |
| Function Versioning   | Planned | Deploy multiple versions, rollback support |

### Environment Variables

```dart
# Set environment variables for a function
dart_cloud env set <function-id> DATABASE_URL=postgres://...
dart_cloud env list <function-id>
dart_cloud env delete <function-id> DATABASE_URL
```

### Scheduled Functions

```dart
# function.yaml
schedule:
  cron: "0 * * * *" # Every hour
  timezone: "UTC"
```

---

## Phase 4: Scaling & Performance

### Priority: Medium

| Task              | Status  | Description                                |
| ----------------- | ------- | ------------------------------------------ |
| Container Pooling | Planned | Pre-warm containers for faster cold starts |
| Auto-scaling      | Planned | Scale based on request volume              |
| Load Balancing    | Planned | Distribute requests across instances       |
| Caching Layer     | Planned | Response caching for repeated requests     |
| Metrics Dashboard | Planned | Real-time performance monitoring           |
| Rate Limiting     | Planned | Per-user and per-function limits           |

### Cold Start Optimization

1. Pre-build base images with common dependencies
2. Container pool with warm instances
3. Lazy loading for rarely-used functions
4. Image layer caching

---

## Phase 5: Enterprise Features

### Priority: Low

| Task              | Status  | Description                   |
| ----------------- | ------- | ----------------------------- |
| Team Management   | Planned | Organizations, teams, roles   |
| RBAC              | Planned | Role-based access control     |
| Audit Logs        | Planned | Complete audit trail          |
| SSO Integration   | Planned | SAML, OAuth2 providers        |
| Private Functions | Planned | Internal-only function access |
| VPC Support       | Planned | Deploy in private networks    |

---

## Phase 6: Ecosystem

### Priority: Low

| Task                  | Status  | Description                      |
| --------------------- | ------- | -------------------------------- |
| Function Marketplace  | Planned | Share and discover functions     |
| Plugins System        | Planned | Extend CLI and backend           |
| Database Integrations | Planned | Built-in PostgreSQL, Redis, etc. |
| Storage Service       | Planned | S3-compatible object storage     |
| CDN Integration       | Planned | Edge caching for responses       |

---

## Technical Debt

| Item                  | Priority | Description                              |
| --------------------- | -------- | ---------------------------------------- |
| Refactor TokenService | Medium   | Simplify token validation flow           |
| Update Dependencies   | Low      | Keep packages up to date                 |
| Code Documentation    | Medium   | Inline documentation for all public APIs |
| Error Codes           | Medium   | Standardized error codes across API      |
| API Versioning        | Low      | Prepare for v2 API                       |

---

## Release Schedule

| Version | Target  | Focus                             |
| ------- | ------- | --------------------------------- |
| 0.1.0   | Q1 2025 | Core stability, bug fixes         |
| 0.2.0   | Q2 2025 | Developer experience improvements |
| 0.3.0   | Q3 2025 | Platform features                 |
| 1.0.0   | Q4 2025 | Production-ready release          |

---

## Contributing

We welcome contributions! Priority areas:

1. **Bug fixes** - Help us squash bugs
2. **Documentation** - Improve docs and examples
3. **Testing** - Add test coverage
4. **Features** - Implement planned features

---

## Feedback

Have ideas or suggestions? Open an issue on GitHub:

- [Feature Requests](https://github.com/liodali/ContainerPub/issues/new?labels=enhancement)
- [Bug Reports](https://github.com/liodali/ContainerPub/issues/new?labels=bug)
- [Questions](https://github.com/liodali/ContainerPub/discussions)
