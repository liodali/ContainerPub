# Backup and Replication System

Comprehensive backup and replication solution for Dart Cloud Backend, including database backups, volume backups, and volume replication capabilities.

## 📁 Directory Structure

```
deploy/backups/
├── README.md                    # This file
├── backup-database.sh           # Database backup script
├── restore-database.sh          # Database restore script
├── backup-volumes.sh            # Docker volume backup script
├── restore-volumes.sh           # Docker volume restore script
├── backup-all.sh                # Complete backup (DB + volumes)
├── replicate-volumes.sh         # Volume replication script
├── docker-compose.backup.yml    # Backup service configuration
└── data/                        # Backup storage (gitignored)
    ├── *.sql.gz                 # Database backups
    ├── *.tar.gz                 # Archive backups
    ├── *.meta                   # Backup metadata
    └── volumes/                 # Volume backups
```

## 🚀 Quick Start

### Prerequisites

1. Docker and Docker Compose installed
2. Dart Cloud Backend stack running
3. Proper permissions to execute scripts

### Make Scripts Executable

```bash
chmod +x *.sh
```

## 📊 Database Backups

### Create Database Backup

```bash
# Backup both databases (main + functions)
./backup-database.sh

# Set custom retention period (default: 7 days)
BACKUP_RETENTION_DAYS=14 ./backup-database.sh
```

**Output:**
- `data/dart_cloud_YYYYMMDD_HHMMSS.sql.gz` - Main database backup
- `data/functions_db_YYYYMMDD_HHMMSS.sql.gz` - Functions database backup
- `data/full_backup_YYYYMMDD_HHMMSS.tar.gz` - Combined archive
- `data/backup_YYYYMMDD_HHMMSS.meta` - Backup metadata

### Restore Database

```bash
# Restore both databases from archive
./restore-database.sh -f data/full_backup_20240101_120000.tar.gz

# Restore only main database
./restore-database.sh -f data/dart_cloud_20240101_120000.sql.gz -d main

# Restore only functions database
./restore-database.sh -f data/functions_db_20240101_120000.sql.gz -d functions

# Skip confirmation prompt
./restore-database.sh -f data/full_backup_20240101_120000.tar.gz -y
```

## 💾 Volume Backups

### Create Volume Backup

```bash
# Backup all volumes
./backup-volumes.sh

# Set custom retention period (default: 7 days)
VOLUME_RETENTION_DAYS=14 ./backup-volumes.sh
```

**Output:**
- `data/volumes/postgres_volume_YYYYMMDD_HHMMSS.tar.gz` - PostgreSQL data volume
- `data/volumes/functions_volume_YYYYMMDD_HHMMSS.tar.gz` - Functions data volume
- `data/volumes/volumes_backup_YYYYMMDD_HHMMSS.tar.gz` - Combined archive
- `data/volumes/volume_backup_YYYYMMDD_HHMMSS.meta` - Volume metadata

### Restore Volume

```bash
# Restore all volumes from archive
./restore-volumes.sh -f data/volumes/volumes_backup_20240101_120000.tar.gz

# Restore only PostgreSQL volume
./restore-volumes.sh -f data/volumes/postgres_volume_20240101_120000.tar.gz -v postgres

# Restore only functions volume
./restore-volumes.sh -f data/volumes/functions_volume_20240101_120000.tar.gz -v functions

# Skip confirmation prompt
./restore-volumes.sh -f data/volumes/volumes_backup_20240101_120000.tar.gz -y
```

## 🔄 Complete Backup

### Backup Everything (Databases + Volumes)

```bash
# Create complete backup
./backup-all.sh
```

**Output:**
- All database backups
- All volume backups
- `data/complete_backup_YYYYMMDD_HHMMSS.tar.gz` - Complete archive
- `data/backup_manifest_YYYYMMDD_HHMMSS.txt` - Detailed manifest with restore instructions

## 🔁 Volume Replication

Volume replication allows you to continuously sync volumes to remote locations for disaster recovery.

### Local Replication

```bash
# Replicate to local directory
./replicate-volumes.sh -t local -d /mnt/backup

# Continuous replication every hour
./replicate-volumes.sh -t local -d /mnt/backup -c -i 3600
```

### Remote Replication (rsync)

```bash
# One-time replication to remote server
./replicate-volumes.sh -t rsync -d user@backup-server:/backup/volumes

# Continuous replication
./replicate-volumes.sh -t rsync -d user@backup-server:/backup/volumes -c -i 3600
```

### S3 Replication

```bash
# Replicate to S3 bucket (requires AWS CLI)
./replicate-volumes.sh -t s3 -d s3://my-bucket/backups/volumes

# Continuous replication to S3
./replicate-volumes.sh -t s3 -d s3://my-bucket/backups/volumes -c -i 7200
```

