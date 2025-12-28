import 'dart:io';
import 'dart:convert';
import 'package:podman_socket_dart_client/podman_socket_dart_client.dart';

class BenchmarkResult {
  final String operation;
  final List<Duration> times;

  BenchmarkResult(this.operation, this.times);

  Duration get mean {
    if (times.isEmpty) return Duration.zero;
    final total = times.fold<int>(0, (sum, d) => sum + d.inMicroseconds);
    return Duration(microseconds: total ~/ times.length);
  }

  Duration get median {
    if (times.isEmpty) return Duration.zero;
    final sorted = List<Duration>.from(times)..sort((a, b) => a.compareTo(b));
    return sorted[sorted.length ~/ 2];
  }

  Duration get min =>
      times.isEmpty ? Duration.zero : times.reduce((a, b) => a < b ? a : b);
  Duration get max =>
      times.isEmpty ? Duration.zero : times.reduce((a, b) => a > b ? a : b);

  double get stdev {
    if (times.length < 2) return 0.0;
    final meanMicros = mean.inMicroseconds;
    final variance =
        times.fold<double>(
          0.0,
          (sum, d) {
            final diff = d.inMicroseconds - meanMicros;
            return sum + (diff * diff);
          },
        ) /
        times.length;
    return sqrt(variance);
  }

  Map<String, dynamic> toJson() => {
    'operation': operation,
    'mean_ms': mean.inMilliseconds,
    'median_ms': median.inMilliseconds,
    'min_ms': min.inMilliseconds,
    'max_ms': max.inMilliseconds,
    'stdev_ms': stdev / 1000,
    'iterations': times.length,
    'times_ms': times.map((d) => d.inMilliseconds).toList(),
  };
}

double sqrt(double x) {
  if (x < 0) return double.nan;
  if (x == 0) return 0;

  double guess = x / 2;
  double lastGuess;

  do {
    lastGuess = guess;
    guess = (guess + x / guess) / 2;
  } while ((guess - lastGuess).abs() > 0.0001);

  return guess;
}

class DartClientBenchmark {
  final String socketPath;
  final int iterations;
  final PodmanClient client;
  final List<BenchmarkResult> results = [];

  DartClientBenchmark({
    required this.socketPath,
    this.iterations = 10,
  }) : client = PodmanClient(socketPath: socketPath);

