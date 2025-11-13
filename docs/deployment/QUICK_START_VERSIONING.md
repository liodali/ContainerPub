# Quick Start: Deployment Versioning

## TL;DR

Every deployment now creates a new version. You can view history and rollback instantly.

## Deploy Function (First Time)

```bash
curl -X POST http://localhost:8080/api/functions/deploy \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "name=my-function" \
  -F "archive=@function.tar.gz"
```

Response:

```json
{
  "id": "abc-123",
  "name": "my-function",
  "version": 1,
  "status": "active",
  "isNewFunction": true
}
```

## Update Function (Creates Version 2)

```bash
curl -X POST http://localhost:8080/api/functions/deploy \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "name=my-function" \
  -F "archive=@function-v2.tar.gz"
```

Response:

```json
{
  "id": "abc-123",
  "name": "my-function",
  "version": 2,
  "status": "active",
  "isNewFunction": false
}
```

## View Deployment History

```bash
curl http://localhost:8080/api/functions/abc-123/deployments \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Response:

```json
{
  "deployments": [
    {
      "version": 2,
      "isActive": true,
      "deployedAt": "2024-01-02T00:00:00Z"
    },
    {
      "version": 1,
      "isActive": false,
      "deployedAt": "2024-01-01T00:00:00Z"
    }
  ]
}
```

## Rollback to Version 1

```bash
curl -X POST http://localhost:8080/api/functions/abc-123/rollback \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"version": 1}'
```

Response:

```json
{
  "message": "Successfully rolled back to version 1",
  "version": 1
}
```

## What Happens Behind the Scenes

### On Deploy

1. Archive uploaded to S3: `functions/abc-123/v2/function.tar.gz`
2. Docker image built: `dart-function-abc-123-v2:latest`
3. Previous version (v1) marked inactive
4. New version (v2) marked active
5. Function invocations use v2

### On Rollback

1. Version 2 marked inactive
2. Version 1 marked active
3. Function invocations use v1
4. **No rebuild needed** - instant switch!

## Storage Layout

```
S3 Bucket:
  functions/
    abc-123/
      v1/function.tar.gz  ← Version 1 (preserved)
      v2/function.tar.gz  ← Version 2 (current)

Docker Images:
  dart-function-abc-123-v1:latest  ← Version 1 (preserved)
  dart-function-abc-123-v2:latest  ← Version 2 (current)
```

## Common Workflows

### Safe Update Pattern

```bash
# 1. Deploy new version
curl -X POST .../deploy -F "archive=@new-version.tar.gz"

# 2. Test the new version
curl -X POST .../abc-123/invoke -d '{"body": {"test": true}}'

# 3. If issues found, rollback
curl -X POST .../abc-123/rollback -d '{"version": 1}'

# 4. If all good, keep new version
# (no action needed)
```

### View All Versions

```bash
# Get deployment history
curl .../abc-123/deployments

# Check which version is active
# (look for "isActive": true)
```

### Emergency Rollback

```bash
# Instant rollback to last known good version
curl -X POST .../abc-123/rollback -d '{"version": 1}'
```

## Key Points

✅ **Every deploy creates a new version**
✅ **All versions are preserved**
✅ **Rollback is instant (no rebuild)**
✅ **Zero downtime updates**
✅ **Complete audit trail**

## Migration for Existing Functions

If you have existing functions, re-deploy them to enable versioning:

```bash
# Re-deploy existing function
curl -X POST .../deploy \
  -F "name=existing-function" \
  -F "archive=@existing-function.tar.gz"
```

This creates version 1 with the new versioning system.
