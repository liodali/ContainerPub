import 'dart:convert';
import 'package:podman_socket_dart_client/src/models/compat_container_config.dart';

import '../podman_socket_client.dart';
import '../podman_dart_client_base.dart';

/// Container operations API (compat and libpod endpoints)
class ContainerOperations {
  final PodmanSocketClient _client;

  ContainerOperations(this._client);

  /// Run a container
  /// Example: runContainer('alpine:latest', cmd: ['echo', 'hello'])
  Future<String> runContainer(
    CompatContainerConfig containerSpec, {
    bool start = true,
  }) async {
    final createBody = jsonEncode(containerSpec.toJson());
    print(createBody);
    final createResponse = await _client.post(
      'containers/create',
      body: createBody,
    );

    if (createResponse.statusCode != 201) {
      throw Exception('Failed to create container: ${createResponse.body}');
    }
    print(createResponse.body);
    final containerId = jsonDecode(createResponse.body)['Id'];

    if (start) {
      final startResponse = await _client.post(
        'containers/$containerId/start',
      );

      if (startResponse.statusCode != 204 && startResponse.statusCode != 304) {
        throw Exception('Failed to start container: ${startResponse.body}');
      }
    }
    return containerId;
  }

  /// Start a container
  /// Example: startContainer('containerId')
  Future<String> startContainer(
    String containerId,
  ) async {
    final startResponse = await _client.post(
      'containers/$containerId/start',
    );

    if (startResponse.statusCode != 204 && startResponse.statusCode != 304) {
      throw Exception('Failed to start container: ${startResponse.body}');
    }
    print(startResponse.body);

    return startResponse.body;
  }

  /// Get container stats
  /// Example: statsContainer('containerId')
  Future<String> statsContainer(
    String containerId,
  ) async {
    final statsResponse = await _client.get(
      'containers/$containerId/stats',
    );

    if (statsResponse.statusCode != 200) {
      throw Exception('Failed to get container stats: ${statsResponse.body}');
    }
    print(statsResponse.body);

    return statsResponse.body;
  }

  /// Get container logs
  /// Example: logsContainer('containerId')
  Future<String> logsContainer(
    String containerId,
  ) async {
    final logsResponse = await _client.get(
      'containers/$containerId/logs',
    );

    if (logsResponse.statusCode != 200) {
      throw Exception('Failed to get container logs: ${logsResponse.body}');
    }
    print(logsResponse.body);

    return logsResponse.body;
  }

  /// Delete a container by ID
  /// Example: deleteContainer(containerId)
  Future<void> deleteContainer(String containerId, {bool force = false}) async {
    final query = force ? '?force=true' : '';
    final response = await _client.delete(
      'containers/$containerId$query',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete container: ${response.body}');
    }
  }

  /// Kill a container (compat API)
  ///
  /// [name] - Container name or ID
  /// [signal] - Signal to send (default: SIGKILL)
  /// [all] - Send kill signal to all containers (default: false)
  Future<PodmanResponse> killContainer({
    required String name,
    String signal = 'SIGKILL',
    bool all = false,
  }) async {
    final queryParams = <String, String>{
      'signal': signal,
      'all': all.toString(),
    };

    final query = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return await _client.post('containers/$name/kill?$query');
  }

  /// Kill containers with filters (compat API)
  ///
  /// [filters] - JSON-encoded filters map
  /// [signal] - Signal to send (default: SIGKILL)
  Future<List<String>> killContainersWithFilter({
    required Map<String, List<String>> filters,
    String signal = 'SIGKILL',
  }) async {
    // Get list of containers matching filters
    final listResponse = await listContainers(filters: filters);

    if (listResponse.statusCode != 200) {
      throw Exception('Failed to list containers: ${listResponse.body}');
    }

    final containers = jsonDecode(listResponse.body) as List;
    final killedContainers = <String>[];

    // Kill each container
    for (final container in containers) {
      final id = container['Id'] as String;
      final response = await killContainer(name: id, signal: signal);

      if (response.statusCode == 204) {
        killedContainers.add(id);
      }
    }

    return killedContainers;
  }

  /// Pause a container (compat API)
  ///
  /// [name] - Container name or ID
  Future<PodmanResponse> pauseContainer(String name) async {
    return await _client.post('containers/$name/pause');
  }

