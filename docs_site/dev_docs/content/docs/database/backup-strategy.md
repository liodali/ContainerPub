---
title: Backup and Disaster Recovery Strategy
description: Comprehensive backup, replication, and disaster recovery documentation for ContainerPub
---

# Backup and Disaster Recovery Strategy

Complete guide to backing up, replicating, and recovering data in the ContainerPub serverless platform.

## 📋 Overview

The ContainerPub backup system provides comprehensive data protection through:

- **Database Backups** - PostgreSQL database dumps with compression
- **Volume Backups** - Docker volume snapshots
- **Volume Replication** - Real-time or scheduled replication to remote locations
- **Automated Scheduling** - Cron-based backup automation
- **Disaster Recovery** - Complete system restore procedures

## 🏗️ System Architecture

```dart
┌─────────────────────────────────────────────┐
│         ContainerPub Backend Stack          │
├─────────────────────────────────────────────┤
│  PostgreSQL Container  │  Backend Container │
│  ↓ postgres_data       │  ↓ functions_data  │
└──────────┬──────────────┴──────────┬────────┘
           │                         │
┌──────────▼─────────────────────────▼────────┐
│            Backup System Layer              │
│  • Database Backup (pg_dump)                │
│  • Volume Backup (tar archive)              │
│  • Combined Archives                        │
└──────────┬──────────────────────────────────┘
           │
┌──────────▼──────────────────────────────────┐
│        Replication Layer (Optional)         │
│  Local Storage │ Rsync │ S3 │ Custom        │
└─────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

1. Docker and Docker Compose installed
2. ContainerPub backend stack running
3. Proper permissions to execute scripts

### Setup

```dart
# Navigate to backup directory
cd dart_cloud_backend/deploy/backups

# Make scripts executable
chmod +x *.sh
```

## 📦 Manual Backups

### Complete Backup (Recommended)

Backup everything - databases and volumes:

```dart
./backup-all.sh
```

**Output:**
- Database backups (main + functions)
- Volume backups (PostgreSQL + functions data)
- Combined archive
- Backup manifest with restore instructions

### Database Only

```dart
./backup-database.sh
```

**Creates:**
- `data/dart_cloud_TIMESTAMP.sql.gz` - Main database
- `data/functions_db_TIMESTAMP.sql.gz` - Functions database
- `data/full_backup_TIMESTAMP.tar.gz` - Combined archive
- `data/backup_TIMESTAMP.meta` - Metadata

### Volumes Only

```dart
./backup-volumes.sh
```

**Creates:**
- `data/volumes/postgres_volume_TIMESTAMP.tar.gz`
- `data/volumes/functions_volume_TIMESTAMP.tar.gz`
- `data/volumes/volumes_backup_TIMESTAMP.tar.gz`
- `data/volumes/volume_backup_TIMESTAMP.meta`

## 🔄 Restore Procedures

### List Available Backups

```dart
# List all backups
ls -lh data/*.tar.gz

# View backup metadata
cat data/backup_TIMESTAMP.meta
```

### Complete System Restore

```dart
# 1. Stop services
cd ../../
docker-compose down

# 2. Restore volumes first
cd deploy/backups
./restore-volumes.sh -f data/volumes/volumes_backup_TIMESTAMP.tar.gz -y

# 3. Start services
cd ../../
docker-compose up -d

# 4. Wait for database to be healthy
docker-compose ps

# 5. Restore databases
cd deploy/backups
./restore-database.sh -f data/full_backup_TIMESTAMP.tar.gz -y
```

### Restore Database Only

```dart
# Restore both databases
./restore-database.sh -f data/full_backup_TIMESTAMP.tar.gz

# Restore main database only
./restore-database.sh -f data/dart_cloud_TIMESTAMP.sql.gz -d main

# Restore functions database only
./restore-database.sh -f data/functions_db_TIMESTAMP.sql.gz -d functions

# Skip confirmation prompt
./restore-database.sh -f data/full_backup_TIMESTAMP.tar.gz -y
```

### Restore Volumes Only

```dart
# Restore all volumes
./restore-volumes.sh -f data/volumes/volumes_backup_TIMESTAMP.tar.gz

# Restore PostgreSQL volume only
./restore-volumes.sh -f data/volumes/postgres_volume_TIMESTAMP.tar.gz -v postgres

# Restore functions volume only
./restore-volumes.sh -f data/volumes/functions_volume_TIMESTAMP.tar.gz -v functions
```

## 🤖 Automated Backups

### Setup Automated Backup Service

1. **Configure backup schedule** in `deploy/.env`:

```dart
# Backup schedule (cron format)
BACKUP_SCHEDULE="0 2 * * *"  # Daily at 2 AM

# Retention periods
BACKUP_RETENTION_DAYS=7
VOLUME_RETENTION_DAYS=7
```

2. **Start the backup service**:

```dart
cd dart_cloud_backend/deploy
docker-compose -f docker-compose.yml -f backups/docker-compose.backup.yml up -d
```

3. **Verify service is running**:

```dart
docker ps | grep backup
docker logs dart_cloud_backup_service
```

### Common Cron Schedules

```dart
# Every day at 2 AM
BACKUP_SCHEDULE="0 2 * * *"

# Every 6 hours
BACKUP_SCHEDULE="0 */6 * * *"

