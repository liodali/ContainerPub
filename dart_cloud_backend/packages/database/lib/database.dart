/// Database package with entity-based query management and raw SQL support
///
/// This package provides:
/// - Entity-based database management with DatabaseManagerQuery
/// - Query builder for constructing SQL queries
/// - Entity models for all database tables
/// - Raw SQL query methods for complex operations
/// - Legacy QueryHelpers for backward compatibility
library;

import 'package:postgres/postgres.dart';

// Legacy query helpers (for backward compatibility)
export 'src/query_helpers.dart';

// Entity system
export 'src/entity.dart';
export 'src/query_builder.dart';
export 'src/database_manager_query.dart';
export 'src/managers.dart';

// Entity models
export 'src/entities/user_entity.dart';
export 'src/entities/function_entity.dart';
export 'src/entities/function_deployment_entity.dart';
export 'src/entities/function_log_entity.dart';
export 'src/entities/function_invocation_entity.dart';
export 'src/entities/user_information.dart';
export 'src/entities/organization.dart';
export 'src/entities/organization_member.dart';
export 'src/entities/logs_entity.dart';
export 'src/entities/api_key_entity.dart';

// Relationship managers
export 'src/relationship_manager.dart';
export 'src/managers/user_relationships.dart';
export 'src/managers/organization_relationships.dart';

// Utilities
export 'src/utils/secure_data_encoder.dart';

// Models
export 'src/models/invocation_logs.dart';

// DTOs (Data Transfer Objects)
export 'src/dto/user_dto.dart';
export 'src/dto/organization_dto.dart';

class Database {
  static late Connection _connection;

  static Connection get connection => _connection;

  static Future<void> initialize(String databaseUrl) async {
    try {
      // Parse database URL
      final uri = Uri.parse(databaseUrl);
      final user = uri.userInfo.split(':').first;
      final password = uri.userInfo.contains(':')
          ? uri.userInfo.split(':')[1]
          : '';
      if (user.isEmpty || password.isEmpty) {
        throw Exception('Invalid database URL');
      }
      _connection = await Connection.open(
        Endpoint(
          host: uri.host,
          port: uri.port,
          database: uri.pathSegments.isNotEmpty
              ? uri.pathSegments[0]
              : 'dart_cloud',
          username: user,
          password: password,
        ),
        settings: const ConnectionSettings(sslMode: SslMode.disable),
      );

      print('✓ Database connected');

      // Create tables
      await _createTables();
    } catch (e, trace) {
      print('⚠️  Database connection failed: $e');
      print('Trace: $trace');
      print('   Continuing without database (in-memory mode)');
      // In production, you might want to fail here
    }
  }

  static Future<void> _createTables() async {
    // Enable UUID extension
    await _connection.execute('''
      CREATE EXTENSION IF NOT EXISTS "uuid-ossp"
    ''');

    // Users table with serial ID (internal) and UUID (public)
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create index on UUID for fast lookups
    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_users_uuid ON users(uuid)
    ''');

    // Functions table with serial ID (internal) and UUID (public)
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS functions (
        id SERIAL PRIMARY KEY,
        uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        name VARCHAR(255) NOT NULL,
        status VARCHAR(50) DEFAULT 'active',
        active_deployment_id INTEGER,
        analysis_result JSONB,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, name)
      )
    ''');

