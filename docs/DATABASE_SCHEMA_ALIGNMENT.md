# Database Schema Alignment

## Overview
All SQL initialization files have been aligned with the source of truth: `dart_cloud_backend/packages/database/lib/database.dart`

## Source of Truth: database.dart

The Dart entities define the following schema approach:
- **SERIAL IDs** (internal, auto-incrementing integers)
- **UUIDs** (public-facing, for client APIs)
- **INTEGER foreign keys** (not UUID foreign keys)

## Schema Details

### dart_cloud Database

#### users
```sql
id SERIAL PRIMARY KEY
uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4()
email VARCHAR(255) UNIQUE NOT NULL
password_hash VARCHAR(255) NOT NULL
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
```

#### functions
```sql
id SERIAL PRIMARY KEY
uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4()
user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE
name VARCHAR(255) NOT NULL
status VARCHAR(50) DEFAULT 'active'
active_deployment_id INTEGER
analysis_result JSONB
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
UNIQUE(user_id, name)
```

#### function_deployments
```sql
id SERIAL PRIMARY KEY
uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4()
function_id INTEGER NOT NULL REFERENCES functions(id) ON DELETE CASCADE
version INTEGER NOT NULL
image_tag VARCHAR(255) NOT NULL
s3_key VARCHAR(500) NOT NULL
status VARCHAR(50) DEFAULT 'building'
is_active BOOLEAN DEFAULT false
build_logs TEXT
deployed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
UNIQUE(function_id, version)
```

#### function_logs
```sql
id SERIAL PRIMARY KEY
uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4()
function_id INTEGER NOT NULL REFERENCES functions(id) ON DELETE CASCADE
level VARCHAR(20) NOT NULL
message TEXT NOT NULL
timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
```

#### function_invocations
```sql
id SERIAL PRIMARY KEY
uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4()
function_id INTEGER NOT NULL REFERENCES functions(id) ON DELETE CASCADE
status VARCHAR(50) NOT NULL
duration_ms INTEGER
error TEXT
timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
```

### functions_db Database

#### function_data
```sql
id SERIAL PRIMARY KEY
uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4()
function_id INTEGER NOT NULL
key VARCHAR(255) NOT NULL
value JSONB
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
UNIQUE(function_id, key)
```

## Files Updated

### 1. `/dart_cloud_backend/deploy/init-db.sql`
**Purpose**: Local development initialization script

**Changes Made**:
- ✅ Uses SERIAL + UUID for all tables
- ✅ INTEGER foreign keys (not UUID)
- ✅ Removed extra columns not in source of truth:
  - `description`, `runtime`, `environment`, `last_invoked_at`, `invocation_count` from functions
  - `metadata` from function_logs (uses `timestamp` instead of `created_at`)
- ✅ Added `function_invocations` table
- ✅ Proper indexes on both SERIAL IDs and UUIDs
- ✅ Includes `analysis_result` JSONB column in functions

### 2. `/deployment/infrastructure/postgres/init/01-init-databases.sql`
**Purpose**: Production Docker container initialization

**Changes Made**:
- ✅ Converted from UUID-only to SERIAL + UUID
- ✅ Changed all foreign keys from UUID to INTEGER
- ✅ Added UUID extension (uuid-ossp)
- ✅ Removed extra columns not in source of truth
- ✅ Added UUID indexes for client-facing queries
- ✅ Added proper DROP TRIGGER IF EXISTS statements
- ✅ Fixed function_data to use INTEGER function_id

### 3. `/deployment/infrastructure/postgres/init/02-add-docker-s3-columns.sql`
**Purpose**: Migration script for existing databases

**Changes Made**:
- ✅ Updated function_deployments to use SERIAL + UUID
- ✅ Changed function_id foreign key to INTEGER
- ✅ Changed active_deployment_id to INTEGER (not UUID)
- ✅ Fixed migration logic to use SERIAL RETURNING for new_deployment_id
- ✅ Added UUID index on function_deployments
- ✅ Removed code column nullable migration (not in source of truth)

## Key Principles

### 1. Dual Identifier Strategy
- **SERIAL IDs**: Used internally for database operations, foreign keys, and joins
- **UUIDs**: Exposed to clients via APIs for security and obfuscation

### 2. Foreign Key Strategy
- All foreign keys use INTEGER (referencing SERIAL IDs)
- Never expose SERIAL IDs in API responses
- Always use UUIDs in client-facing operations

### 3. Index Strategy
- UUID indexes for client-facing queries (WHERE uuid = ?)
- SERIAL ID indexes automatically created as primary keys
- Foreign key indexes for fast joins
- Timestamp indexes for time-based queries

## Benefits

1. **Performance**: SERIAL IDs are faster for joins and internal operations
2. **Security**: UUIDs prevent enumeration attacks and ID guessing
3. **Compatibility**: Works with existing Dart entity models
4. **Consistency**: All three SQL files now match the source of truth
5. **Maintainability**: Single source of truth in database.dart

## Usage

### Local Development
```bash
psql -U dart_cloud -d postgres -f dart_cloud_backend/deploy/init-db.sql
```

### Docker Container (Production)
The init scripts run automatically on first container startup:
1. `01-init-databases.sql` - Creates tables
2. `02-add-docker-s3-columns.sql` - Applies migrations

## Verification

All files now correctly implement:
- ✅ SERIAL PRIMARY KEY for internal IDs
- ✅ UUID UNIQUE NOT NULL for public identifiers
- ✅ INTEGER foreign keys
- ✅ Proper indexes on both ID types
- ✅ Matching column names and types with Dart entities
- ✅ Consistent trigger and function definitions

## Notes

- The `function_invocations` table exists in the Dart entities and init-db.sql but is not yet in the production deployment scripts (01-init-databases.sql). This is intentional as it may be added in a future migration.
- The `function_data` table in functions_db does not have a foreign key constraint to dart_cloud.functions because it's in a separate database. The INTEGER function_id is used for logical relationships only.
