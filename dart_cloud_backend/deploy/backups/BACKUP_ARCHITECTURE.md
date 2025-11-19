# Backup System Architecture

Complete architecture documentation for the Dart Cloud Backend backup and disaster recovery system.

## 🏗️ System Overview

The backup system provides comprehensive data protection through:

1. **Database Backups** - PostgreSQL database dumps
2. **Volume Backups** - Docker volume snapshots
3. **Volume Replication** - Real-time or scheduled replication
4. **Automated Scheduling** - Cron-based backup automation
5. **Disaster Recovery** - Complete system restore procedures

## 📐 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                   Dart Cloud Backend Stack                   │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐         ┌──────────────┐                  │
│  │  PostgreSQL  │         │   Backend    │                  │
│  │   Container  │         │   Container  │                  │
│  └──────┬───────┘         └──────┬───────┘                  │
│         │                        │                           │
│         │                        │                           │
│  ┌──────▼───────┐         ┌─────▼────────┐                 │
│  │ postgres_data│         │functions_data│                  │
│  │   Volume     │         │   Volume     │                  │
│  └──────┬───────┘         └──────┬───────┘                  │
│         │                        │                           │
└─────────┼────────────────────────┼───────────────────────────┘
          │                        │
          │                        │
┌─────────▼────────────────────────▼───────────────────────────┐
│                    Backup System Layer                        │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────┐    ┌──────────────────┐               │
│  │  Database Backup │    │  Volume Backup   │               │
│  │   (pg_dump)      │    │  (tar archive)   │               │
│  └────────┬─────────┘    └────────┬─────────┘               │
│           │                       │                          │
│           └───────────┬───────────┘                          │
│                       │                                      │
│              ┌────────▼────────┐                             │
│              │  Backup Storage │                             │
│              │  (data/ dir)    │                             │
│              └────────┬────────┘                             │
│                       │                                      │
└───────────────────────┼──────────────────────────────────────┘
                        │
                        │
┌───────────────────────▼──────────────────────────────────────┐
│                 Replication Layer (Optional)                  │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  Local   │  │  Rsync   │  │    S3    │  │  Custom  │    │
│  │  Storage │  │  Remote  │  │  Bucket  │  │  Script  │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

## 🔧 Components

### 1. Database Backup System

**Script:** `backup-database.sh`

**Process:**
1. Connects to PostgreSQL container
2. Dumps main database (`dart_cloud`)
3. Dumps functions database (`functions_db`)
4. Compresses dumps with gzip
5. Creates combined archive
6. Generates metadata file
7. Cleans old backups based on retention policy

**Output Files:**
- `dart_cloud_TIMESTAMP.sql.gz` - Main database backup
- `functions_db_TIMESTAMP.sql.gz` - Functions database backup
- `full_backup_TIMESTAMP.tar.gz` - Combined archive
- `backup_TIMESTAMP.meta` - Backup metadata

**Technologies:**
- PostgreSQL `pg_dump` utility
- Gzip compression
- Docker exec for container access

### 2. Volume Backup System

**Script:** `backup-volumes.sh`

**Process:**
1. Creates temporary Alpine container
2. Mounts volume as read-only
3. Creates tar.gz archive of volume contents
4. Stores archive in backup directory
5. Generates volume metadata
6. Cleans old backups

**Output Files:**
- `postgres_volume_TIMESTAMP.tar.gz` - PostgreSQL data volume
- `functions_volume_TIMESTAMP.tar.gz` - Functions data volume
- `volumes_backup_TIMESTAMP.tar.gz` - Combined archive
- `volume_backup_TIMESTAMP.meta` - Volume metadata

**Technologies:**
- Docker volumes
- Alpine Linux container
- Tar compression

### 3. Volume Replication System

**Script:** `replicate-volumes.sh`

**Replication Types:**

#### Local Replication
- Copies backups to local filesystem
- Fast and simple
- Good for same-server redundancy

#### Rsync Replication
- Syncs to remote server via SSH
- Efficient incremental transfers
- Requires SSH key authentication

#### S3 Replication
- Uploads to S3-compatible storage
- Geographic redundancy
- Requires AWS CLI

#### Custom Replication
- User-defined replication command
- Maximum flexibility
- Custom integration support

**Features:**
- One-time or continuous replication
- Configurable intervals
- Multiple destination support
- Error handling and logging

### 4. Automated Backup Service

**Configuration:** `docker-compose.backup.yml`

**Components:**

#### Backup Service Container
- Alpine Linux base
- Cron scheduler
- Docker CLI for volume operations
- Bash for script execution

**Features:**
- Cron-based scheduling
- Environment variable configuration
- Health checks
- Log management
- Automatic retention cleanup

#### Backup Monitor (Optional)
- Real-time backup monitoring
- Status reporting
- Disk usage tracking
- Latest backup information

### 5. Restore System

**Scripts:**
- `restore-database.sh` - Database restoration
- `restore-volumes.sh` - Volume restoration

**Process:**
1. Validates backup file
2. Extracts archive
3. Stops services (if needed)
4. Restores data
5. Verifies restoration
6. Restarts services

**Safety Features:**
- Confirmation prompts
- Backup validation
- Selective restoration
- Error handling

## 🔄 Data Flow

### Backup Flow

```
1. Trigger (Manual/Scheduled)
   ↓
2. Pre-backup Checks
   - Container status
   - Disk space
   - Credentials
   ↓
3. Database Backup
   - pg_dump main DB
   - pg_dump functions DB
   - Compress dumps
   ↓
4. Volume Backup
   - Mount volumes
   - Create tar archives
   - Compress archives
   ↓
5. Post-backup Tasks
   - Create metadata
   - Verify backups
   - Clean old backups
   ↓
6. Replication (Optional)
   - Copy to destination
   - Verify transfer
   - Update logs
   ↓
7. Notification (Optional)
   - Send status email
   - Webhook notification
```