  Future<Duration> measureOperation(Future<void> Function() operation) async {
    final stopwatch = Stopwatch()..start();
    await operation();
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  Future<void> benchmarkListImages() async {
    print('\n${'=' * 60}');
    print('Benchmarking: List Images');
    print('=' * 60);

    final times = <Duration>[];

    for (int i = 0; i < iterations; i++) {
      try {
        final elapsed = await measureOperation(() async {
          await client.imagesOps.existImage('docker.io/library/alpine:latest');
        });
        times.add(elapsed);
        print(
          '  Iteration ${i + 1}/$iterations: ${elapsed.inMilliseconds}ms ✓',
        );
      } catch (e) {
        print('  Iteration ${i + 1}/$iterations: FAILED - $e');
      }

      await Future.delayed(Duration(milliseconds: 100));
    }

    results.add(BenchmarkResult('list_images', times));
  }

  Future<void> benchmarkListContainers() async {
    print('\n${'=' * 60}');
    print('Benchmarking: List Containers');
    print('=' * 60);

    final times = <Duration>[];

    for (int i = 0; i < iterations; i++) {
      try {
        final elapsed = await measureOperation(() async {
          await client.containerOps.listContainers(all: true);
        });
        times.add(elapsed);
        print(
          '  Iteration ${i + 1}/$iterations: ${elapsed.inMilliseconds}ms ✓',
        );
      } catch (e) {
        print('  Iteration ${i + 1}/$iterations: FAILED - $e');
      }

      await Future.delayed(Duration(milliseconds: 100));
    }

    results.add(BenchmarkResult('list_containers', times));
  }

  Future<void> benchmarkFullWorkflow() async {
    print('\n${'=' * 60}');
    print('Benchmarking: Full Workflow (Check + Run + Delete)');
    print('=' * 60);

    final times = <Duration>[];

    for (int i = 0; i < iterations; i++) {
      try {
        final elapsed = await measureOperation(() async {
          // Check if image exists
          final exists = await client.imagesOps.existImage(
            'docker.io/library/alpine:latest',
          );

          if (!exists) {
            await client.imagesOps.pullImage('docker.io/library/alpine:latest');
          }

          // Run container
          final containerId = await client.containerOps.runContainer(
            CompatContainerConfig(
              image: 'alpine:latest',
              cmd: ['echo', 'Hello from benchmark ${DateTime.now()}'],
              name: 'benchmark-container-$i',
            ),
          );

          // Small delay to let container start
          await Future.delayed(Duration(milliseconds: 500));

          // Delete container
          await client.containerOps.deleteContainer(containerId, force: true);
        });

        times.add(elapsed);
        print(
          '  Iteration ${i + 1}/$iterations: ${elapsed.inMilliseconds}ms ✓',
        );
      } catch (e) {
        print('  Iteration ${i + 1}/$iterations: FAILED - $e');
      }

      await Future.delayed(Duration(milliseconds: 500));
    }

    results.add(BenchmarkResult('full_workflow', times));
  }

  Future<void> benchmarkContainerCreate() async {
    print('\n${'=' * 60}');
    print('Benchmarking: Container Create Only');
    print('=' * 60);

    final times = <Duration>[];
    final containerIds = <String>[];

    for (int i = 0; i < iterations; i++) {
      try {
        final elapsed = await measureOperation(() async {
          final containerId = await client.containerOps.runContainer(
            CompatContainerConfig(
              image: 'alpine:latest',
              cmd: ['echo', 'test'],
              name: 'bench-create-$i',
            ),
            start: false,
          );
          containerIds.add(containerId);
        });

        times.add(elapsed);
        print(
          '  Iteration ${i + 1}/$iterations: ${elapsed.inMilliseconds}ms ✓',
        );
      } catch (e) {
        print('  Iteration ${i + 1}/$iterations: FAILED - $e');
      }

      await Future.delayed(Duration(milliseconds: 100));
    }

    // Cleanup
    print('\nCleaning up test containers...');
    for (final id in containerIds) {
      try {
        await client.containerOps.deleteContainer(id, force: true);
      } catch (e) {
        // Ignore cleanup errors
      }
    }

    results.add(BenchmarkResult('container_create', times));
  }

  void printResults() {
    print('\n${'=' * 60}');
    print('BENCHMARK RESULTS - Dart Socket Client');
    print('=' * 60);

    for (final result in results) {
      print('\n${result.operation.toUpperCase()}:');
      print('  Mean:       ${result.mean.inMilliseconds}ms');
      print('  Median:     ${result.median.inMilliseconds}ms');
      print('  Min:        ${result.min.inMilliseconds}ms');
      print('  Max:        ${result.max.inMilliseconds}ms');
      print('  Std Dev:    ${result.stdev.toStringAsFixed(2)}μs');
      print('  Iterations: ${result.times.length}');
    }
  }

  Future<void> saveResults(String filename) async {
    final data = {
      'socket_path': socketPath,
      'iterations': iterations,
      'timestamp': DateTime.now().toIso8601String(),
      'results': results.map((r) => r.toJson()).toList(),
    };

    final file = File(filename);
    await file.writeAsString(JsonEncoder.withIndent('  ').convert(data));
    print('\n✓ Results saved to: $filename');
  }

  Future<void> runAllBenchmarks() async {
    print('\n${'#' * 60}');
    print('# Dart Socket Client Performance Benchmark');
    print('# Socket: $socketPath');
    print('# Iterations: $iterations');
    print('#' * 60);

    // Verify socket exists
    if (!File(socketPath).existsSync()) {
      print('ERROR: Socket not found at $socketPath');
      exit(1);
    }

    // Run benchmarks
    await benchmarkListImages();
    await benchmarkListContainers();
    await benchmarkContainerCreate();
    await benchmarkFullWorkflow();

    // Print results
    printResults();

    // Save to file
    await saveResults('benchmark_results_dart.json');
  }
}

void main(List<String> args) async {
  String socketPath = '/run/podman/podman.sock';
  int iterations = 10;

  // Parse arguments
  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--socket' && i + 1 < args.length) {
      socketPath = args[i + 1];
      i++;
    } else if (args[i] == '--iterations' && i + 1 < args.length) {
      iterations = int.tryParse(args[i + 1]) ?? 10;
      i++;
    } else if (args[i] == '--help') {
      print('Usage: dart run benchmark_dart_client.dart [options]');
      print('Options:');
      print(
        '  --socket PATH        Path to Podman socket (default: /run/podman/podman.sock)',
      );
      print(
        '  --iterations N       Number of iterations per test (default: 10)',
      );
      print('  --help              Show this help message');
      exit(0);
    }
  }

  final benchmark = DartClientBenchmark(
    socketPath: socketPath,
    iterations: iterations,
  );

  await benchmark.runAllBenchmarks();
}
