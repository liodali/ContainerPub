---
title: Backup Quick Reference
description: Quick reference guide for backup and restore operations
---

# Backup Quick Reference

Fast reference for common backup and restore operations in ContainerPub.

## 🎯 Quick Commands

### Backup Operations

```dart
# Navigate to backup directory
cd dart_cloud_backend/deploy/backups

# Complete backup (everything)
./backup-all.sh

# Database only
./backup-database.sh

# Volumes only
./backup-volumes.sh
```

### Restore Operations

```dart
# List available backups
ls -lh data/*.tar.gz

# Restore database
./restore-database.sh -f data/full_backup_TIMESTAMP.tar.gz

# Restore volumes
./restore-volumes.sh -f data/volumes/volumes_backup_TIMESTAMP.tar.gz

# Skip confirmation
./restore-database.sh -f data/full_backup_TIMESTAMP.tar.gz -y
```

### Replication

```dart
# Local replication
./replicate-volumes.sh -t local -d /mnt/backup

# Remote replication (rsync)
./replicate-volumes.sh -t rsync -d user@server:/backup/volumes

# S3 replication
./replicate-volumes.sh -t s3 -d s3://bucket/backups/volumes

# Continuous replication (every hour)
./replicate-volumes.sh -t local -d /mnt/backup -c -i 3600
```

## 📋 Common Scenarios

### Scenario 1: Daily Backup

```dart
# Setup automated daily backups at 2 AM
cd dart_cloud_backend/deploy

# Edit .env
echo 'BACKUP_SCHEDULE="0 2 * * *"' >> .env
echo 'BACKUP_RETENTION_DAYS=7' >> .env

# Start backup service
docker-compose -f docker-compose.yml -f backups/docker-compose.backup.yml up -d

# Verify
docker logs dart_cloud_backup_service
```

### Scenario 2: Emergency Restore

```dart
# 1. Stop services
cd dart_cloud_backend
docker-compose down

# 2. Restore volumes
cd deploy/backups
./restore-volumes.sh -f data/volumes/volumes_backup_TIMESTAMP.tar.gz -y

# 3. Start services
cd ../../
docker-compose up -d

# 4. Restore databases
cd deploy/backups
./restore-database.sh -f data/full_backup_TIMESTAMP.tar.gz -y

# 5. Verify
cd ../../
docker-compose ps
docker-compose logs -f
```

### Scenario 3: Migrate to New Server

```dart
# On old server - create backup
./backup-all.sh

# Copy to new server
scp -r data/ user@new-server:/path/to/backups/

# On new server - restore
./restore-volumes.sh -f data/volumes/volumes_backup_TIMESTAMP.tar.gz -y
docker-compose up -d
./restore-database.sh -f data/full_backup_TIMESTAMP.tar.gz -y
```

### Scenario 4: Setup Off-site Replication

```dart
# Setup SSH keys
ssh-keygen -t ed25519
ssh-copy-id user@backup-server

# Configure in .env
cat >> ../deploy/.env << EOF
REPLICATION_ENABLED=true
REPLICATION_TYPE=rsync
REPLICATION_TARGET=user@backup-server:/backup/volumes
REPLICATION_INTERVAL=3600
EOF

# Start backup service with replication
docker-compose -f docker-compose.yml -f backups/docker-compose.backup.yml up -d
```

## 🔧 Troubleshooting Commands

### Check Backup Status

```dart
# List all backups
ls -lh data/

# View latest backup metadata
cat data/backup_*.meta | tail -n 50

# Check backup integrity
tar -tzf data/full_backup_TIMESTAMP.tar.gz

# Verify database backup
gunzip -t data/dart_cloud_TIMESTAMP.sql.gz
```

### Check Service Status

```dart
# Check containers
docker ps | grep postgres
docker ps | grep backup

# View logs
docker logs dart_cloud_backup_service
docker logs dart_cloud_postgres

# Check disk space
df -h
du -sh data/
```

### Test Database Connection

```dart
# Test PostgreSQL connection
docker exec dart_cloud_postgres psql -U dart_cloud -c "SELECT version();"

# Check database size
docker exec dart_cloud_postgres psql -U dart_cloud -d dart_cloud -c "
  SELECT pg_size_pretty(pg_database_size('dart_cloud')) as size;
"
```

## 📊 Backup Schedule Examples

```dart
# Every day at 2 AM
BACKUP_SCHEDULE="0 2 * * *"

# Every 4 hours (production)
BACKUP_SCHEDULE="0 */4 * * *"

# Every 6 hours
BACKUP_SCHEDULE="0 */6 * * *"

# Every Sunday at 3 AM
BACKUP_SCHEDULE="0 3 * * 0"

# Twice daily (midnight and noon)
BACKUP_SCHEDULE="0 0,12 * * *"

# Every hour
BACKUP_SCHEDULE="0 * * * *"
```

