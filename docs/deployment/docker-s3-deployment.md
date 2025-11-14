# Container & S3 Deployment Architecture

## Overview

The ContainerPub backend uses a modern deployment architecture that combines S3 storage with **Podman** containerization for secure, scalable function execution.

> **Note**: This system uses **Podman** instead of Docker. Podman is a daemonless, rootless container engine that provides better security while maintaining 100% Docker CLI compatibility. See [Podman Infrastructure](./podman-infrastructure.md) for details.

## Architecture Components

### 1. S3 Storage

- **Purpose**: Persistent storage for function archives
- **Location**: Configurable S3-compatible storage (AWS S3, Cloudflare R2, MinIO, etc.)
- **Structure**: `functions/{function-id}/function.tar.gz`

### 2. Podman Containers

- **Purpose**: Isolated execution environment for each function
- **Runtime**: Podman (rootless, daemonless container engine)
- **Base Image**: Configurable (default: `dart:stable`)
- **Lifecycle**: Created on-demand, automatically removed after execution
- **Security**: Rootless execution, no daemon required

### 3. Function Executor

- **Timeout**: Configurable execution timeout (default: 5 seconds)
- **Cleanup Timer**: 10ms cleanup timer after execution
- **Concurrency**: Configurable max concurrent executions

## Deployment Flow

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │ POST /api/functions/deploy
       │ (multipart: name, archive)
       ▼
┌─────────────────────────────────────────┐
│         Deploy Handler                  │
│  1. Generate function ID                │
│  2. Upload archive to S3                │
│  3. Extract archive locally             │
│  4. Build Docker image                  │
│  5. Store metadata in database          │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│         S3 Storage                      │
│  functions/                             │
│    └── {function-id}/                   │
│        └── function.tar.gz              │
└─────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│         Docker Registry                 │
│  dart-function-{function-id}:latest     │
└─────────────────────────────────────────┘
```

## Execution Flow

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │ POST /api/functions/{id}/invoke
       │ (body: {body, query})
       ▼
┌─────────────────────────────────────────┐
│      Function Executor                  │
│  1. Get image_tag from database         │
│  2. Run Docker container                │
│  3. Wait for result (with timeout)      │
│  4. Schedule cleanup timer (10ms)       │
│  5. Return result                       │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│      Docker Container                   │
│  - Isolated network                     │
│  - Memory limit: 128MB (configurable)   │
│  - CPU limit: 0.5 cores                 │
│  - Auto-removed after execution         │
└─────────────────────────────────────────┘
```

## Configuration

### Environment Variables

```bash
# S3 Configuration
S3_ENDPOINT=https://s3.amazonaws.com
S3_BUCKET_NAME=dart-cloud-functions
S3_ACCESS_KEY_ID=your_access_key_id
S3_SECRET_ACCESS_KEY=your_secret_access_key
S3_REGION=us-east-1
S3_SESSION_TOKEN=                    # Optional
S3_ACCOUNT_ID=                       # Optional (for Cloudflare R2)

# Docker Configuration
DOCKER_BASE_IMAGE=dart:stable
DOCKER_REGISTRY=localhost:5000

# Function Execution Limits
FUNCTION_TIMEOUT_SECONDS=5
FUNCTION_MAX_MEMORY_MB=128
FUNCTION_MAX_CONCURRENT=10
```

### Database Schema

The `functions` table now includes:

- `status`: Function status (active, inactive, building, failed)
- `image_tag`: Docker image tag for the function
- `s3_key`: S3 object key for the function archive

## Security Features

### Container Isolation

- **Network**: Isolated by default (`--network none`)
- **Memory**: Limited to configured max (default: 128MB)
- **CPU**: Limited to 0.5 cores
- **Filesystem**: Read-only function code

### Resource Limits

- **Execution Timeout**: Configurable per-function timeout
- **Concurrent Executions**: Global limit on concurrent function runs
- **Memory**: Per-container memory limits
- **CPU**: Per-container CPU limits

## Benefits

### 1. Scalability

- Functions stored in S3 can be retrieved by any backend instance
- Docker images can be pushed to a registry for multi-node deployments
- Horizontal scaling without shared filesystem requirements

### 2. Security

- Complete process isolation via Docker containers
- Network isolation prevents unauthorized external access
- Resource limits prevent resource exhaustion attacks

### 3. Reliability

- S3 provides durable storage for function archives
- Failed deployments don't affect running functions
- Easy rollback by keeping previous versions in S3

### 4. Performance

- Docker images are cached locally for fast startup
- Containers are removed immediately after execution (10ms cleanup timer)
- No persistent processes consuming resources

## Migration from Direct Execution

### Database Migration

Run the migration script to add new columns:

```bash
psql -U dart_cloud -d dart_cloud -f infrastructure/postgres/init/02-add-docker-s3-columns.sql
```

### Existing Functions

Existing functions need to be re-deployed to:

1. Upload archives to S3
2. Build Docker images
3. Update database with new metadata

## Monitoring

### Logs

- Deployment logs: Stored in `function_logs` table
- Execution logs: Docker container stdout/stderr
- S3 operations: Check S3 access logs

### Metrics

- Active executions: `FunctionExecutor.activeExecutions`
- Container cleanup timers: Tracked per function ID
- S3 upload/download success rates

## Troubleshooting

### Docker Build Failures

- Check Dockerfile generation in `DockerService._generateDockerfile()`
- Verify base image is available: `docker pull dart:stable`
- Check function has valid `pubspec.yaml` and `main.dart`

### S3 Upload Failures

- Verify S3 credentials are correct
- Check bucket exists and has write permissions
- Verify network connectivity to S3 endpoint

### Container Execution Failures

- Check Docker daemon is running: `docker ps`
- Verify image exists: `docker images | grep dart-function`
- Check container logs: `docker logs <container-name>`

## Future Enhancements

1. **Multi-region S3**: Replicate archives across regions
2. **Image Registry**: Push images to remote registry for multi-node
3. **Cold Start Optimization**: Keep warm containers for frequently-used functions
4. **Auto-scaling**: Scale based on execution queue depth
5. **Function Versioning**: Keep multiple versions in S3 and registry
