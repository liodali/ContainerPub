# Deployment Versioning & History - Changelog

## Summary

Implemented a comprehensive deployment versioning and history system that tracks all function deployments, enables instant rollbacks, and builds a new Docker image for each deployment.

## Key Changes

### Database Schema Updates

#### New Table: function_deployments

- Tracks all deployment versions for each function
- Stores Docker image tag and S3 key per version
- Maintains active/inactive status
- Records deployment timestamp

#### Updated Table: functions

- Removed: image_tag, s3_key, code columns
- Added: active_deployment_id (references active deployment)
- Added: status column (building, active, inactive, failed)

### Deployment Flow Changes

#### Before (Single Version)

1. Upload archive
2. Build Docker image
3. Store image_tag in functions table
4. Execute from single image

#### After (Multi-Version)

1. Upload archive to S3 with version: functions/{id}/v{n}/function.tar.gz
2. Build versioned Docker image: dart-function-{id}-v{n}:latest
3. Create deployment record with version number
4. Mark previous deployment as inactive
5. Set new deployment as active
6. Update function's active_deployment_id

### New Features

1. **Automatic Versioning**: Each deploy increments version number
2. **Deployment History**: View all past deployments
3. **Instant Rollback**: Switch to any previous version
4. **Version Isolation**: Each version has separate Docker image and S3 archive
5. **Zero Downtime**: New version built while old version serves traffic

### API Endpoints Added

- GET /api/functions/{id}/deployments - View deployment history
- POST /api/functions/{id}/rollback - Rollback to specific version

### Files Modified

1. **infrastructure/postgres/init/01-init-databases.sql**

   - Added function_deployments table
   - Updated functions table schema
   - Added indexes for performance

2. **infrastructure/postgres/init/02-add-docker-s3-columns.sql**

   - Migration script for existing databases
   - Migrates old data to new schema
   - Handles backward compatibility

3. **lib/handlers/function_handler.dart**

   - Updated deploy() to support versioning
   - Added getDeployments() endpoint
   - Added rollback() endpoint
   - Version tracking and management

4. **lib/services/function_executor.dart**

   - Updated to query active deployment
   - Joins functions with function_deployments
   - Uses active deployment's image tag

5. **lib/router.dart**
   - Added /api/functions/{id}/deployments route
   - Added /api/functions/{id}/rollback route

### Documentation Added

1. **docs/deployment/deployment-versioning.md**

   - Complete versioning architecture
   - API documentation
   - Best practices
   - Troubleshooting guide

2. **docs/deployment/docker-s3-deployment.md**
   - Docker and S3 integration
   - Security features
   - Monitoring and troubleshooting

## Migration Guide

### For New Installations

No action needed - schema includes versioning by default

### For Existing Installations

Run migration script:

```bash
psql -U dart_cloud -d dart_cloud -f infrastructure/postgres/init/02-add-docker-s3-columns.sql
```

This will:

- Create function_deployments table
- Migrate existing functions to version 1
- Preserve existing data
- Set up proper indexes

### Re-deploy Existing Functions

Existing functions need to be re-deployed to:

1. Create versioned S3 archives
2. Build versioned Docker images
3. Create deployment records

## Benefits

1. **Rollback Safety**: Instant rollback to any previous version
2. **Audit Trail**: Complete history of all deployments
3. **Zero Downtime**: Atomic switches between versions
4. **Disaster Recovery**: All versions preserved in S3
5. **Testing**: Deploy and test new versions safely

## Breaking Changes

### Database Schema

- functions.image_tag removed (use active_deployment_id)
- functions.s3_key removed (use active_deployment_id)
- functions.code removed (stored in S3 only)

### Migration Required

Existing deployments must run migration script to continue working

## Testing Checklist

- [ ] Deploy new function (creates version 1)
- [ ] Deploy update to existing function (creates version 2)
- [ ] View deployment history
- [ ] Rollback to version 1
- [ ] Invoke function (uses rolled-back version)
- [ ] Deploy another update (creates version 3)
- [ ] Verify all versions in S3
- [ ] Verify all Docker images exist
- [ ] Check deployment logs

## Performance Considerations

### Storage Growth

- Each version creates new S3 object and Docker image
- Consider implementing cleanup policy for old versions
- Recommend keeping last 10 versions

### Query Performance

- Added indexes on function_deployments
- JOIN query for active deployment is fast
- Deployment history queries are paginated

## Security

- Deployment history is user-scoped
- Only function owner can view deployments
- Only function owner can rollback
- All operations logged to function_logs

## Future Enhancements

1. Automatic cleanup of old versions
2. Canary deployments (gradual rollout)
3. Blue-green deployments
4. Automatic rollback on errors
5. Version tagging and labels
6. Deployment approval workflow
