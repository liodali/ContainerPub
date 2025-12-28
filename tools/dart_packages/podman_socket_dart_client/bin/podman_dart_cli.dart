#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:podman_socket_dart_client/podman_socket_dart_client.dart';

void printJson(Map<String, dynamic> data) {
  print(JsonEncoder.withIndent('  ').convert(data));
}

void printError(String message) {
  stderr.writeln(
    JsonEncoder.withIndent('  ').convert({
      'success': false,
      'error': message,
    }),
  );
}

void printSuccess(dynamic data) {
  printJson({
    'success': true,
    'data': data,
  });
}

Future<void> listImages(PodmanClient client, {bool all = false}) async {
  try {
    final response = await client.podmanSocketClient.get(
      'images/json?all=$all',
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to list images: ${response.body}');
    }

    final images = jsonDecode(response.body) as List;
    final imagesData = images
        .map(
          (img) => {
            'id': img['Id'],
            'tags': img['RepoTags'] ?? [],
            'size': img['Size'] ?? 0,
            'created': img['Created'] ?? '',
            'digest': img['Digest'] ?? '',
          },
        )
        .toList();

    printSuccess(imagesData);
  } catch (e, trace) {
    printError('Failed to list images: $e');
    printError(trace.toString());
    exit(1);
  }
}

Future<void> buildImage(
  PodmanClient client, {
  required String context,
  String? tag,
  String dockerfile = 'Dockerfile',
  Map<String, String>? buildArgs,
}) async {
  try {
    printError('Build image not yet implemented in Dart CLI');
    exit(1);
  } catch (e) {
    printError('Failed to build image: $e');
    exit(1);
  }
}

Future<void> runContainer(
  PodmanClient client, {
  required String image,
  String? name,
  bool detach = true,
  Map<String, int>? ports,
  Map<String, String>? environment,
  Map<String, Map<String, String>>? volumes,
  List<String>? command,
}) async {
  try {
    final hostConfig = CompatHostConfig(
      portBindings: ports?.map(
        (container, host) => MapEntry(
          container,
          [
            {'HostPort': host.toString()},
          ],
        ),
      ),
    );

    final config = CompatContainerConfig(
      image: image,
      name: name,
      cmd: command,
      env: environment?.entries.map((e) => '${e.key}=${e.value}').toList(),
      hostConfig: hostConfig,
    );

    final containerId = await client.containerOps.runContainer(config);

    // Get container details
    final response = await client.podmanSocketClient.get(
      'containers/$containerId/json',
    );
    final containerData = jsonDecode(response.body);

    printSuccess({
      'container_id': containerId,
      'name': containerData['Name']?.toString().replaceFirst('/', ''),
      'status': containerData['State']?['Status'] ?? 'unknown',
      'image': image,
    });
  } catch (e) {
    printError('Failed to run container: $e');
    exit(1);
  }
}

Future<void> deleteContainer(
  PodmanClient client, {
  required String containerId,
  bool force = false,
}) async {
  try {
    await client.containerOps.deleteContainer(containerId, force: force);

    printSuccess({
      'container_id': containerId,
      'message': 'Container deleted successfully',
    });
  } catch (e) {
    printError('Failed to delete container: $e');
    exit(1);
  }
}

