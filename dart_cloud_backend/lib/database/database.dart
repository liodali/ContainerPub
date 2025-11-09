import 'package:postgres/postgres.dart';
import 'package:dart_cloud_backend/config/config.dart';

class Database {
  static late Connection _connection;

  static Connection get connection => _connection;

  static Future<void> initialize() async {
    try {
      // Parse database URL
      final uri = Uri.parse(Config.databaseUrl);
      print(uri.toString());
      print(uri.host);
      print(uri.port);
      print(uri.pathSegments);
      print(uri.userInfo);
      final user = uri.userInfo.split(':').first;
      final password = uri.userInfo.contains(':') ? uri.userInfo.split(':')[1] : '';
      if (user.isEmpty || password.isEmpty) {
        throw Exception('Invalid database URL');
      }
      _connection = await Connection.open(
        Endpoint(
          host: uri.host,
          port: uri.port,
          database: uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : 'dart_cloud',
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

    // Function logs table with serial ID (internal) and UUID (public)
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS function_logs (
        id SERIAL PRIMARY KEY,
        uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
        function_id INTEGER NOT NULL REFERENCES functions(id) ON DELETE CASCADE,
        level VARCHAR(20) NOT NULL,
        message TEXT NOT NULL,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create index on function_id for fast function log queries
    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_function_logs_function_id ON function_logs(function_id)
    ''');

    // Create index on timestamp for time-based queries
    await _connection.execute('''
      CREATE INDEX IF NOT EXISTS idx_function_logs_timestamp ON function_logs(timestamp DESC)
    ''');

    // Function invocations table with serial ID (internal) and UUID (public)
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS function_invocations (
        id SERIAL PRIMARY KEY,
        uuid UUID UNIQUE NOT NULL DEFAULT uuid_generate_v4(),
        function_id INTEGER NOT NULL REFERENCES functions(id) ON DELETE CASCADE,
        status VARCHAR(50) NOT NULL,
        duration_ms INTEGER,
        error TEXT,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
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

    print('✓ Database tables created/verified');
    print('✓ Indexes created for performance');
    print('✓ Triggers created for automatic timestamps');
  }

  static Future<void> close() async {
    await _connection.close();
  }
}
