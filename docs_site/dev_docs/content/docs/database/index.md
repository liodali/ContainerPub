---
title: Database & Backup Documentation
description: Database system, backup strategies, and disaster recovery
---

# Database & Backup Documentation

Complete documentation for the ContainerPub database system, backup strategies, and disaster recovery procedures.

## Overview

The ContainerPub database infrastructure provides:

- **Entity-Based Database** - Type-safe PostgreSQL database management
- **Query Builder** - Fluent API for complex SQL queries
- **Backup System** - Automated database and volume backups
- **Disaster Recovery** - Complete system restore procedures
- **Replication** - Real-time and scheduled data replication

## Quick Links

### Database System

- [Database System](./database-system.md) - Complete database architecture and API
- [Database Quick Reference](./database-quick-reference.md) - Quick reference guide
- [Implementation History](./database-implementation-tracking.md) - Development timeline

### Backup & Recovery

- [Backup Strategy](./backup-strategy.md) - Comprehensive backup and disaster recovery
- [Backup Workflows](./backup-workflows.md) - Step-by-step backup procedures
- [Backup Quick Reference](./backup-quick-reference.md) - Quick command reference

## Database System

### Key Features

**Entity-Based Models:**

- Type-safe entity definitions
- Automatic table creation
- Field annotations and constraints
- Relationship support

**Query Builder:**

- Fluent API for SQL queries
- Parameterized queries for security
- Complex joins and conditions
- Aggregation and analytics

**Relationship Management:**

- `hasMany` - One-to-many relationships
- `belongsTo` - Many-to-one relationships
- `manyToMany` - Many-to-many relationships
- Eager loading support

**CRUD Operations:**

- Create, read, update, delete
- Batch operations
- Transaction support
- Soft deletes

### Architecture

```dart
database/
├── lib/
│   ├── database.dart              # Main Database class
│   └── src/
│       ├── entity.dart            # Base entity & annotations
│       ├── query_builder.dart     # SQL query builder
│       ├── database_manager_query.dart  # CRUD manager
│       ├── relationship_manager.dart    # Relationships
│       └── entities/              # Database entities
│           ├── user_entity.dart
│           ├── function_entity.dart
│           ├── organization.dart
│           └── ...
```

### Core Entities

**User Management:**

- `UserEntity` - User accounts and authentication
- `UserInformation` - Extended user profiles
- `Organization` - Organization/team management
- `OrganizationMember` - Organization membership

**Function Management:**

- `FunctionEntity` - Function metadata
- `FunctionDeploymentEntity` - Deployment history
- `FunctionLogEntity` - Execution logs
- `FunctionInvocationEntity` - Invocation records

### Usage Example

```dart
// Initialize database
final db = Database(
  host: 'localhost',
  port: 5432,
  databaseName: 'containerpub',
  username: 'postgres',
  password: 'password',
);

// Create entity
final user = UserEntity()
  ..email = 'user@example.com'
  ..passwordHash = hashedPassword;

await db.users.create(user);

// Query with builder
final users = await db.users
  .where('email', '=', 'user@example.com')
  .get();

// Relationships
final userFunctions = await db.users
  .hasMany<FunctionEntity>(user.id!, 'owner_id')
  .get();
```

## Backup System

### Backup Types

**Database Backups:**

- PostgreSQL dumps with `pg_dump`
- Compressed archives (gzip)
- Schema and data preservation
- Point-in-time recovery

**Volume Backups:**

- Docker volume snapshots
- Function data archives
- Configuration backups
- Complete state preservation

**Combined Backups:**

- Database + volumes in single archive
- Timestamped backups
- Automated scheduling
- Retention policies

### Backup Architecture

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

### Backup Scripts

**Core Scripts:**

- `backup_database.sh` - Database backup only
- `backup_volumes.sh` - Volume backup only
- `backup_all.sh` - Combined backup
- `restore_database.sh` - Database restore
- `restore_volumes.sh` - Volume restore
- `restore_all.sh` - Complete restore

**Replication:**

- `replicate_backups.sh` - Backup replication
- `setup_replication.sh` - Configure replication
- Supports rsync, S3, and custom destinations

### Automation

**Cron Scheduling:**

