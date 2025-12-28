#!/usr/bin/env python3
"""
Benchmark script to compare Python CLI vs Dart Socket Client performance
"""
import subprocess
import json
import time
import sys
import os
from pathlib import Path
from typing import Dict, List, Tuple
from statistics import mean, median, stdev


class BenchmarkRunner:
    def __init__(self, socket_path: str, iterations: int = 10):
        self.socket_path = socket_path
        self.iterations = iterations
        self.results = {
            'python': {},
            'dart': {}
        }   
        
        # Paths
        self.python_cli = Path(__file__).parent / 'podman_client' / 'podman_client.py'
        self.dart_cli = Path(__file__).parent / 'dart_packages' / 'podman_socket_dart_client' / 'bin' / 'podman_dart_cli.dart'
        self.dart_package_dir = Path(__file__).parent / 'dart_packages' / 'podman_socket_dart_client'
        
    def run_python_command(self, command: List[str]) -> Tuple[float, bool, str]:
        """Run Python CLI command and measure execution time"""
        start = time.perf_counter()
        try:
            result = subprocess.run(
                ['python3', str(self.python_cli), '--socket', self.socket_path] + command,
                capture_output=True,
                text=True,
                timeout=30
            )
            elapsed = time.perf_counter() - start
            success = result.returncode == 0
            output = result.stdout if success else result.stderr
            return elapsed, success, output
        except subprocess.TimeoutExpired:
            elapsed = time.perf_counter() - start
            return elapsed, False, "Timeout"
        except Exception as e:
            elapsed = time.perf_counter() - start
            return elapsed, False, str(e)
    
    def run_dart_command(self, command: List[str]) -> Tuple[float, bool, str]:
        """Run Dart CLI command and measure execution time"""
        start = time.perf_counter()
        try:
            result = subprocess.run(
                ['dart', 'run', str(self.dart_cli), '--socket', self.socket_path] + command,
                capture_output=True,
                text=True,
                timeout=30,
                cwd=str(self.dart_package_dir)
            )
            elapsed = time.perf_counter() - start
            success = result.returncode == 0
            output = result.stdout if success else result.stderr
            return elapsed, success, output
        except subprocess.TimeoutExpired:
            elapsed = time.perf_counter() - start
            return elapsed, False, "Timeout"
        except Exception as e:
            elapsed = time.perf_counter() - start
            return elapsed, False, str(e)
    
    def benchmark_list_images(self) -> Dict[str, List[float]]:
        """Benchmark listing images"""
        print(f"\n{'='*60}")
        print("Benchmarking: List Images")
        print(f"{'='*60}")
        
        python_times = []
        dart_times = []
        
        print("\n--- Python CLI ---")
        for i in range(self.iterations):
            elapsed, success, output = self.run_python_command(['images'])
            if success:
                python_times.append(elapsed)
                print(f"  Python iteration {i+1}/{self.iterations}: {elapsed:.4f}s ✓")
            else:
                print(f"  Python iteration {i+1}/{self.iterations}: FAILED - {output[:100]}")
            time.sleep(0.1)
        
        print("\n--- Dart CLI ---")
        for i in range(self.iterations):
            elapsed, success, output = self.run_dart_command(['images'])
            if success:
                dart_times.append(elapsed)
                print(f"  Dart iteration {i+1}/{self.iterations}: {elapsed:.4f}s ✓")
            else:
                print(f"  Dart iteration {i+1}/{self.iterations}: FAILED - {output[:100]}")
            time.sleep(0.1)
        
        return {
            'python': python_times,
            'dart': dart_times
        }
    
    def benchmark_list_containers(self) -> Dict[str, List[float]]:
        """Benchmark listing containers"""
        print(f"\n{'='*60}")
        print("Benchmarking: List Containers")
        print(f"{'='*60}")
        
        python_times = []
        
        print("\n--- Python CLI ---")
        for i in range(self.iterations):
            elapsed, success, output = self.run_python_command(['ps', '--all'])
            if success:
                python_times.append(elapsed)
                print(f"  Python iteration {i+1}/{self.iterations}: {elapsed:.4f}s ✓")
            else:
                print(f"  Python iteration {i+1}/{self.iterations}: FAILED - {output[:100]}")
            time.sleep(0.1)
        dart_times = []
        print("\n--- Dart CLI ---")
        for i in range(self.iterations):
            elapsed, success, output = self.run_dart_command(['ps', '--all'])
            if success:
                dart_times.append(elapsed)
                print(f"  Dart iteration {i+1}/{self.iterations}: {elapsed:.4f}s ✓")
            else:
                print(f"  Dart iteration {i+1}/{self.iterations}: FAILED - {output[:100]}")
            time.sleep(0.1)
        
        return {
            'python': python_times,
            'dart': dart_times
        }
    
    def benchmark_run_and_delete(self) -> Dict[str, List[float]]:
        """Benchmark run container and delete workflow"""
        print(f"\n{'='*60}")
        print("Benchmarking: Run Container + Delete")
        print(f"{'='*60}")
        
        python_times = []
        dart_times = []
        
        # Python CLI workflow
        print("\n--- Python CLI ---")
        for i in range(self.iterations):
            try:
                start = time.perf_counter()
                pythonfile = str(self.python_cli)
                proccessArgs = ['python3', pythonfile, '--socket', self.socket_path,
                     'run', 'alpine:latest', '--name', f'bench-py-{i}']
                # Run container
                run_result = subprocess.run(
                    proccessArgs,
                    capture_output=True,
                    text=True,
                    timeout=30
                )
                if run_result.returncode == 0:
                    try:
                        container_data = json.loads(str(run_result.stdout))
                        container_id = container_data['data']['container_id']
                        
                        # Delete container
                        delete_result = subprocess.run(
                            ['python3', str(self.python_cli), '--socket', self.socket_path,
                             'rm','--container-id', container_id, '--force'],
                            capture_output=True,
                            text=True,
                            timeout=30
                        )
                        
                        if delete_result.returncode == 0:
                            elapsed = time.perf_counter() - start
                            python_times.append(elapsed)
                            print(f"  Python iteration {i+1}/{self.iterations}: {elapsed:.4f}s ✓")
                        else:
                            print(f"  Python iteration {i+1}/{self.iterations}: FAILED (delete) - {delete_result.stderr}")
                    except json.JSONDecodeError as je:
                        print(f"  Python iteration {i+1}/{self.iterations}: FAILED (parse) - {str(je)}")
                else:
                    error_msg = run_result.stderr or run_result.stdout
                    print(f"  Python iteration {i+1}/{self.iterations}: FAILED (run) - {error_msg}")
            except Exception as e:
                print(f"  Python iteration {i+1}/{self.iterations}: ERROR - {str(e)}")
            
            time.sleep(0.5)
        
        # Dart CLI workflow
        print("\n--- Dart CLI ---")
        for i in range(self.iterations):
            try:
                start = time.perf_counter()
                
                # Run container
                run_result = subprocess.run(
                    ['dart', 'run', str(self.dart_cli), '--socket', self.socket_path,
                     'run', 'alpine:latest', '--name', f'bench-dart-{i}'],
                    capture_output=True,
                    text=True,
                    timeout=30,
                    cwd=str(self.dart_package_dir)
                )
                
                if run_result.returncode == 0:
                    try:
                        container_data = json.loads(run_result.stdout)
                        container_id = container_data['data']['container_id']
                        
                        # Delete container
                        delete_result = subprocess.run(
                            ['dart', 'run', str(self.dart_cli), '--socket', self.socket_path,
                             'rm','--container-id',container_id, '--force'],
                            capture_output=True,
                            text=True,
                            timeout=30,
                            cwd=str(self.dart_package_dir)
                        )
                        
                        if delete_result.returncode == 0:
                            elapsed = time.perf_counter() - start
                            dart_times.append(elapsed)
                            print(f"  Dart iteration {i+1}/{self.iterations}: {elapsed:.4f}s ✓")
                        else:
                            print(f"  Dart iteration {i+1}/{self.iterations}: FAILED (delete) - {delete_result.stderr}")
                    except json.JSONDecodeError as je:
                        print(f"  Dart iteration {i+1}/{self.iterations}: FAILED (parse) - {str(je)}")
                else:
                    error_msg = run_result.stderr or run_result.stdout
                    print(f"  Dart iteration {i+1}/{self.iterations}: FAILED (run) - {error_msg}")
            except Exception as e:
                print(f"  Dart iteration {i+1}/{self.iterations}: ERROR - {str(e)}")
            
            time.sleep(0.5)
        
        return {
            'python': python_times,
            'dart': dart_times
        }
    
    def calculate_stats(self, times: List[float]) -> Dict[str, float]:
        """Calculate statistics from timing data"""
        if not times:
            return {
                'mean': 0,
                'median': 0,
                'min': 0,
                'max': 0,
                'stdev': 0
            }
        
        return {
            'mean': mean(times),
            'median': median(times),
            'min': min(times),
            'max': max(times),
            'stdev': stdev(times) if len(times) > 1 else 0
        }
    
    def print_comparison(self, operation: str, python_times: List[float], dart_times: List[float]):
        """Print comparison statistics"""
        print(f"\n{'='*60}")
        print(f"Results: {operation}")
        print(f"{'='*60}")
        
        python_stats = self.calculate_stats(python_times)
        dart_stats = self.calculate_stats(dart_times)
        
        print(f"\n{'Python CLI':<20} {'Dart Socket Client':<20}")
        print(f"{'-'*20} {'-'*20}")
        print(f"{'Mean:':<15} {python_stats['mean']:>6.4f}s    {dart_stats['mean']:>6.4f}s")
        print(f"{'Median:':<15} {python_stats['median']:>6.4f}s    {dart_stats['median']:>6.4f}s")
        print(f"{'Min:':<15} {python_stats['min']:>6.4f}s    {dart_stats['min']:>6.4f}s")
        print(f"{'Max:':<15} {python_stats['max']:>6.4f}s    {dart_stats['max']:>6.4f}s")
        print(f"{'Std Dev:':<15} {python_stats['stdev']:>6.4f}s    {dart_stats['stdev']:>6.4f}s")
        print(f"{'Iterations:':<15} {len(python_times):>6}      {len(dart_times):>6}")
        
        if python_times and dart_times:
            python_mean = python_stats['mean']
            dart_mean = dart_stats['mean']
            
            if python_mean < dart_mean:
                speedup = dart_mean / python_mean
                print(f"\n🏆 Python CLI is {speedup:.2f}x faster")
            elif dart_mean < python_mean:
                speedup = python_mean / dart_mean
                print(f"\n🏆 Dart Socket Client is {speedup:.2f}x faster")
            else:
                print(f"\n⚖️  Both implementations have similar performance")
    
    def run_all_benchmarks(self):
        """Run all benchmarks and generate report"""
        print(f"\n{'#'*60}")
        print("# Podman Client Performance Benchmark")
        print(f"# Socket: {self.socket_path}")
        print(f"# Iterations: {self.iterations}")
        print(f"{'#'*60}")
        
        # Check if files exist
        if not self.python_cli.exists():
            print(f"ERROR: Python CLI not found at {self.python_cli}")
            return
        
        if not self.dart_cli.exists():
            print(f"ERROR: Dart CLI not found at {self.dart_cli}")
            return
        
        # Run benchmarks
        results = {}
        
        # 1. List Images
        results['list_images'] = self.benchmark_list_images()
        self.print_comparison('List Images', 
                            results['list_images']['python'],
                            results['list_images']['dart'])
        
        # 2. List Containers
        results['list_containers'] = self.benchmark_list_containers()
        self.print_comparison('List Containers',
                            results['list_containers']['python'],
                            results['list_containers']['dart'])
        
        # 3. Run and Delete Workflow
        results['run_and_delete'] = self.benchmark_run_and_delete()
        self.print_comparison('Run Container + Delete',
                            results['run_and_delete']['python'],
                            results['run_and_delete']['dart'])
        
        # Generate summary
        self.generate_summary(results)
        
        # Save results to JSON
        self.save_results(results)
    
    def generate_summary(self, results: Dict):
        """Generate overall summary"""
        print(f"\n{'='*60}")
        print("OVERALL SUMMARY")
        print(f"{'='*60}")
        
        print("\nKey Findings:")
        print("- Python CLI: Subprocess overhead + Python runtime + Podman Python library")
        print("- Dart CLI: Subprocess overhead + Dart runtime + Direct socket communication")
        print("\nExpected Results:")
        print("- Both have subprocess startup overhead")
        print("- Dart may be slightly faster due to direct socket vs Python library")
        print("- True one-to-one CLI comparison (both are command-line tools)")
    
    def save_results(self, results: Dict):
        """Save results to JSON file in benchmark folder"""
        from datetime import datetime
        
        # Create benchmark folder
        benchmark_dir = Path(__file__).parent / 'benchmark'
        benchmark_dir.mkdir(exist_ok=True)
        
        # Create timestamped filename
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        output_file = benchmark_dir / f'results_{timestamp}.json'
        
        # Convert to serializable format
        serializable_results = {
            'timestamp': datetime.now().isoformat(),
            'socket_path': self.socket_path,
            'iterations': self.iterations,
            'results': {}
        }
        
        for operation, data in results.items():
            serializable_results['results'][operation] = {
                'python': {
                    'times': data['python'],
                    'stats': self.calculate_stats(data['python'])
                },
                'dart': {
                    'times': data['dart'],
                    'stats': self.calculate_stats(data['dart'])
                }
            }
        
        with open(output_file, 'w') as f:
            json.dump(serializable_results, f, indent=2)
        
        # Also save latest results as symlink/copy
        latest_file = benchmark_dir / 'results_latest.json'
        with open(latest_file, 'w') as f:
            json.dump(serializable_results, f, indent=2)
        
        print(f"\n✓ Results saved to: {output_file}")
        print(f"✓ Latest results: {latest_file}")


def main():
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Benchmark Python CLI vs Dart Socket Client for Podman"
    )
    parser.add_argument(
        '--socket',
        type=str,
        default='/run/podman/podman.sock',
        help='Path to Podman socket'
    )
    parser.add_argument(
        '--iterations',
        type=int,
        default=10,
        help='Number of iterations per test (default: 10)'
    )
    
    args = parser.parse_args()
    
    # Check if socket exists
    if not os.path.exists(args.socket):
        print(f"ERROR: Podman socket not found at {args.socket}")
        print("Please ensure Podman is running and socket path is correct")
        sys.exit(1)
    
    benchmark = BenchmarkRunner(args.socket, args.iterations)
    benchmark.run_all_benchmarks()


if __name__ == '__main__':
    main()
