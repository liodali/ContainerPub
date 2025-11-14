---
title: Architecture Overview
description: Understand the ContainerPub system architecture
---

# Architecture Overview

ContainerPub is built on a modern, scalable architecture designed for security and performance.

## System Components

### 1. CLI Tool (`dart_cloud_cli`)

The command-line interface for developers:

- **Function Management** - Deploy, list, delete functions
- **Logging** - View function execution logs
- **Monitoring** - Check function status and metrics
- **Configuration** - Set environment variables
- **Authentication** - Secure API access

### 2. Backend Server (`dart_cloud_backend`)

The core platform:

- **Function Hosting** - Execute Dart functions
- **Container Management** - Podman-based isolation
- **API Server** - HTTP endpoints for functions
- **Database** - PostgreSQL for metadata
- **Monitoring** - Metrics and logging system
- **Authentication** - User and function authorization

## Architecture Diagram

```
┌─────────────────────────────────────────────┐
│         Developer Machine                   │
│  ┌──────────────────────────────────────┐  │
│  │    dart_cloud CLI Tool               │  │
│  │  - Deploy functions                  │  │
│  │  - Manage lifecycle                  │  │
│  │  - View logs                         │  │
│  └──────────────────────────────────────┘  │
└──────────────┬──────────────────────────────┘
               │ HTTP/REST API
               ▼
┌─────────────────────────────────────────────┐
│    ContainerPub Backend Server              │
│  ┌──────────────────────────────────────┐  │
│  │  API Server (Shelf)                  │  │
│  │  - Function deployment               │  │
│  │  - Function execution                │  │
│  │  - Metrics collection                │  │
│  └──────────────────────────────────────┘  │
│  ┌──────────────────────────────────────┐  │
│  │  Container Runtime (Podman)          │  │
│  │  - Build images                      │  │
│  │  - Run containers                    │  │
│  │  - Manage resources                  │  │
│  └──────────────────────────────────────┘  │
│  ┌──────────────────────────────────────┐  │
│  │  Database (PostgreSQL)               │  │
│  │  - Function metadata                 │  │
│  │  - User data                         │  │
│  │  - Execution history                 │  │
│  └──────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

## Deployment Flow

### 1. Function Upload
```
Developer → CLI → API Server → Storage
```

### 2. Image Building
```
Storage → Extract → Build Image → Podman Registry
```

### 3. Function Execution
```
API Request → Scheduler → Podman Container → Response
```

### 4. Monitoring
```
Container → Metrics Collector → Database → Dashboard
```

## Technology Stack

### Backend
- **Language**: Dart 3.x
- **Framework**: Shelf (HTTP server)
- **Database**: PostgreSQL
- **Container Runtime**: Podman
- **Storage**: File system / Object storage

### CLI
- **Language**: Dart 3.x
- **Distribution**: Compiled binaries
- **Platforms**: Linux, macOS, Windows

## Security Architecture

### Container Isolation
- **Rootless Containers** - Podman runs without root
- **User Namespaces** - Each container in isolated namespace
- **Resource Limits** - CPU, memory, disk constraints
- **Network Isolation** - Containers on isolated networks

### API Security
- **Authentication** - Token-based authentication
- **Authorization** - Role-based access control
- **Encryption** - HTTPS for all communications
- **Audit Logging** - Complete request logging

### Function Security
- **Client-side Analysis** - Pre-deployment security checks
- **Sandboxing** - Functions run in isolated containers
- **Environment Isolation** - Secrets via environment variables
- **Resource Limits** - Prevent resource exhaustion

## Scaling Architecture

### Horizontal Scaling
- Multiple backend instances
- Load balancer distribution
- Shared database
- Distributed cache

### Vertical Scaling
- Resource allocation per function
- Dynamic resource adjustment
- Container resource limits
- Memory and CPU management

## Database Schema

### Functions Table
```dart
CREATE TABLE functions (
  id UUID PRIMARY KEY,
  name VARCHAR(255),
  owner_id UUID,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  status VARCHAR(50),
  metadata JSONB
);
```

### Executions Table
```dart
CREATE TABLE executions (
  id UUID PRIMARY KEY,
  function_id UUID,
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  status VARCHAR(50),
  logs TEXT,
  result JSONB
);
```

## Performance Considerations

### Cold Start
- Optimized base images
- Minimal dependencies
- Fast container startup
- Cached layers

### Warm Execution
- Container reuse
- Memory caching
- Connection pooling
- Optimized runtime

### Resource Usage
- Efficient memory management
- CPU throttling
- Disk usage optimization
- Network optimization

## Monitoring & Observability

### Metrics Collected
- Function execution time
- Memory usage
- CPU usage
- Error rates
- Request count

### Logging
- Function stdout/stderr
- API request logs
- System events
- Audit trail

### Alerting
- Performance degradation
- Error thresholds
- Resource exhaustion
- Security events

## Future Enhancements

- **Kubernetes Integration** - Deploy on K8s
- **Multi-region** - Global function distribution
- **Advanced Scheduling** - Intelligent placement
- **Custom Runtimes** - Support other languages
- **Serverless Workflows** - Function orchestration

## Next Steps

- Read [Development Guide](/docs/development)
- Explore [Database Schema](/docs/architecture/database)
- Check [Security Model](/docs/architecture/security)