### Restore Flow

```
1. Restore Request
   ↓
2. Pre-restore Checks
   - Backup file exists
   - Backup integrity
   - Confirmation
   ↓
3. Service Shutdown
   - Stop backend
   - Keep database running
   ↓
4. Volume Restore (if needed)
   - Extract volume backup
   - Mount and restore
   ↓
5. Service Startup
   - Start database
   - Wait for health
   ↓
6. Database Restore
   - Extract SQL dumps
   - Execute restore
   - Verify data
   ↓
7. Service Restart
   - Start backend
   - Verify health
   ↓
8. Post-restore Validation
   - Check data integrity
   - Test connections
   - Verify functionality
```

## 📊 Storage Structure

```
deploy/backups/
├── scripts/
│   ├── backup-database.sh
│   ├── backup-volumes.sh
│   ├── backup-all.sh
│   ├── restore-database.sh
│   ├── restore-volumes.sh
│   └── replicate-volumes.sh
│
├── data/                        # Gitignored
│   ├── dart_cloud_*.sql.gz      # Database backups
│   ├── functions_db_*.sql.gz    # Function DB backups
│   ├── full_backup_*.tar.gz     # Combined DB archives
│   ├── complete_backup_*.tar.gz # Complete system backups
│   ├── backup_*.meta            # Backup metadata
│   ├── backup_manifest_*.txt    # Backup manifests
│   │
│   └── volumes/
│       ├── postgres_volume_*.tar.gz
│       ├── functions_volume_*.tar.gz
│       ├── volumes_backup_*.tar.gz
│       └── volume_backup_*.meta
│
├── config/
│   ├── .backup.conf             # Default configuration
│   └── docker-compose.backup.yml
│
└── docs/
    ├── README.md
    ├── QUICKSTART.md
    └── BACKUP_ARCHITECTURE.md
```

## 🔐 Security Considerations

### 1. Access Control
- Backup scripts require Docker access
- Database credentials in environment variables
- Restricted file permissions on backups

### 2. Data Protection
- Backups contain sensitive data
- Should be encrypted at rest
- Secure transmission for replication

### 3. Credential Management
- Never commit credentials to git
- Use environment variables
- Rotate credentials regularly

### 4. Backup Integrity
- Checksums for verification
- Regular restore testing
- Backup validation

## 📈 Performance Considerations

### Backup Performance

| Component | Time | Size | Impact |
|-----------|------|------|--------|
| Database Backup | 1-5 min | 10-100 MB | Low |
| Volume Backup | 2-10 min | 100 MB - 10 GB | Medium |
| Compression | 1-3 min | -70% size | Medium |
| Replication | Varies | N/A | Low-High |

### Optimization Tips

1. **Schedule During Low Traffic**
   - Run backups during off-peak hours
   - Minimize impact on production

2. **Incremental Backups**
   - Consider incremental volume backups
   - Reduces backup time and storage

3. **Parallel Operations**
   - Backup database and volumes concurrently
   - Utilize multiple CPU cores

4. **Compression Tuning**
   - Balance compression ratio vs. speed
   - Use appropriate compression level

## 🔍 Monitoring and Alerting

### Metrics to Monitor

1. **Backup Success Rate**
   - Track successful vs. failed backups
   - Alert on consecutive failures

2. **Backup Duration**
   - Monitor backup completion time
   - Alert on abnormal durations

3. **Backup Size**
   - Track backup growth over time
   - Alert on unexpected size changes

4. **Storage Usage**
   - Monitor backup directory size
   - Alert on low disk space

5. **Replication Status**
   - Track replication success
   - Monitor replication lag

### Alerting Strategies

```bash
# Example: Email notification on backup failure
if [ $BACKUP_STATUS -ne 0 ]; then
    echo "Backup failed at $(date)" | \
    mail -s "Backup Failure Alert" admin@example.com
fi

# Example: Webhook notification
curl -X POST https://hooks.example.com/backup \
    -H "Content-Type: application/json" \
    -d '{"status":"failed","timestamp":"'$(date)'"}'
```

## 🎯 Best Practices

### 1. Backup Strategy (3-2-1 Rule)
- **3** copies of data
- **2** different storage types
- **1** off-site copy

### 2. Regular Testing
- Test restores monthly
- Document restore procedures
- Train team on recovery process

### 3. Retention Policy
- Keep daily backups for 7 days
- Keep weekly backups for 4 weeks
- Keep monthly backups for 12 months

### 4. Documentation
- Document backup procedures
- Maintain runbooks
- Update after changes

### 5. Automation
- Automate backup creation
- Automate backup verification
- Automate retention cleanup

## 🚨 Disaster Recovery

### Recovery Time Objective (RTO)
- Target: < 1 hour
- Actual: 15-30 minutes (typical)

### Recovery Point Objective (RPO)
- Target: < 4 hours
- Actual: Based on backup schedule

### Recovery Procedures

See [QUICKSTART.md](QUICKSTART.md) for detailed recovery procedures.

## 📚 References

- [PostgreSQL Backup Documentation](https://www.postgresql.org/docs/current/backup.html)
- [Docker Volume Management](https://docs.docker.com/storage/volumes/)
- [Backup Best Practices](https://www.backblaze.com/blog/the-3-2-1-backup-strategy/)

## 🔄 Version History

- **v1.0.0** - Initial backup system implementation
  - Database backup/restore
  - Volume backup/restore
  - Automated scheduling
  - Volume replication
  - Comprehensive documentation