# Every Sunday at 3 AM
BACKUP_SCHEDULE="0 3 * * 0"

# Every day at midnight and noon
BACKUP_SCHEDULE="0 0,12 * * *"

# Every 4 hours (production recommended)
BACKUP_SCHEDULE="0 */4 * * *"
```

### Stop Backup Service

```dart
docker-compose -f docker-compose.yml -f backups/docker-compose.backup.yml down
```

## 🔁 Volume Replication

Volume replication provides geographic redundancy and disaster recovery capabilities.

### Local Replication

Copy backups to a local directory:

```dart
# One-time replication
./replicate-volumes.sh -t local -d /mnt/backup

# Continuous replication (every hour)
./replicate-volumes.sh -t local -d /mnt/backup -c -i 3600
```

### Remote Replication (Rsync)

Sync to a remote server via SSH:

```dart
# Setup SSH key authentication first
ssh-copy-id user@backup-server

# One-time replication
./replicate-volumes.sh -t rsync -d user@backup-server:/backup/volumes

# Continuous replication (every 2 hours)
./replicate-volumes.sh -t rsync -d user@backup-server:/backup/volumes -c -i 7200
```

### S3 Replication

Upload to S3-compatible storage (AWS S3, Cloudflare R2, MinIO):

```dart
# Configure AWS CLI first
aws configure

# One-time replication
./replicate-volumes.sh -t s3 -d s3://my-bucket/backups/volumes

# Continuous replication (every 4 hours)
./replicate-volumes.sh -t s3 -d s3://my-bucket/backups/volumes -c -i 14400
```

### Custom Replication

Use custom replication commands:

```dart
# Set custom command
export REPLICATION_COMMAND="scp"

# Replicate
./replicate-volumes.sh -t custom -d user@server:/backup
```

### Enable Automated Replication

Configure in `deploy/.env`:

```dart
# Enable replication
REPLICATION_ENABLED=true

# Replication type
REPLICATION_TYPE=rsync

# Destination
REPLICATION_TARGET=user@backup-server:/backup/volumes

# Interval (seconds)
REPLICATION_INTERVAL=3600
```

## 📊 Backup Strategy Recommendations

### Development Environment

```dart
Frequency: Daily
Retention: 7 days
Replication: Not required
Schedule: "0 2 * * *"
```

### Staging Environment

```dart
Frequency: Every 6 hours
Retention: 14 days
Replication: Optional (local)
Schedule: "0 */6 * * *"
```

### Production Environment

```dart
Frequency: Every 4 hours
Retention: 30 days
Replication: Required (off-site)
Schedule: "0 */4 * * *"
Testing: Weekly restore tests
```

## 🔐 Security Best Practices

### 1. Encrypt Backups

```dart
# Encrypt backup
gpg --symmetric --cipher-algo AES256 backup.tar.gz

