# ContainerPub Documentation

Complete documentation for ContainerPub - A serverless function platform with Dart.

## 📚 Documentation Index

### Getting Started

- **[Local Development Quick Start](README_LOCAL_DEV.md)** - Get started in 3 steps
- **[Local Deployment Guide](LOCAL_DEPLOYMENT.md)** - Complete setup instructions
- **[Local Architecture](LOCAL_ARCHITECTURE.md)** - System architecture and diagrams

### Security & Templates

- **[Security Guide](SECURITY.md)** - Security architecture and best practices
- **[Function Templates](FUNCTION_TEMPLATE.md)** - Function templates and examples
- **[Quick Reference](QUICK_REFERENCE.md)** - Quick reference guide

### Advanced Topics

- **[Database Access](DATABASE_ACCESS.md)** - Secure database access with timeouts
- **[Migration Guide](MIGRATION_GUIDE.md)** - Migrating existing functions
- **[Execution Protection](EXECUTION_PROTECTION_SUMMARY.md)** - Implementation details
- **[Architecture](ARCHITECTURE.md)** - Complete system architecture

### Implementation

- **[Implementation Complete](IMPLEMENTATION_COMPLETE.md)** - Feature implementation summary
- **[Local Setup Complete](LOCAL_SETUP_COMPLETE.md)** - Setup verification

## 🚀 Quick Links

### For Developers

1. **First Time Setup**
   - [Local Development Quick Start](README_LOCAL_DEV.md)
   - [Function Templates](FUNCTION_TEMPLATE.md)

2. **Writing Functions**
   - [Quick Reference](QUICK_REFERENCE.md)
   - [Security Guide](SECURITY.md)
   - [Database Access](DATABASE_ACCESS.md)

3. **Deployment**
   - [Local Deployment Guide](LOCAL_DEPLOYMENT.md)
   - [Migration Guide](MIGRATION_GUIDE.md)

### For DevOps

1. **Infrastructure**
   - [Architecture](ARCHITECTURE.md)
   - [Local Architecture](LOCAL_ARCHITECTURE.md)

2. **Security**
   - [Security Guide](SECURITY.md)
   - [Execution Protection](EXECUTION_PROTECTION_SUMMARY.md)

