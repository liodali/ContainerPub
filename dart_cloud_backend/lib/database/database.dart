import 'package:postgres/postgres.dart';
import 'package:dart_cloud_backend/config/config.dart';

class Database {
  static late Connection _connection;

  static Connection get connection => _connection;

  static Future<void> initialize() async {
    try {
      // Parse database URL
      final uri = Uri.parse(Config.databaseUrl);

      _connection = await Connection.open(
        Endpoint(
          host: uri.host,
          port: uri.port,
          database: uri.pathSegments.isNotEmpty
              ? uri.pathSegments[0]
              : 'dart_cloud',
          username: uri.userInfo.split(':').first,
          password: uri.userInfo.contains(':')
              ? uri.userInfo.split(':')[1]
              : '',
        ),
        settings: const ConnectionSettings(sslMode: SslMode.disable),
      );

      print('✓ Database connected');

      // Create tables
      await _createTables();
    } catch (e) {
      print('⚠️  Database connection failed: $e');
      print('   Continuing without database (in-memory mode)');
      // In production, you might want to fail here
    }
  }

  static Future<void> _createTables() async {
    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS functions (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        name VARCHAR(255) NOT NULL,
        status VARCHAR(50) DEFAULT 'active',
        analysis_result JSONB,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS function_logs (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        function_id UUID REFERENCES functions(id) ON DELETE CASCADE,
        level VARCHAR(20) NOT NULL,
        message TEXT NOT NULL,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await _connection.execute('''
      CREATE TABLE IF NOT EXISTS function_invocations (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        function_id UUID REFERENCES functions(id) ON DELETE CASCADE,
        status VARCHAR(50) NOT NULL,
        duration_ms INTEGER,
        error TEXT,
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    print('✓ Database tables created/verified');
  }

  static Future<void> close() async {
    await _connection.close();
  }
}
