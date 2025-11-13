# Deployment Versioning & History

## Overview

The ContainerPub backend now supports full deployment versioning and history tracking. Each time you deploy a function (new or update), a new version is created with its own Docker image and S3 archive. This enables easy rollbacks, deployment history tracking, and zero-downtime updates.

## Key Features

- **Automatic Versioning**: Each deployment gets an incremental version number
- **Deployment History**: All deployments are preserved in the database
- **Active Deployment Tracking**: Only one deployment is active at a time
- **Easy Rollbacks**: Switch to any previous deployment version instantly
- **Docker Image per Version**: Each version has its own isolated Docker image
- **S3 Archive per Version**: Each version's code is stored separately in S3

## Architecture

### Database Schema

#### `functions` Table

```sql
CREATE TABLE functions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    name VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'active',
    active_deployment_id UUID,  -- References current active deployment
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    UNIQUE(user_id, name)
);
```

#### `function_deployments` Table

```sql
CREATE TABLE function_deployments (
    id UUID PRIMARY KEY,
    function_id UUID NOT NULL,
    version INTEGER NOT NULL,
    image_tag VARCHAR(255) NOT NULL,
    s3_key VARCHAR(500) NOT NULL,
    status VARCHAR(50) DEFAULT 'building',
    is_active BOOLEAN DEFAULT false,
    build_logs TEXT,
    deployed_at TIMESTAMP,
    UNIQUE(function_id, version)
);
```

## Deployment Flow

### First Deployment (New Function)

```
1. Client uploads function archive
2. Backend creates function record (version 1)
3. Archive uploaded to S3: functions/{id}/v1/function.tar.gz
4. Docker image built: dart-function-{id}-v1:latest
5. Deployment record created with version=1, is_active=true
6. Function's active_deployment_id set to new deployment
```

### Subsequent Deployments (Updates)

```
1. Client uploads updated function archive
2. Backend detects existing function
3. Gets latest version (e.g., v2) and increments to v3
4. Marks current active deployment (v2) as inactive
5. Archive uploaded to S3: functions/{id}/v3/function.tar.gz
6. Docker image built: dart-function-{id}-v3:latest
7. New deployment record created with version=3, is_active=true
8. Function's active_deployment_id updated to new deployment
9. Previous versions (v1, v2) remain in database and S3
```

## API Endpoints

### Deploy Function

```bash
POST /api/functions/deploy
Content-Type: multipart/form-data

Fields:
  - name: function_name
  - archive: function.tar.gz

Response (New Function):
{
  "id": "uuid",
  "name": "function_name",
  "version": 1,
  "deploymentId": "deployment-uuid",
  "status": "active",
  "isNewFunction": true,
  "createdAt": "2024-01-01T00:00:00Z"
}

Response (Update):
{
  "id": "uuid",
  "name": "function_name",
  "version": 3,
  "deploymentId": "deployment-uuid",
  "status": "active",
  "isNewFunction": false,
  "createdAt": "2024-01-01T00:00:00Z"
}
```

### Get Deployment History

```bash
GET /api/functions/{id}/deployments

Response:
{
  "deployments": [
    {
      "id": "deployment-uuid",
      "version": 3,
      "imageTag": "localhost:5000/dart-function-{id}-v3:latest",
      "s3Key": "functions/{id}/v3/function.tar.gz",
      "status": "active",
      "isActive": true,
      "deployedAt": "2024-01-03T00:00:00Z"
    },
    {
      "id": "deployment-uuid",
      "version": 2,
      "imageTag": "localhost:5000/dart-function-{id}-v2:latest",
      "s3Key": "functions/{id}/v2/function.tar.gz",
      "status": "active",
      "isActive": false,
      "deployedAt": "2024-01-02T00:00:00Z"
    },
    {
      "id": "deployment-uuid",
      "version": 1,
      "imageTag": "localhost:5000/dart-function-{id}-v1:latest",
      "s3Key": "functions/{id}/v1/function.tar.gz",
      "status": "active",
      "isActive": false,
      "deployedAt": "2024-01-01T00:00:00Z"
    }
  ]
}
```

### Rollback to Previous Version

```bash
POST /api/functions/{id}/rollback
Content-Type: application/json

{
  "version": 2
}

Response:
{
  "message": "Successfully rolled back to version 2",
  "version": 2,
  "deploymentId": "deployment-uuid"
}
```