# Decrypt backup
gpg --decrypt backup.tar.gz.gpg > backup.tar.gz
```

### 2. Secure Storage

- Store backups in secure locations with restricted access
- Use encrypted filesystems for backup storage
- Implement access control lists (ACLs)

### 3. Credential Management

- Never commit credentials to version control
- Use environment variables for sensitive data
- Rotate credentials regularly
- Use separate credentials for backup operations

### 4. Access Control

```dart
# Set proper permissions on backup directory
chmod 700 deploy/backups/data
chown backup-user:backup-group deploy/backups/data

# Restrict script execution
chmod 750 deploy/backups/*.sh
```

### 5. Network Security

- Use SSH keys for remote replication
- Enable firewall rules for backup traffic
- Use VPN for sensitive data transfers
- Implement rate limiting

## 🔍 Monitoring and Verification

### Check Backup Status

```dart
# List all backups
ls -lh data/

# View latest backup metadata
cat data/backup_*.meta | tail -n 50

# Check backup integrity
tar -tzf data/full_backup_TIMESTAMP.tar.gz

# Verify database backup
gunzip -c data/dart_cloud_TIMESTAMP.sql.gz | head -n 50
```

### Monitor Disk Usage

```dart
# Check backup directory size
du -sh data/

# List largest backups
du -h data/*.tar.gz | sort -rh | head -n 10

# Check available disk space
df -h
```

### Automated Monitoring

```dart
# View backup service logs
docker logs dart_cloud_backup_service

# Follow logs in real-time
docker logs -f dart_cloud_backup_service

# Check service health
docker inspect dart_cloud_backup_service | grep Health
```

### Backup Verification Script

```dart
#!/bin/bash
# verify-backups.sh

BACKUP_DIR="data"
LATEST_BACKUP=$(ls -t ${BACKUP_DIR}/full_backup_*.tar.gz | head -n 1)

echo "Verifying backup: ${LATEST_BACKUP}"

# Check file exists
if [ ! -f "${LATEST_BACKUP}" ]; then
    echo "ERROR: Backup file not found"
    exit 1
fi

# Check file size (should be > 1MB)
SIZE=$(stat -f%z "${LATEST_BACKUP}")
if [ ${SIZE} -lt 1048576 ]; then
    echo "ERROR: Backup file too small"
    exit 1
fi

# Verify archive integrity
if tar -tzf "${LATEST_BACKUP}" > /dev/null 2>&1; then
    echo "SUCCESS: Backup verified"
    exit 0
else
    echo "ERROR: Backup corrupted"
    exit 1
fi
```

## 🛠️ Troubleshooting

### Backup Fails

**Check container status:**
```dart
docker ps | grep postgres
docker ps | grep backend
```

**Check database connection:**
```dart
docker exec dart_cloud_postgres psql -U dart_cloud -c "SELECT version();"
```

**Verify credentials:**
```dart
# Check .env file
cat deploy/.env | grep POSTGRES

# Test connection
docker exec -e PGPASSWORD="${POSTGRES_PASSWORD}" dart_cloud_postgres \
    psql -U dart_cloud -d dart_cloud -c "SELECT 1;"
```

**Check disk space:**
```dart
df -h
```

### Restore Fails

**Verify backup integrity:**
```dart
# Test archive
tar -tzf data/full_backup_TIMESTAMP.tar.gz

# Test database dump
gunzip -t data/dart_cloud_TIMESTAMP.sql.gz
```

**Check permissions:**
```dart
ls -l data/
```

**Ensure containers are running:**
```dart
docker-compose ps
```

### Replication Issues

**Test SSH connection (rsync):**
```dart
ssh user@backup-server "echo 'Connection successful'"
```

**Test S3 access:**
```dart
aws s3 ls s3://my-bucket/
```

**Check network connectivity:**
```dart
ping backup-server
traceroute backup-server
```

## 📈 Performance Optimization

### Backup Performance

| Component | Typical Time | Size | Impact |
|-----------|--------------|------|--------|
| Database Backup | 1-5 min | 10-100 MB | Low |
| Volume Backup | 2-10 min | 100 MB - 10 GB | Medium |
| Compression | 1-3 min | -70% size | Medium |
| Replication | Varies | N/A | Low-High |

### Optimization Tips

1. **Schedule During Low Traffic**
   - Run backups during off-peak hours
   - Minimize impact on production

2. **Parallel Operations**
   ```dart
   # Backup database and volumes concurrently
   ./backup-database.sh &
   ./backup-volumes.sh &
   wait
   ```

3. **Compression Tuning**
   ```dart
   # Adjust compression level (1-9)
   export COMPRESSION_LEVEL=6  # Balance speed vs. size
   ```

4. **Incremental Backups**
   - Consider incremental volume backups for large datasets
   - Reduces backup time and storage

## 📋 Backup Checklist

### Daily Tasks
- [ ] Verify automated backups completed
- [ ] Check backup service logs
- [ ] Monitor disk space usage

### Weekly Tasks
- [ ] Review backup sizes and trends
- [ ] Test restore procedure (non-production)
- [ ] Verify replication status
- [ ] Clean up old backups manually if needed

### Monthly Tasks
- [ ] Perform full disaster recovery test
- [ ] Review and update backup strategy
- [ ] Audit backup access logs
- [ ] Update documentation

### Quarterly Tasks
- [ ] Review retention policies
- [ ] Test off-site restore
- [ ] Update backup scripts
- [ ] Train team on recovery procedures

## 🎯 3-2-1 Backup Rule

Follow the industry-standard **3-2-1 backup rule**:

- **3** copies of data
  - Production database
  - Local backup
  - Replicated backup

- **2** different storage types
  - Docker volumes (production)
  - Compressed archives (backup)

- **1** off-site copy
  - Remote server (rsync)
  - Cloud storage (S3)
  - Geographic redundancy

## 🚨 Disaster Recovery

### Recovery Time Objective (RTO)

**Target:** < 1 hour  
**Typical:** 15-30 minutes

### Recovery Point Objective (RPO)

**Target:** < 4 hours  
**Actual:** Based on backup schedule

### Recovery Procedures

1. **Assess the situation**
   - Identify what data is lost
   - Determine last known good backup

2. **Communicate**
   - Notify stakeholders
   - Document the incident

3. **Execute recovery**
   - Follow restore procedures
   - Verify data integrity

4. **Validate**
   - Test system functionality
   - Verify data completeness

5. **Post-mortem**
   - Document lessons learned
   - Update procedures

## 📚 Configuration Reference

### Environment Variables

```dart
# Database Configuration
POSTGRES_USER=dart_cloud
POSTGRES_PASSWORD=secure_password
POSTGRES_DB=dart_cloud
FUNCTION_DB=functions_db
POSTGRES_HOST=postgres
POSTGRES_CONTAINER=dart_cloud_postgres

# Volume Configuration
POSTGRES_VOLUME=dart_cloud_backend_postgres_data
FUNCTIONS_VOLUME=dart_cloud_backend_functions_data

# Backup Configuration
BACKUP_RETENTION_DAYS=7
VOLUME_RETENTION_DAYS=7
BACKUP_SCHEDULE="0 2 * * *"

# Replication Configuration
REPLICATION_ENABLED=false
REPLICATION_TYPE=local
REPLICATION_TARGET=/mnt/backup
REPLICATION_INTERVAL=3600
```

### Script Options

**backup-database.sh:**
```dart
BACKUP_RETENTION_DAYS=7 ./backup-database.sh
```

**restore-database.sh:**
```dart
./restore-database.sh -f FILE [-d main|functions|both] [-y]
```

**backup-volumes.sh:**
```dart
VOLUME_RETENTION_DAYS=7 ./backup-volumes.sh
```

**restore-volumes.sh:**
```dart
./restore-volumes.sh -f FILE [-v postgres|functions|both] [-y]
```

**replicate-volumes.sh:**
```dart
./replicate-volumes.sh -t TYPE -d DEST [-v VOLUME] [-c] [-i INTERVAL]
```

## 🔗 Additional Resources
- [PostgreSQL Backup Documentation](https://www.postgresql.org/docs/current/backup.html)
- [Docker Volume Management](https://docs.docker.com/storage/volumes/)

## 📞 Support

For backup-related issues:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review backup logs in `data/*.log`
3. Check Docker logs: `docker-compose logs`
4. Consult the [Architecture Documentation](../architecture.md)

---

**Last Updated:** November 2025  
**Version:** 1.0.0