### Custom Replication

```bash
# Set custom replication command
export REPLICATION_COMMAND="scp"
./replicate-volumes.sh -t custom -d user@server:/backup
```

## 🐳 Automated Backups with Docker Compose

### Setup Automated Backup Service

1. Copy the backup service configuration:
```bash
cp docker-compose.backup.yml ../docker-compose.backup.yml
```

2. Configure backup schedule in `.env`:
```bash
# Backup configuration
BACKUP_SCHEDULE="0 2 * * *"  # Daily at 2 AM
BACKUP_RETENTION_DAYS=7
VOLUME_RETENTION_DAYS=7
REPLICATION_ENABLED=false
```

3. Start the backup service:
```bash
cd ..
docker-compose -f docker-compose.yml -f docker-compose.backup.yml up -d
```

### Backup Service Features

- **Automated Scheduling**: Runs backups on cron schedule
- **Health Monitoring**: Tracks backup success/failure
- **Log Management**: Centralized backup logs
- **Retention Management**: Automatic cleanup of old backups

## 📅 Backup Schedules

Common cron schedule examples:

```bash
# Every day at 2 AM
BACKUP_SCHEDULE="0 2 * * *"

# Every 6 hours
BACKUP_SCHEDULE="0 */6 * * *"

# Every Sunday at 3 AM
BACKUP_SCHEDULE="0 3 * * 0"

# Every day at midnight and noon
BACKUP_SCHEDULE="0 0,12 * * *"
```

## 🔐 Security Best Practices

1. **Encrypt Backups**: Use encryption for sensitive data
   ```bash
   # Encrypt backup
   gpg --symmetric --cipher-algo AES256 backup.tar.gz
   
   # Decrypt backup
   gpg --decrypt backup.tar.gz.gpg > backup.tar.gz
   ```

2. **Secure Storage**: Store backups in secure locations with restricted access

3. **Test Restores**: Regularly test backup restoration procedures

4. **Off-site Backups**: Keep copies in different geographic locations

5. **Access Control**: Limit who can create and restore backups

## 🔍 Monitoring and Verification

### Check Backup Status

```bash
# List all backups
ls -lh data/*.tar.gz

# View backup metadata
cat data/backup_20240101_120000.meta

# Check backup integrity
tar -tzf data/full_backup_20240101_120000.tar.gz
```

### Verify Database Backup

```bash
# Test database backup without restoring
gunzip -c data/dart_cloud_20240101_120000.sql.gz | head -n 50
```

### Monitor Disk Usage

```bash
# Check backup directory size
du -sh data/

# List largest backups
du -h data/*.tar.gz | sort -rh | head -n 10
```

## 🛠️ Troubleshooting

### Database Backup Fails

```bash
# Check if PostgreSQL container is running
docker ps | grep postgres

# Check database connection
docker exec dart_cloud_postgres psql -U dart_cloud -c "SELECT version();"

# Verify credentials in .env file
cat ../deploy/.env | grep POSTGRES
```

### Volume Backup Fails

```bash
# List Docker volumes
docker volume ls

# Inspect volume
docker volume inspect dart_cloud_backend_postgres_data

# Check disk space
df -h
```

### Restore Fails

```bash
# Verify backup file integrity
tar -tzf data/full_backup_20240101_120000.tar.gz

# Check permissions
ls -l data/

# Ensure containers are running
docker-compose ps
```

## 📝 Environment Variables

Configure these in `../deploy/.env`:

```bash
# Database Configuration
POSTGRES_USER=dart_cloud
POSTGRES_PASSWORD=your_secure_password
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

## 🔄 Disaster Recovery

### Complete System Restore

1. **Restore Volumes First**:
   ```bash
   ./restore-volumes.sh -f data/volumes/volumes_backup_20240101_120000.tar.gz -y
   ```

2. **Start Services**:
   ```bash
   cd .. && docker-compose up -d
   ```

3. **Restore Databases**:
   ```bash
   cd backups
   ./restore-database.sh -f data/full_backup_20240101_120000.tar.gz -y
   ```

4. **Verify Services**:
   ```bash
   docker-compose ps
   docker-compose logs -f
   ```

## 📊 Backup Strategy Recommendations

### Development Environment
- **Frequency**: Daily
- **Retention**: 7 days
- **Replication**: Not required

### Staging Environment
- **Frequency**: Every 6 hours
- **Retention**: 14 days
- **Replication**: Optional (local)

### Production Environment
- **Frequency**: Every 4 hours
- **Retention**: 30 days
- **Replication**: Required (off-site)
- **Testing**: Weekly restore tests

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Review backup logs in `data/*.log`
3. Check Docker logs: `docker-compose logs`
4. Consult the main project documentation

## 📄 License

Part of the Dart Cloud Backend project.