## Storage Structure

### S3 Bucket Layout

```
functions/
  ├── {function-id-1}/
  │   ├── v1/
  │   │   └── function.tar.gz
  │   ├── v2/
  │   │   └── function.tar.gz
  │   └── v3/
  │       └── function.tar.gz
  └── {function-id-2}/
      ├── v1/
      │   └── function.tar.gz
      └── v2/
          └── function.tar.gz
```

### Docker Images

```
localhost:5000/dart-function-{id}-v1:latest
localhost:5000/dart-function-{id}-v2:latest
localhost:5000/dart-function-{id}-v3:latest
```

## Execution Flow

When a function is invoked:

1. Query active deployment for the function

```sql
SELECT fd.image_tag
FROM functions f
JOIN function_deployments fd ON f.active_deployment_id = fd.id
WHERE f.id = $1 AND fd.is_active = true
```

2. Run Docker container with the active deployment's image
3. Return result to client

## Rollback Process

Rollback is instant and doesn't require rebuilding:

1. Deactivate current deployment: `is_active = false`
2. Activate target deployment: `is_active = true`
3. Update function's `active_deployment_id`
4. Next invocation uses the rolled-back version

**No downtime** - the Docker image and S3 archive already exist!

## Benefits

### 1. Zero-Downtime Updates

- New version built while old version still serves traffic
- Atomic switch when new version is ready

### 2. Instant Rollbacks

- No rebuild required
- Switch to any previous version in milliseconds
- Previous Docker images and archives already exist

### 3. Audit Trail

- Complete history of all deployments
- Track when each version was deployed
- See which version is currently active

### 4. Safe Experimentation

- Deploy new version
- Test it
- Rollback if issues found
- No risk of losing previous working version

### 5. Disaster Recovery

- All versions stored in S3
- Can recover any previous version
- Docker images can be rebuilt from S3 archives

## Best Practices

### 1. Version Cleanup

Consider implementing a cleanup policy:

- Keep last N versions (e.g., 10)
- Delete old Docker images
- Archive old S3 objects to cheaper storage

### 2. Testing Before Rollout

- Deploy new version
- Test with canary requests
- Monitor for errors
- Rollback if needed

### 3. Deployment Logs

- Each deployment logs to `function_logs` table
- Track build progress
- Debug deployment failures

### 4. Version Naming

- Versions are auto-incremented integers
- Easy to reference: "rollback to v5"
- No confusion with semantic versioning

## Migration

To migrate existing functions to the new versioning system:

```bash
# Run the migration script
psql -U dart_cloud -d dart_cloud -f infrastructure/postgres/init/02-add-docker-s3-columns.sql
```

This will:

1. Create `function_deployments` table
2. Migrate existing functions to version 1
3. Set up proper indexes
4. Clean up old schema

## Monitoring

### Check Active Deployments

```sql
SELECT f.name, fd.version, fd.deployed_at
FROM functions f
JOIN function_deployments fd ON f.active_deployment_id = fd.id
WHERE f.user_id = 'user-uuid';
```

### View Deployment History

```sql
SELECT version, status, is_active, deployed_at
FROM function_deployments
WHERE function_id = 'function-uuid'
ORDER BY version DESC;
```

### Find Failed Deployments

```sql
SELECT f.name, fd.version, fd.status, fd.build_logs
FROM function_deployments fd
JOIN functions f ON fd.function_id = f.id
WHERE fd.status = 'failed';
```

## Troubleshooting

### Deployment Stuck in "building"

- Check Docker build logs
- Verify function code is valid
- Check S3 upload succeeded

### Rollback Failed

- Verify target version exists
- Check deployment status is 'active'
- Ensure Docker image still exists

### Missing Docker Image

- Rebuild from S3 archive
- Download archive: `aws s3 cp s3://bucket/functions/{id}/v{n}/function.tar.gz`
- Extract and rebuild: `docker build -t {image-tag} .`

## Future Enhancements

1. **Canary Deployments**: Route percentage of traffic to new version
2. **Blue-Green Deployments**: Run both versions simultaneously
3. **Automatic Rollback**: Detect errors and rollback automatically
4. **Version Tagging**: Add custom tags/labels to deployments
5. **Deployment Approval**: Require manual approval before activation
6. **A/B Testing**: Split traffic between versions for testing