```dart
# Daily database backup at 2 AM
0 2 * * * /path/to/backup_database.sh

# Weekly full backup on Sunday at 3 AM
0 3 * * 0 /path/to/backup_all.sh

# Hourly replication
0 * * * * /path/to/replicate_backups.sh
```

## Disaster Recovery

### Recovery Procedures

**Database Recovery:**

1. Stop backend services
2. Restore database from backup
3. Verify data integrity
4. Restart services

**Volume Recovery:**

1. Stop containers
2. Restore volume data
3. Verify file permissions
4. Restart containers

**Complete System Recovery:**

1. Restore database
2. Restore volumes
3. Verify configurations
4. Test functionality
5. Resume operations

### Recovery Time Objectives

- **Database**: 5-15 minutes
- **Volumes**: 10-30 minutes
- **Complete System**: 20-45 minutes
- **Verification**: 10-20 minutes

## Best Practices

### Database Management

1. **Use Transactions** - For multi-step operations
2. **Parameterized Queries** - Prevent SQL injection
3. **Index Optimization** - For frequently queried fields
4. **Connection Pooling** - Efficient resource usage
5. **Regular Maintenance** - VACUUM and ANALYZE

### Backup Management

1. **Regular Backups** - Daily database, weekly full
2. **Test Restores** - Verify backup integrity monthly
3. **Off-site Storage** - Replicate to remote location
4. **Retention Policy** - Keep 30 daily, 12 weekly, 12 monthly
5. **Monitoring** - Alert on backup failures
6. **Documentation** - Keep recovery procedures updated

### Security

1. **Encrypted Backups** - Use encryption for sensitive data
2. **Access Control** - Restrict backup access
3. **Secure Transfer** - Use SSH/TLS for replication
4. **Audit Logging** - Track backup operations
5. **Key Management** - Secure encryption keys

## Monitoring

### Database Metrics

- Connection count
- Query performance
- Table sizes
- Index usage
- Lock contention
- Replication lag

### Backup Metrics

- Backup success/failure rate
- Backup size and duration
- Storage usage
- Replication status
- Recovery time testing

## Troubleshooting

### Common Database Issues

**Connection Errors:**

- Check PostgreSQL service status
- Verify connection parameters
- Check firewall rules
- Review connection limits

**Performance Issues:**

- Analyze slow queries
- Check index usage
- Review table statistics
- Optimize query patterns

### Common Backup Issues

**Backup Failures:**

- Check disk space
- Verify permissions
- Review error logs
- Test backup scripts

**Restore Issues:**

- Verify backup integrity
- Check PostgreSQL version compatibility
- Review restore logs
- Ensure sufficient disk space

## Documentation Structure

### Database Documentation

1. **[Database System](./database-system.md)** - Complete system architecture

   - Entity definitions
   - Query builder API
   - Relationship management
   - CRUD operations
   - Examples and best practices

2. **[Database Quick Reference](./database-quick-reference.md)** - Quick command reference

   - Common queries
   - Entity operations
   - Relationship queries
   - Troubleshooting

3. **[Implementation History](./database-implementation-tracking.md)** - Development timeline
   - Feature additions
   - Bug fixes
   - Performance improvements
   - Migration notes

### Backup Documentation

1. **[Backup Strategy](./backup-strategy.md)** - Comprehensive guide

   - System architecture
   - Backup types
   - Replication setup
   - Disaster recovery
   - Best practices

2. **[Backup Workflows](./backup-workflows.md)** - Step-by-step procedures

   - Backup procedures
   - Restore procedures
   - Testing procedures
   - Automation setup

3. **[Backup Quick Reference](./backup-quick-reference.md)** - Quick commands
   - Backup commands
   - Restore commands
   - Replication commands
   - Troubleshooting

## Next Steps

- Read [Database System](./database-system.md) for complete database documentation
- Check [Backup Strategy](./backup-strategy.md) for backup and recovery procedures
- Review [Backend Architecture](../backend/architecture.md) for system integration
- Explore [CLI Documentation](../cli/index.md) for client tools

## Support

For issues, questions, or contributions:

- GitHub: [liodali/ContainerPub](https://github.com/liodali/ContainerPub)
- Documentation: [ContainerPub Docs](/)