Future<void> listContainers(PodmanClient client, {bool all = false}) async {
  try {
    final response = await client.containerOps.listContainers(all: all);

    if (response.statusCode != 200) {
      throw Exception('Failed to list containers: ${response.body}');
    }

    final containers = jsonDecode(response.body) as List;
    final containersData = containers
        .map(
          (container) => {
            'id': container['Id'],
            'name':
                (container['Names'] as List?)?.first?.toString().replaceFirst(
                  '/',
                  '',
                ) ??
                '',
            'status': container['State'] ?? 'unknown',
            'image': container['Image'] ?? 'unknown',
            'created': container['Created'] ?? '',
          },
        )
        .toList();

    printSuccess(containersData);
  } catch (e) {
    printError('Failed to list containers: $e');
    exit(1);
  }
}

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'socket',
      defaultsTo: '/run/podman/podman.sock',
      help: 'Path to Podman socket',
    )
    ..addCommand(
      'images',
      ArgParser()..addFlag(
        'all',
        abbr: 'a',
        defaultsTo: false,
        help: 'Show all images (including intermediate)',
      ),
    )
    ..addCommand(
      'build',
      ArgParser()
        ..addOption('tag', abbr: 't', help: 'Image tag (e.g., myapp:latest)')
        ..addOption(
          'file',
          abbr: 'f',
          defaultsTo: 'Dockerfile',
          help: 'Dockerfile name',
        )
        ..addMultiOption(
          'build-arg',
          help: 'Build arguments (format: KEY=VALUE)',
        ),
    )
    ..addCommand(
      'run',
      ArgParser()
        ..addOption('name', help: 'Container name')
        ..addFlag(
          'detach',
          abbr: 'd',
          defaultsTo: true,
          help: 'Run container in background',
        )
        ..addMultiOption(
          'port',
          abbr: 'p',
          help: 'Port mapping (format: HOST:CONTAINER)',
        )
        ..addMultiOption(
          'env',
          abbr: 'e',
          help: 'Environment variables (format: KEY=VALUE)',
        )
        ..addMultiOption(
          'volume',
          abbr: 'v',
          help: 'Volume mapping (format: HOST:CONTAINER)',
        ),
    )
    ..addCommand(
      'rm',
      ArgParser()
        ..addOption(
          'container-id',
          abbr: 'i',
          help: 'Container ID',
        )
        ..addFlag(
          'force',
          abbr: 'f',
          defaultsTo: false,
          help: 'Force delete (stop if running)',
        ),
    )
    ..addCommand(
      'ps',
      ArgParser()..addFlag(
        'all',
        abbr: 'a',
        defaultsTo: false,
        help: 'Show all containers (including stopped)',
      ),
    );

  try {
    final results = parser.parse(arguments);

    if (results.command == null) {
      print(
        'Podman Dart CLI - Manage containers and images via Podman socket\n',
      );
      print('Usage: podman_dart_cli [options] <command>\n');
      print(parser.usage);
      exit(1);
    }

    final socketPath = results['socket'] as String;
    final client = PodmanClient(socketPath: socketPath);

    switch (results.command!.name) {
      case 'images':
        await listImages(client, all: results.command!['all'] as bool);
        break;

      case 'build':
        final buildArgs = <String, String>{};
        for (final arg in results.command!['build-arg'] as List<String>) {
          final parts = arg.split('=');
          if (parts.length == 2) {
            buildArgs[parts[0]] = parts[1];
          }
        }

        if (results.command!.rest.isEmpty) {
          printError('Build context path required');
          exit(1);
        }

        await buildImage(
          client,
          context: results.command!.rest.first,
          tag: results.command!['tag'] as String?,
          dockerfile: results.command!['file'] as String,
          buildArgs: buildArgs.isNotEmpty ? buildArgs : null,
        );
        break;

      case 'run':
        if (results.command!.rest.isEmpty) {
          printError('Image name required');
          exit(1);
        }

        final ports = <String, int>{};
        final portList = results.command!['port'] as List<String>? ?? [];
        for (final port in portList) {
          final parts = port.split(':');
          if (parts.length == 2) {
            ports[parts[1]] = int.parse(parts[0]);
          }
        }

        final env = <String, String>{};
        final envList = results.command!['env'] as List<String>? ?? [];
        for (final envVar in envList) {
          final parts = envVar.split('=');
          if (parts.length == 2) {
            env[parts[0]] = parts[1];
          }
        }

        final volumes = <String, Map<String, String>>{};
        final volumeList = results.command!['volume'] as List<String>? ?? [];
        for (final vol in volumeList) {
          final parts = vol.split(':');
          if (parts.length == 2) {
            volumes[parts[0]] = {'bind': parts[1], 'mode': 'rw'};
          }
        }

        await runContainer(
          client,
          image: results.command!.rest.first,
          name: results.command!['name'] as String?,
          detach: results.command!['detach'] as bool,
          ports: ports.isNotEmpty ? ports : null,
          environment: env.isNotEmpty ? env : null,
          volumes: volumes.isNotEmpty ? volumes : null,
          command: results.command!.rest.length > 1
              ? results.command!.rest.skip(1).toList()
              : null,
        );
        break;

      case 'rm':
        print(results.command!.arguments);
        if (!results.command!.arguments.contains('--container-id') &&
            results.command?.option('container-id') == null) {
          printError('Container ID or name required');
          exit(1);
        }

        await deleteContainer(
          client,
          containerId: results.command!.option('container-id')!,
          force: results.command!['force'] as bool,
        );
        break;

      case 'ps':
        await listContainers(client, all: results.command!['all'] as bool);
        break;

      default:
        printError('Unknown command: ${results.command!.name}');
        exit(1);
    }
  } catch (e) {
    printError('Error: $e');
    exit(1);
  }
}
