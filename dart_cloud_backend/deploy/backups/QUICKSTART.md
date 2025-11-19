# Backup System Quick Start Guide

Get started with the Dart Cloud Backend backup system in 5 minutes.

## 🚀 Setup (One-time)

### 1. Make Scripts Executable

```bash
cd deploy/backups
chmod +x *.sh
```

### 2. Configure Environment (Optional)

Edit `deploy/.env` to customize backup settings:

```bash
# Backup retention (default: 7 days)
BACKUP_RETENTION_DAYS=7
VOLUME_RETENTION_DAYS=7

# Backup schedule (default: daily at 2 AM)
BACKUP_SCHEDULE="0 2 * * *"
```

## 📦 Manual Backups

### Quick Backup (Everything)

```bash
./backup-all.sh
```

This creates:
- ✅ Database backups (main + functions)
- ✅ Volume backups (PostgreSQL + functions data)
- ✅ Combined archive
- ✅ Backup manifest with restore instructions

### Database Only

```bash
./backup-database.sh
```

### Volumes Only

```bash
./backup-volumes.sh
```

## 🔄 Restore

### List Available Backups

```bash
ls -lh data/*.tar.gz
```

### Restore Everything

```bash
# 1. Stop services
cd ../.. && docker-compose down

# 2. Restore volumes
cd deploy/backups
./restore-volumes.sh -f data/volumes/volumes_backup_YYYYMMDD_HHMMSS.tar.gz -y

# 3. Start services
cd ../.. && docker-compose up -d

# 4. Restore databases
cd deploy/backups
./restore-database.sh -f data/full_backup_YYYYMMDD_HHMMSS.tar.gz -y
```

### Restore Database Only

```bash
./restore-database.sh -f data/full_backup_YYYYMMDD_HHMMSS.tar.gz
```

### Restore Volumes Only

```bash
./restore-volumes.sh -f data/volumes/volumes_backup_YYYYMMDD_HHMMSS.tar.gz
```

## 🤖 Automated Backups

### Start Automated Backup Service

```bash
cd ..
docker-compose -f docker-compose.yml -f backups/docker-compose.backup.yml up -d
```

### Check Backup Service Status

```bash
docker logs dart_cloud_backup_service
```

### Stop Backup Service

```bash
docker-compose -f docker-compose.yml -f backups/docker-compose.backup.yml down
```

## 🔁 Volume Replication

### Local Replication

```bash
# One-time replication
./replicate-volumes.sh -t local -d /mnt/backup

# Continuous replication (every hour)
./replicate-volumes.sh -t local -d /mnt/backup -c -i 3600
```

### Remote Replication (rsync)

```bash
# Setup SSH key authentication first
ssh-copy-id user@backup-server

# Replicate
./replicate-volumes.sh -t rsync -d user@backup-server:/backup/volumes
```

### S3 Replication

```bash
# Configure AWS CLI first
aws configure

# Replicate to S3
./replicate-volumes.sh -t s3 -d s3://my-bucket/backups/volumes
```

## 📊 Monitoring

### Check Backup Status

```bash
# List all backups
ls -lh data/

# View latest backup metadata
cat data/backup_*.meta | tail -n 50

# Check disk usage
du -sh data/
```

### View Backup Logs

```bash
# Automated backup service logs
docker logs dart_cloud_backup_service

# Manual backup logs
cat data/*.log
```

## 🔧 Common Tasks

### Change Backup Schedule

Edit `deploy/.env`:
```bash
# Every 6 hours
BACKUP_SCHEDULE="0 */6 * * *"

# Every Sunday at 3 AM
BACKUP_SCHEDULE="0 3 * * 0"
```

Restart backup service:
```bash
docker-compose -f docker-compose.yml -f backups/docker-compose.backup.yml restart backup-service
```

### Clean Old Backups Manually

```bash
# Remove backups older than 30 days
find data/ -name "*.tar.gz" -mtime +30 -delete
find data/ -name "*.sql.gz" -mtime +30 -delete
```

### Test Backup Integrity

```bash
# Test database backup
gunzip -t data/dart_cloud_*.sql.gz

# Test archive
tar -tzf data/full_backup_*.tar.gz > /dev/null
```

## ⚠️ Important Notes

1. **Always test restores** in a non-production environment first
2. **Keep backups secure** - they contain sensitive data
3. **Monitor disk space** - backups can grow large
4. **Use off-site backups** for production systems
5. **Document your restore procedures**

## 🆘 Troubleshooting

### Backup Fails

```bash
# Check if containers are running
docker ps

# Check database connection
docker exec dart_cloud_postgres psql -U dart_cloud -c "SELECT 1;"

# Check disk space
df -h
```

### Restore Fails

```bash
# Verify backup file
tar -tzf data/full_backup_*.tar.gz

# Check permissions
ls -l data/

# View detailed error
./restore-database.sh -f data/full_backup_*.tar.gz 2>&1 | tee restore.log
```

## 📚 Full Documentation

For detailed information, see [README.md](README.md)

## 🎯 Quick Reference

| Task | Command |
|------|---------|
| Backup everything | `./backup-all.sh` |
| Backup database | `./backup-database.sh` |
| Backup volumes | `./backup-volumes.sh` |
| Restore database | `./restore-database.sh -f FILE` |
| Restore volumes | `./restore-volumes.sh -f FILE` |
| Replicate volumes | `./replicate-volumes.sh -t TYPE -d DEST` |
| List backups | `ls -lh data/` |
| Check logs | `docker logs dart_cloud_backup_service` |

## 💡 Pro Tips

1. **Schedule regular test restores** to verify backup integrity
2. **Use replication** for critical production data
3. **Monitor backup sizes** to detect issues early
4. **Keep multiple backup generations** for point-in-time recovery
5. **Document your backup strategy** and share with your team