  /// Pause containers with filters (compat API)
  ///
  /// [filters] - JSON-encoded filters map
  Future<List<String>> pauseContainersWithFilter({
    required Map<String, List<String>> filters,
  }) async {
    final listResponse = await listContainers(filters: filters);

    if (listResponse.statusCode != 200) {
      throw Exception('Failed to list containers: ${listResponse.body}');
    }

    final containers = jsonDecode(listResponse.body) as List;
    final pausedContainers = <String>[];

    for (final container in containers) {
      final id = container['Id'] as String;
      final response = await pauseContainer(id);

      if (response.statusCode == 204) {
        pausedContainers.add(id);
      }
    }

    return pausedContainers;
  }

  /// Unpause a container (compat API)
  ///
  /// [name] - Container name or ID
  Future<PodmanResponse> unpauseContainer(String name) async {
    return await _client.post('containers/$name/unpause');
  }

  /// Restart a container (compat API)
  ///
  /// [name] - Container name or ID
  /// [timeout] - Timeout in seconds before sending kill signal
  Future<PodmanResponse> restartContainer({
    required String name,
    int? timeout,
  }) async {
    final query = timeout != null ? 't=$timeout' : '';
    final path = query.isEmpty
        ? 'containers/$name/restart'
        : 'containers/$name/restart?$query';

    return await _client.post(path);
  }

  /// Restart containers with filters (compat API)
  ///
  /// [filters] - JSON-encoded filters map
  /// [timeout] - Timeout in seconds before sending kill signal
  Future<List<String>> restartContainersWithFilter({
    required Map<String, List<String>> filters,
    int? timeout,
  }) async {
    final listResponse = await listContainers(filters: filters);

    if (listResponse.statusCode != 200) {
      throw Exception('Failed to list containers: ${listResponse.body}');
    }

    final containers = jsonDecode(listResponse.body) as List;
    final restartedContainers = <String>[];

    for (final container in containers) {
      final id = container['Id'] as String;
      final response = await restartContainer(name: id, timeout: timeout);

      if (response.statusCode == 204) {
        restartedContainers.add(id);
      }
    }

    return restartedContainers;
  }

  /// Stop a container (compat API)
  ///
  /// [name] - Container name or ID
  /// [timeout] - Timeout in seconds before killing container
  Future<PodmanResponse> stopContainer({
    required String name,
    int? timeout,
  }) async {
    final query = timeout != null ? 't=$timeout' : '';
    final path = query.isEmpty
        ? 'containers/$name/stop'
        : 'containers/$name/stop?$query';

    return await _client.post(path);
  }

  /// Stop containers with filters (compat API)
  ///
  /// [filters] - JSON-encoded filters map
  /// [timeout] - Timeout in seconds before killing container
  Future<List<String>> stopContainersWithFilter({
    required Map<String, List<String>> filters,
    int? timeout,
  }) async {
    final listResponse = await listContainers(filters: filters);

    if (listResponse.statusCode != 200) {
      throw Exception('Failed to list containers: ${listResponse.body}');
    }

    final containers = jsonDecode(listResponse.body) as List;
    final stoppedContainers = <String>[];

    for (final container in containers) {
      final id = container['Id'] as String;
      final response = await stopContainer(name: id, timeout: timeout);

      if (response.statusCode == 204 || response.statusCode == 304) {
        stoppedContainers.add(id);
      }
    }

    return stoppedContainers;
  }

  /// Wait for a container to meet a condition (compat API)
  ///
  /// [name] - Container name or ID
  /// [condition] - Condition to wait for (configured, created, exited, paused, running, stopped)
  /// [interval] - Time interval to wait before polling (default: 250ms)
  Future<PodmanResponse> waitContainer({
    required String name,
    String condition = 'stopped',
    String interval = '250ms',
  }) async {
    final queryParams = <String, String>{
      'condition': condition,
      'interval': interval,
    };

    final query = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return await _client.post('containers/$name/wait?$query');
  }

  /// Check if a container exists (libpod API)
  ///
  /// [name] - Container name or ID
  /// Returns true if container exists (204), false if not found (404)
  Future<bool> containerExists(String name) async {
    final response = await _client.get('libpod/containers/$name/exists');
    return response.statusCode == 204;
  }

  /// List containers (compat API) - helper method for filter operations
  ///
  /// [all] - Return all containers (default: false, only running)
  /// [filters] - Filters to apply
  Future<PodmanResponse> listContainers({
    bool all = true,
    Map<String, List<String>>? filters,
  }) async {
    final queryParams = <String, String>{
      'all': all.toString(),
    };

    if (filters != null && filters.isNotEmpty) {
      queryParams['filters'] = jsonEncode(filters);
    }

    final query = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return await _client.get('containers/json?$query');
  }
}
