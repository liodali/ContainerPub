# Podman Client Performance Benchmark

Comprehensive benchmark suite to compare the performance of **Python CLI** vs **Dart CLI** for Podman operations.

## Overview

This benchmark measures the execution time of common Podman operations using two different CLI implementations:

1. **Python CLI** (`podman_client.py`) - CLI using Podman Python library
2. **Dart CLI** (`podman_dart_cli.dart`) - CLI using direct Unix socket communication

Both are command-line tools with identical interfaces and JSON output format, enabling a true one-to-one comparison.

## Benchmark Operations

### 1. List Images

- **Python**: `python3 podman_client.py images`
- **Dart**: `dart run podman_dart_cli.dart images`

### 2. List Containers

- **Python**: `python3 podman_client.py ps --all`
- **Dart**: `dart run podman_dart_cli.dart ps --all`

### 3. Run Container + Delete

- **Python**: `python3 podman_client.py run alpine:latest` + `rm container_id`
- **Dart**: `dart run podman_dart_cli.dart run alpine:latest` + `rm container_id`

This workflow measures the complete lifecycle of creating and deleting a container.

## Prerequisites

### Python Requirements

```bash
# Install Python dependencies
pip3 install podman
```

### Dart Requirements

```bash
# Navigate to Dart package
cd tools/dart_packages/podman_socket_dart_client

# Get dependencies (includes args package for CLI)
dart pub get

# Test the CLI
dart run bin/podman_dart_cli.dart --help
```

### Podman Setup

Ensure Podman is running and socket is accessible:

```bash
# Check socket exists
ls -la /run/podman/podman.sock

# Or for Podman Machine on macOS
ls -la ~/Library/Containers/com.docker.docker/Data/podman/podman.sock
```

## Running Benchmarks

### Option 1: Python Benchmark Script (Comprehensive)

Runs both Python CLI and Dart client benchmarks:

```bash
cd tools

# Default (10 iterations)
python3 benchmark_podman_clients.py

# Custom socket path
python3 benchmark_podman_clients.py --socket /path/to/podman.sock

# More iterations for better accuracy
python3 benchmark_podman_clients.py --iterations 50

# Help
python3 benchmark_podman_clients.py --help
```

**Output:**

- Console output with real-time progress
- `benchmark_results.json` - Detailed results in JSON format

### Option 2: Dart Benchmark Script (Dart Only)

Runs only Dart socket client benchmarks:

```bash
cd tools/dart_packages/podman_socket_dart_client

# Default (10 iterations)
dart run benchmark/benchmark_dart_client.dart

# Custom socket path
dart run benchmark/benchmark_dart_client.dart --socket /path/to/podman.sock

# More iterations
dart run benchmark/benchmark_dart_client.dart --iterations 50

# Help
dart run benchmark/benchmark_dart_client.dart --help
```

**Output:**

- Console output with real-time progress
- `benchmark_results_dart.json` - Detailed results in JSON format

## Understanding Results

### Metrics Explained

- **Mean**: Average execution time across all iterations
- **Median**: Middle value when times are sorted (less affected by outliers)
- **Min**: Fastest execution time
- **Max**: Slowest execution time
- **Std Dev**: Standard deviation (measures consistency)
- **Iterations**: Number of successful test runs

### Expected Performance Characteristics

#### Python CLI

- **Pros**:
  - Easy to use from command line
  - JSON output for easy parsing
  - No compilation needed
- **Cons**:
  - Subprocess overhead (~50-100ms startup time)
  - Python interpreter startup
  - Additional process creation overhead

#### Dart Socket Client

- **Pros**:
  - Direct socket communication (no subprocess)
  - Compiled Dart code (faster execution)
  - Lower latency for simple operations
- **Cons**:
  - Requires Dart runtime
  - More complex integration

### Performance Expectations

```
Operation          Python CLI    Dart CLI       Expected Winner
─────────────────────────────────────────────────────────────────
List Images        ~250-350ms    ~200-300ms     Dart (slightly faster)
List Containers    ~150-250ms    ~100-200ms     Dart (slightly faster)
Run + Delete       ~400-600ms    ~350-500ms     Dart (slightly faster)
```

**Why Dart May Be Slightly Faster:**

1. Direct Unix socket communication vs Python library overhead
2. Compiled Dart code vs interpreted Python
3. More efficient HTTP request building

**Both Have:**

1. Subprocess creation overhead (~50-100ms)
2. Runtime initialization overhead
3. Similar JSON parsing overhead

**Key Insight:**
This is a true CLI-to-CLI comparison. Both are command-line tools with subprocess overhead, making the performance difference smaller than comparing a CLI to a library. The main difference is in the underlying implementation (direct socket vs Python library).

## Sample Output

```
============================================================
Benchmarking: List Images
============================================================
  Python iteration 1/10: 0.1523s ✓
  Python iteration 2/10: 0.1489s ✓
  ...

============================================================
Results: List Images
============================================================

Python CLI           Dart Socket Client
-------------------- --------------------
Mean:           0.1506s    0.0523s
Median:         0.1501s    0.0518s
Min:            0.1445s    0.0501s
Max:            0.1589s    0.0567s
Std Dev:        0.0042s    0.0018s
Iterations:         10          10

🏆 Dart Socket Client is 2.88x faster
```

## Analyzing Results

### JSON Output Structure

```json
{
  "list_images": {
    "python": {
      "times": [0.1523, 0.1489, ...],
      "stats": {
        "mean": 0.1506,
        "median": 0.1501,
        "min": 0.1445,
        "max": 0.1589,
        "stdev": 0.0042
      }
    },
    "dart": {
      "times": [0.0523, 0.0518, ...],
      "stats": { ... }
    }
  }
}
```

### Tips for Accurate Benchmarking

1. **Run multiple iterations**: Use at least 10-20 iterations for statistical significance
2. **Warm up**: First few runs may be slower due to caching
3. **Consistent environment**: Close other applications, avoid system load
4. **Multiple runs**: Run benchmark multiple times and compare results
5. **Socket location**: Ensure socket path is correct for your system

## Troubleshooting

### Socket Not Found

```bash
# Find Podman socket
podman info | grep -i socket

# Or check common locations
ls -la /run/podman/podman.sock
ls -la /var/run/podman/podman.sock
ls -la ~/Library/Containers/com.docker.docker/Data/podman/podman.sock
```

### Python CLI Fails

```bash
# Check Python dependencies
pip3 list | grep podman

# Test CLI directly
python3 tools/podman_client/podman_client.py --socket /path/to/socket images
```

### Dart Client Fails

```bash
# Check Dart dependencies
cd tools/dart_packages/podman_socket_dart_client
dart pub get

# Test example directly
dart run example/podman_socket_dart_client_example.dart
```

### Permission Denied

```bash
# Check socket permissions
ls -la /run/podman/podman.sock

# Add user to podman group (Linux)
sudo usermod -aG podman $USER
```

## Integration with Backend

The benchmark results help decide which implementation to use in the ContainerPub backend:

- **For high-frequency operations**: Use Dart socket client (lower latency)
- **For CLI tools**: Use Python CLI (easier integration)
- **For backend services**: Use Dart socket client (better performance)

## Contributing

To add new benchmark operations:

1. Add operation to `benchmark_podman_clients.py`
2. Add corresponding operation to `benchmark_dart_client.dart`
3. Update this README with expected results
4. Run benchmarks and document findings

## License

Part of the ContainerPub project.
