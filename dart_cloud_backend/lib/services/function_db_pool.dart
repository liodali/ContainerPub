import 'dart:async';
import 'package:postgres/postgres.dart';
import 'package:dart_cloud_backend/config/config.dart';

/// Database connection pool for function execution
/// Provides controlled, time-limited database access for functions
class FunctionDatabasePool {
  static FunctionDatabasePool? _instance;
  final List<Connection> _availableConnections = [];
  final Set<Connection> _inUseConnections = {};
  bool _initialized = false;

  FunctionDatabasePool._();

  static FunctionDatabasePool get instance {
    _instance ??= FunctionDatabasePool._();
    return _instance!;
  }

  /// Initialize the connection pool
  Future<void> initialize() async {
    if (_initialized || Config.functionDatabaseUrl == null) {
      return;
    }

    try {
      final uri = Uri.parse(Config.functionDatabaseUrl!);

      // Create initial connections
      for (var i = 0; i < Config.functionDatabaseMaxConnections; i++) {
        final connection = await Connection.open(
          Endpoint(
            host: uri.host,
            port: uri.port,
            database: uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : 'functions_db',
            username: uri.userInfo.split(':').first,
            password: uri.userInfo.contains(':') ? uri.userInfo.split(':')[1] : '',
          ),
          settings: ConnectionSettings(
            sslMode: SslMode.disable,
            connectTimeout: Duration(
              milliseconds: Config.functionDatabaseConnectionTimeoutMs,
            ),
          ),
        );

        _availableConnections.add(connection);
      }

      _initialized = true;
      print(
        '✓ Function database pool initialized with ${_availableConnections.length} connections',
      );
    } catch (e) {
      print('⚠️  Failed to initialize function database pool: $e');
    }
  }

  /// Get a connection from the pool with timeout
  Future<Connection?> getConnection({
    Duration? timeout,
  }) async {
    if (!_initialized) {
      return null;
    }

    final timeoutDuration =
        timeout ?? Duration(milliseconds: Config.functionDatabaseConnectionTimeoutMs);

    try {
      return await _getConnectionInternal().timeout(timeoutDuration);
    } on TimeoutException {
      return null;
    }
  }

  Future<Connection> _getConnectionInternal() async {
    // Wait for available connection
    while (_availableConnections.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final connection = _availableConnections.removeAt(0);
    _inUseConnections.add(connection);
    return connection;
  }

  /// Release a connection back to the pool
  void releaseConnection(Connection connection) {
    if (_inUseConnections.remove(connection)) {
      _availableConnections.add(connection);
    }
  }

  /// Execute a query with automatic connection management and timeout
  Future<Result?> executeQuery(
    String query, {
    Map<String, dynamic>? parameters,
    Duration? timeout,
  }) async {
    final connection = await getConnection(timeout: timeout);
    if (connection == null) {
      return null;
    }

    try {
      final timeoutDuration =
          timeout ?? Duration(milliseconds: Config.functionDatabaseConnectionTimeoutMs);

      final result = await connection
          .execute(
            query,
            parameters: parameters?.values.toList(),
          )
          .timeout(timeoutDuration);

      return result;
    } catch (e) {
      rethrow;
    } finally {
      releaseConnection(connection);
    }
  }

  /// Get pool statistics
  Map<String, dynamic> getStats() {
    return {
      'initialized': _initialized,
      'totalConnections': _availableConnections.length + _inUseConnections.length,
      'availableConnections': _availableConnections.length,
      'inUseConnections': _inUseConnections.length,
      'maxConnections': Config.functionDatabaseMaxConnections,
    };
  }

  /// Close all connections
  Future<void> close() async {
    for (final connection in _availableConnections) {
      await connection.close();
    }
    for (final connection in _inUseConnections) {
      await connection.close();
    }
    _availableConnections.clear();
    _inUseConnections.clear();
    _initialized = false;
  }
}
