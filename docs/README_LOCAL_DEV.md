# Local Development Quick Start

## 🚀 One-Command Setup

```bash
# Make setup script executable and run it
chmod +x setup-local.sh
./setup-local.sh
```

Or using Make:

```bash
make setup
```

## 📋 What Gets Set Up

1. **PostgreSQL Database** (via Docker)
   - Main database: `dart_cloud`
   - Functions database: `functions_db`
   - Test data pre-populated

2. **Backend Configuration**
   - `.env` file with all settings
   - Function execution limits configured
   - Database connections configured

3. **Directory Structure**
   - Functions storage directory created
   - Example functions ready to deploy

## 🎯 Quick Start (3 Steps)

### Step 1: Start Backend

```bash
cd dart_cloud_backend
dart run bin/server.dart
```

Expected output:
```
✓ Database connected
✓ Database tables created/verified
✓ Function database pool initialized with 5 connections
✓ Server running on http://localhost:8080
```

### Step 2: Register & Login (New Terminal)

```bash
cd dart_cloud_cli

# Register
dart run bin/main.dart register
# Email: test@example.com
# Password: testpass123

# Login
dart run bin/main.dart login
# Email: test@example.com
# Password: testpass123
```

### Step 3: Deploy & Test

```bash
# Deploy example function
dart run bin/main.dart deploy my-func ../examples/simple-function

# Invoke it
dart run bin/main.dart invoke <function-id> --body '{"name": "World"}'

# Expected response:
# {
#   "success": true,
#   "message": "Hello, World!",
#   "timestamp": "2024-11-07T..."
# }
```

## 🛠️ Using Make Commands

```bash
# Setup everything
make setup

# Start PostgreSQL
make start-db

# Start backend
make start-backend

# Run tests
make test

# Check status
make status

# View logs
make logs

# Clean test data
make clean

# Database shell
make db-shell

# See all commands
make help
```

## 🧪 Run Automated Tests

```bash
# Make test script executable
chmod +x test-local.sh

# Run all tests
./test-local.sh
```

Or:

```bash
make test
```

Tests include:
- ✅ User registration
- ✅ User login
- ✅ Function deployment
- ✅ Function invocation
- ✅ Security checks (@function annotation)
- ✅ Dangerous code detection
- ✅ Function deletion

## 📦 Deploy Example Functions

### Simple Function

```bash
cd dart_cloud_cli
dart run bin/main.dart deploy simple ../examples/simple-function
dart run bin/main.dart invoke <id> --body '{"name": "Alice"}'
```

### HTTP Function

```bash
dart run bin/main.dart deploy http ../examples/http-function
dart run bin/main.dart invoke <id> --body '{"url": "https://api.github.com"}'
```

### Database Function

```bash
dart run bin/main.dart deploy db ../examples/database-function

# List items
dart run bin/main.dart invoke <id> --body '{"action": "list"}'

# Create item
dart run bin/main.dart invoke <id> --body '{"action": "create", "name": "New Item"}'
```

## 🔍 Monitoring & Debugging

### Check Backend Status

```bash
curl http://localhost:8080/api/health
```

### View Function Logs

```bash
# Via CLI
dart run bin/main.dart logs <function-id>

# Via database
make logs
```

### Check Database

```bash
# Main database
make db-shell

# Functions database
make db-shell-functions
```

### View Execution Metrics

```sql
-- In database shell
SELECT 
  status, 
  COUNT(*) as count,
  AVG(duration_ms) as avg_duration
FROM function_invocations 
GROUP BY status;
```

## 🔧 Configuration

All settings in `dart_cloud_backend/.env`:

```bash
# Execution Limits
FUNCTION_TIMEOUT_SECONDS=5          # 5 seconds max
FUNCTION_MAX_MEMORY_MB=128          # 128 MB limit
FUNCTION_MAX_CONCURRENT=10          # 10 concurrent executions

# Database Access
FUNCTION_DATABASE_URL=postgres://...
FUNCTION_DB_MAX_CONNECTIONS=5       # 5 connections
FUNCTION_DB_TIMEOUT_MS=5000         # 5 second timeout
```

## 🧹 Cleanup

### Clean Test Data

```bash
make clean
```

### Stop Everything

```bash
# Stop backend: Ctrl+C in backend terminal

# Stop database
make stop-db
```

### Remove Everything

```bash
make clean-all
```

## 🐛 Troubleshooting

### Backend Won't Start

```bash
# Check PostgreSQL is running
docker ps | grep postgres

# Start it if needed
make start-db

# Check .env file exists
ls -la dart_cloud_backend/.env
```

### Database Connection Failed

```bash
# Test connection
docker exec -it containerpub-postgres psql -U dart_cloud -d dart_cloud

# If fails, recreate container
docker stop containerpub-postgres
docker rm containerpub-postgres
make start-db
```

### Function Deployment Fails

```bash
# Check function has @function annotation
grep -r "@function" your_function/

# Check for dangerous code
grep -r "Process.run" your_function/

# View detailed error in backend logs
```

### Port Already in Use

```bash
# Check what's using port 8080
lsof -i :8080

# Kill the process or change PORT in .env
```

## 📚 Documentation

- **LOCAL_DEPLOYMENT.md** - Complete deployment guide
- **SECURITY.md** - Security architecture
- **FUNCTION_TEMPLATE.md** - Function templates
- **DATABASE_ACCESS.md** - Database access guide
- **QUICK_REFERENCE.md** - Quick reference

## 🎯 Next Steps

1. **Explore Examples** - Check `examples/` directory
2. **Read Documentation** - Review security and templates
3. **Create Your Function** - Build your first function
4. **Test Security** - Try deploying dangerous code
5. **Monitor Performance** - Check execution times

## 💡 Tips

- Use `make status` to check system health
- Use `make logs` to view recent logs
- Keep backend terminal open to see real-time logs
- Test security features by trying to deploy dangerous code
- Use database shell to inspect data directly

## 🆘 Need Help?

1. Check backend logs (terminal output)
2. Check database logs: `make logs`
3. Run tests: `make test`
4. Review documentation in project root
5. Check function logs: `dart run bin/main.dart logs <id>`

## ✨ Features to Test

- [x] Function deployment with analysis
- [x] @function annotation enforcement
- [x] Security scanning (Process.run, etc.)
- [x] HTTP request structure (body/query)
- [x] Execution timeout (5 seconds)
- [x] Concurrent execution limits (10 max)
- [x] Database access with timeout
- [x] Connection pooling
- [x] Function logs
- [x] Error handling

Happy coding! 🚀