3. **Monitoring**
   - [Local Deployment Guide](LOCAL_DEPLOYMENT.md#monitoring)
   - [Quick Reference](QUICK_REFERENCE.md#monitoring)

## 📖 Documentation by Topic

### Security

- [Security Architecture](SECURITY.md#security-architecture)
- [Static Code Analysis](SECURITY.md#static-code-analysis)
- [Execution Limits](EXECUTION_PROTECTION_SUMMARY.md#protection-mechanisms)
- [Database Protection](DATABASE_ACCESS.md#security-model)

### Function Development

- [Function Structure](FUNCTION_TEMPLATE.md#basic-structure)
- [HTTP Requests](FUNCTION_TEMPLATE.md#http-request-function)
- [Database Access](DATABASE_ACCESS.md#implementation-examples)
- [Error Handling](QUICK_REFERENCE.md#error-handling)

### Deployment

- [Local Setup](LOCAL_DEPLOYMENT.md#quick-start)
- [Testing](LOCAL_DEPLOYMENT.md#testing-the-system)
- [Troubleshooting](LOCAL_DEPLOYMENT.md#troubleshooting)

### Configuration

- [Environment Variables](QUICK_REFERENCE.md#environment-variables)
- [Execution Limits](EXECUTION_PROTECTION_SUMMARY.md#configuration-tuning)
- [Database Configuration](DATABASE_ACCESS.md#configuration)

## 🎯 Common Tasks

### Deploy a Function

```bash
# See: Local Deployment Guide
cd dart_cloud_cli
dart run bin/main.dart deploy my-func ../examples/simple-function
```

### Test Security Features

```bash
# See: Security Guide
# Try deploying function without @function annotation
# Expected: Deployment rejected
```

### Access Database from Function

```dart
// See: Database Access Guide
final pool = FunctionDatabasePool.instance;
final result = await pool.executeQuery('SELECT * FROM items');
```

### Monitor Execution

```sql
-- See: Quick Reference
SELECT AVG(duration_ms) FROM function_invocations;
```

## 🔍 Search Documentation

- **@function annotation** → [Security Guide](SECURITY.md), [Function Templates](FUNCTION_TEMPLATE.md)
- **Timeout** → [Execution Protection](EXECUTION_PROTECTION_SUMMARY.md), [Database Access](DATABASE_ACCESS.md)
- **Database** → [Database Access](DATABASE_ACCESS.md), [Quick Reference](QUICK_REFERENCE.md)
- **Security** → [Security Guide](SECURITY.md), [Execution Protection](EXECUTION_PROTECTION_SUMMARY.md)
- **Deployment** → [Local Deployment](LOCAL_DEPLOYMENT.md), [Migration Guide](MIGRATION_GUIDE.md)
- **Examples** → [Function Templates](FUNCTION_TEMPLATE.md), [Quick Reference](QUICK_REFERENCE.md)

## 📝 Document Summaries

### README_LOCAL_DEV.md
Quick start guide for local development. Covers setup, deployment, and testing in 3 steps.

### LOCAL_DEPLOYMENT.md
Complete deployment guide with database setup, backend configuration, CLI usage, and troubleshooting.

### LOCAL_ARCHITECTURE.md
System architecture diagrams, request flows, security layers, and file structure.

### SECURITY.md
Security architecture, static analysis, allowed/blocked operations, and best practices.

### FUNCTION_TEMPLATE.md
Function templates, examples, security restrictions, and common patterns.

### DATABASE_ACCESS.md
Database access with connection pooling, timeouts, security model, and examples.

### MIGRATION_GUIDE.md
Step-by-step migration instructions, common scenarios, and troubleshooting.

### QUICK_REFERENCE.md
Quick reference for configuration, templates, common patterns, and troubleshooting.

### EXECUTION_PROTECTION_SUMMARY.md
Implementation details for execution protection, resource limits, and monitoring.

### ARCHITECTURE.md
Complete system architecture, data flow, security model, and scalability.

### IMPLEMENTATION_COMPLETE.md
Summary of implemented features, files created, and getting started guide.

### LOCAL_SETUP_COMPLETE.md
Verification guide for local setup with testing procedures and success indicators.

## 🆘 Getting Help

1. **Check Quick Reference** - [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
2. **Review Examples** - [FUNCTION_TEMPLATE.md](FUNCTION_TEMPLATE.md)
3. **Troubleshooting** - [LOCAL_DEPLOYMENT.md](LOCAL_DEPLOYMENT.md#troubleshooting)
4. **Security Issues** - [SECURITY.md](SECURITY.md)

## 🔗 External Resources

- [Dart Documentation](https://dart.dev/guides)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Shelf Framework](https://pub.dev/packages/shelf)

## 📋 Checklist for New Users

- [ ] Read [Local Development Quick Start](README_LOCAL_DEV.md)
- [ ] Run setup: `./setup-local.sh`
- [ ] Review [Function Templates](FUNCTION_TEMPLATE.md)
- [ ] Deploy example function
- [ ] Read [Security Guide](SECURITY.md)
- [ ] Test security features
- [ ] Review [Quick Reference](QUICK_REFERENCE.md)

## ✨ Key Features Documented

- ✅ Function deployment with static analysis
- ✅ @function annotation enforcement
- ✅ Security scanning (Process.run, shell, etc.)
- ✅ HTTP request structure (body/query)
- ✅ 5-second execution timeout (configurable)
- ✅ Concurrent execution limits (10 max)
- ✅ Database access with connection pooling
- ✅ Query timeout protection (5 seconds)
- ✅ Comprehensive logging
- ✅ Error handling

All documentation is comprehensive, tested, and ready to use!