## 🎯 Script Options Reference

### backup-database.sh

```dart
# Set retention period
BACKUP_RETENTION_DAYS=14 ./backup-database.sh

# Custom container name
POSTGRES_CONTAINER=my_postgres ./backup-database.sh
```

### restore-database.sh

```dart
# Options
-f, --file FILE         # Backup file (required)
-d, --database DB       # Database: main|functions|both (default: both)
-y, --yes              # Skip confirmation
-h, --help             # Show help

# Examples
./restore-database.sh -f backup.tar.gz
./restore-database.sh -f backup.tar.gz -d main
./restore-database.sh -f backup.tar.gz -y
```

### backup-volumes.sh

```dart
# Set retention period
VOLUME_RETENTION_DAYS=14 ./backup-volumes.sh

# Custom volume names
POSTGRES_VOLUME=my_postgres_data ./backup-volumes.sh
```

### restore-volumes.sh

```dart
# Options
-f, --file FILE         # Backup file (required)
-v, --volume VOLUME     # Volume: postgres|functions|both (default: both)
-y, --yes              # Skip confirmation
-h, --help             # Show help

# Examples
./restore-volumes.sh -f volumes_backup.tar.gz
./restore-volumes.sh -f volumes_backup.tar.gz -v postgres
./restore-volumes.sh -f volumes_backup.tar.gz -y
```

### replicate-volumes.sh

```dart
# Options
-t, --type TYPE         # Replication type: local|rsync|s3|custom
-d, --destination DEST  # Destination path or URL
-v, --volume VOLUME     # Volume: postgres|functions|both (default: both)
-c, --continuous        # Run continuously
-i, --interval SECONDS  # Replication interval (default: 3600)
-h, --help             # Show help

# Examples
./replicate-volumes.sh -t local -d /mnt/backup
./replicate-volumes.sh -t rsync -d user@server:/backup
./replicate-volumes.sh -t s3 -d s3://bucket/backups
./replicate-volumes.sh -t local -d /mnt/backup -c -i 3600
```

## 🔐 Security Checklist

- [ ] Backup files stored in secure location
- [ ] Proper file permissions set (700 for data directory)
- [ ] Credentials not committed to version control
- [ ] SSH keys configured for remote replication
- [ ] Backups encrypted if containing sensitive data
- [ ] Regular restore testing performed
- [ ] Off-site backups configured
- [ ] Access logs monitored

## 📈 Monitoring Checklist

- [ ] Automated backups running on schedule
- [ ] Backup service logs reviewed regularly
- [ ] Disk space monitored
- [ ] Backup sizes tracked for anomalies
- [ ] Replication status verified
- [ ] Failed backups alerted
- [ ] Restore procedures tested monthly

## 🚨 Emergency Contacts

```dart
# Check system status
docker-compose ps
docker-compose logs --tail=100

# Quick health check
curl http://localhost:8080/health

# Database connection test
docker exec dart_cloud_postgres pg_isready -U dart_cloud
```

## 📚 Related Documentation

- [Complete Backup Strategy](./backup-strategy.md) - Full documentation
- [Architecture Overview](../architecture.md) - System architecture
- [Database System](./database-system.md) - Database documentation
- [Development Guide](../development.md) - Development workflows

## 💡 Pro Tips

1. **Always test restores** - Don't trust backups you haven't tested
2. **Use replication** - Keep off-site copies for disaster recovery
3. **Monitor disk space** - Set up alerts for low disk space
4. **Document procedures** - Keep runbooks up to date
5. **Automate everything** - Manual backups are forgotten backups
6. **Version your scripts** - Track changes to backup procedures
7. **Test in staging first** - Never test restores in production
8. **Keep multiple generations** - Don't rely on a single backup

## 🔗 Quick Links

| Task | Command |
|------|---------|
| Backup everything | `./backup-all.sh` |
| Restore database | `./restore-database.sh -f FILE` |
| Restore volumes | `./restore-volumes.sh -f FILE` |
| Replicate | `./replicate-volumes.sh -t TYPE -d DEST` |
| List backups | `ls -lh data/` |
| Check logs | `docker logs dart_cloud_backup_service` |
| Verify backup | `tar -tzf FILE` |
| Test DB | `docker exec dart_cloud_postgres psql -U dart_cloud -c "SELECT 1;"` |

---

**Last Updated:** November 2025  
**Version:** 1.0.0