    // Create index on UUID for fast lookups
    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_functions_uuid ON functions(uuid)
    ''');

    // Create index on user_id for fast user queries
    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_functions_user_id ON functions(user_id)
    ''');

    // Migration: Add active_deployment_id column if it doesn't exist
    await _connection.execute('''
      DO \$\$ 
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name='functions' AND column_name='active_deployment_id') THEN
          ALTER TABLE functions ADD COLUMN active_deployment_id INTEGER;
        END IF;
      END \$\$
    ''');

    // Create index on active_deployment_id for fast lookups
    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_functions_active_deployment ON functions(active_deployment_id)
    ''');

    // Function deployments table for versioning and deployment history
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS function_deployments (
        id SERIAL PRIMARY KEY,
        uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
        function_id INTEGER NOT NULL REFERENCES functions(id) ON DELETE CASCADE,
        version INTEGER NOT NULL,
        image_tag VARCHAR(255) NOT NULL,
        s3_key VARCHAR(500) NOT NULL,
        status VARCHAR(50) DEFAULT 'building',
        is_active BOOLEAN DEFAULT false,
        build_logs TEXT,
        deployed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(function_id, version)
      )
    ''');

    // Create indexes for function_deployments
    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_function_deployments_uuid ON function_deployments(uuid)
    ''');

    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_function_deployments_function_id ON function_deployments(function_id)
    ''');

    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_function_deployments_is_active ON function_deployments(function_id, is_active)
    ''');

    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_function_deployments_version ON function_deployments(function_id, version DESC)
    ''');

    // Function logs table with serial ID (internal) and UUID (public)
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS function_logs (
        id SERIAL PRIMARY KEY,
        uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
        function_uuid UUID NOT NULL REFERENCES functions(uuid) ON DELETE CASCADE,
        level VARCHAR(20) NOT NULL,
        message TEXT NOT NULL,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create index on function_id for fast function log queries
    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_function_logs_function_id ON function_logs(function_uuid)
    ''');

    // Create index on timestamp for time-based queries
    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_function_logs_timestamp ON function_logs(timestamp DESC)
    ''');

    // Function invocations table with serial ID (internal) and UUID (public)
    // Stores request metadata and execution logs
    // Body is NOT stored for security - only request info (headers, query, method, path)
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS function_invocations (
        id SERIAL PRIMARY KEY,
        uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
        function_id INTEGER NOT NULL REFERENCES functions(id) ON DELETE CASCADE,
        status VARCHAR(50) NOT NULL,
        duration_ms INTEGER,
        error TEXT,
        logs JSONB,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        request_info JSONB,
        result TEXT,
        success BOOLEAN
      )
    ''');

    // Create index on function_id for fast function invocation queries
    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_function_invocations_function_id ON function_invocations(function_id)
    ''');

    // Create index on timestamp for time-based queries
    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_function_invocations_timestamp ON function_invocations(timestamp DESC)
    ''');

    // Migration: Add logs column to function_invocations if not exists
    await _connection.execute('''
      ALTER TABLE function_invocations 
      ADD COLUMN IF NOT EXISTS logs JSONB
    ''');

    // Migration: Add request info and result fields to function_invocations
    await _connection.execute('''
      ALTER TABLE function_invocations 
      ADD COLUMN IF NOT EXISTS request_info JSONB,
      ADD COLUMN IF NOT EXISTS result TEXT,
      ADD COLUMN IF NOT EXISTS success BOOLEAN
    ''');

    // Create triggers for updated_at
    await _connection.execute('''
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS \$\$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      \$\$ language 'plpgsql'
    ''');

    await _connection.execute('''
      DROP TRIGGER IF EXISTS update_users_updated_at ON users
    ''');

    await _connection.execute('''
      CREATE TRIGGER update_users_updated_at
        BEFORE UPDATE ON users
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column()
    ''');

    await _connection.execute('''
      DROP TRIGGER IF EXISTS update_functions_updated_at ON functions
    ''');

    await _connection.execute('''
      CREATE TRIGGER update_functions_updated_at
        BEFORE UPDATE ON functions
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column()
    ''');

    // User information table
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS user_information (
        id SERIAL PRIMARY KEY,
        uuid UUID DEFAULT gen_random_uuid() UNIQUE NOT NULL,
        user_id UUID NOT NULL REFERENCES users(uuid) ON DELETE CASCADE,
        first_name VARCHAR(100) NOT NULL,
        last_name VARCHAR(100) NOT NULL,
        phone_number VARCHAR(20),
        country VARCHAR(100),
        city VARCHAR(100),
        address TEXT,
        zip_code VARCHAR(20),
        avatar TEXT,
        role VARCHAR(50) NOT NULL CHECK (role IN ('developer', 'team', 'sub_team_developer')),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id)
      )
    ''');

    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_user_information_user_id ON user_information(user_id)
    ''');

    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_user_information_role ON user_information(role)
    ''');

    // Organizations table - one organization can have multiple users
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS organizations (
        id SERIAL PRIMARY KEY,
        uuid UUID DEFAULT gen_random_uuid() UNIQUE NOT NULL,
        name VARCHAR(255) UNIQUE NOT NULL,
        owner_id UUID NOT NULL REFERENCES users(uuid) ON DELETE CASCADE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_organizations_owner_id ON organizations(owner_id)
    ''');

    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_organizations_name ON organizations(name)
    ''');

    // Organization members table - junction table for users belonging to organizations
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS organization_members (
        id SERIAL PRIMARY KEY,
        organization_id UUID NOT NULL REFERENCES organizations(uuid) ON DELETE CASCADE,
        user_id UUID NOT NULL REFERENCES users(uuid) ON DELETE CASCADE,
        joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id)
      )
    ''');

    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_org_members_org_id ON organization_members(organization_id)
    ''');

    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_org_members_user_id ON organization_members(user_id)
    ''');

    // Triggers for new tables
    await _connection.execute('''
      DROP TRIGGER IF EXISTS update_user_information_updated_at ON user_information
    ''');

    await _connection.execute('''
      CREATE TRIGGER update_user_information_updated_at
        BEFORE UPDATE ON user_information
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column()
    ''');

    await _connection.execute('''
      DROP TRIGGER IF EXISTS update_organizations_updated_at ON organizations
    ''');

    await _connection.execute('''
      CREATE TRIGGER update_organizations_updated_at
        BEFORE UPDATE ON organizations
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column()
    ''');

    // Logs table
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS logs (
        id SERIAL PRIMARY KEY,
        uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
        level VARCHAR(20) NOT NULL,
        message TEXT NOT NULL,
        action VARCHAR(50) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create indexes for logs table
    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_logs_uuid ON logs(uuid)
    ''');

    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_logs_action ON logs(action)
    ''');

    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_logs_level ON logs(level)
    ''');

    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_logs_created_at ON logs(created_at DESC)
    ''');

    // API Keys table for function signing
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS api_keys (
        id SERIAL PRIMARY KEY,
        uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
        function_uuid UUID NOT NULL REFERENCES functions(uuid) ON DELETE CASCADE,
        public_key TEXT NOT NULL,
        private_key_hash VARCHAR(255),
        validity VARCHAR(20) NOT NULL CHECK (validity IN ('1h', '1d', '1w', '1m', 'forever')),
        expires_at TIMESTAMP WITH TIME ZONE,
        is_active BOOLEAN DEFAULT true,
        name VARCHAR(255),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        revoked_at TIMESTAMP WITH TIME ZONE
      )
    ''');

    // Create indexes for api_keys table
    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_api_keys_uuid ON api_keys(uuid)
    ''');

    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_api_keys_function_uuid ON api_keys(function_uuid)
    ''');

    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_api_keys_is_active ON api_keys(is_active)
    ''');

    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_api_keys_expires_at ON api_keys(expires_at)
    ''');

    print('✓ Database tables created/verified');
    print('✓ Indexes created for performance');
    print('✓ Triggers created for automatic timestamps');
    print('✓ User relationship tables created');
  }

  static Future<void> close() async {
    await _connection.close();
  }

  // ============================================================================
  // Raw Query Methods
  // ============================================================================

  /// Execute a raw SQL query and return the result
  static Future<Result> rawQuery(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    return await _connection.execute(
      Sql.named(sql),
      parameters: parameters ?? {},
    );
  }

  /// Execute a raw SQL query and return a single row as a map
  static Future<Map<String, dynamic>?> rawQuerySingle(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    final result = await rawQuery(sql, parameters: parameters);
    if (result.isEmpty) return null;

    final row = result.first;
    final map = <String, dynamic>{};
    for (var i = 0; i < row.length; i++) {
      final columnName = row.schema.columns[i].columnName ?? 'column_$i';
      map[columnName] = row[i];
    }
    return map;
  }

  /// Execute a raw SQL query and return all rows as maps
  static Future<List<Map<String, dynamic>>> rawQueryAll(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    final result = await rawQuery(sql, parameters: parameters);

    return result.map((row) {
      final map = <String, dynamic>{};
      for (var i = 0; i < row.length; i++) {
        final columnName = row.schema.columns[i].columnName ?? 'column_$i';
        map[columnName] = row[i];
      }
      return map;
    }).toList();
  }

  /// Execute a raw SQL statement (INSERT, UPDATE, DELETE) and return affected rows
  static Future<int> rawExecute(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    final result = await rawQuery(sql, parameters: parameters);
    return result.affectedRows;
  }

  /// Begin a transaction
  static Future<T> transaction<T>(
    Future<T> Function(Connection connection) callback,
  ) async {
    return _connection.runTx((ctx) async {
      return callback(ctx as Connection);
    });
  }

  /// Execute multiple queries in a transaction
  static Future<void> batchExecute(List<String> queries) async {
    await transaction((ctx) async {
      for (final query in queries) {
        await ctx.execute(query);
      }
    });
  }
}
