import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:dart_cloud_backend/config/config.dart';

class FunctionExecutor {
  final String functionId;

  FunctionExecutor(this.functionId);

  Future<Map<String, dynamic>> execute(Map<String, dynamic> input) async {
    final functionDir = path.join(Config.functionsDir, functionId);
    final functionDirObj = Directory(functionDir);

    if (!await functionDirObj.exists()) {
      return {
        'success': false,
        'error': 'Function directory not found',
        'result': null,
      };
    }

    try {
      // Create a temporary file with the input data
      final tempInputFile = File(path.join(functionDir, '.input.json'));
      await tempInputFile.writeAsString(jsonEncode(input));

      // Execute the Dart function
      // Look for main.dart or bin/main.dart
      String? mainFile;
      final mainDartFile = File(path.join(functionDir, 'main.dart'));
      final binMainDartFile = File(path.join(functionDir, 'bin', 'main.dart'));

      if (await mainDartFile.exists()) {
        mainFile = mainDartFile.path;
      } else if (await binMainDartFile.exists()) {
        mainFile = binMainDartFile.path;
      } else {
        return {
          'success': false,
          'error': 'No main.dart or bin/main.dart found in function',
          'result': null,
        };
      }

      // Run the function with a timeout
      final process = await Process.start(
        'dart',
        ['run', mainFile],
        workingDirectory: functionDir,
        environment: {'FUNCTION_INPUT': jsonEncode(input)},
      );

      final stdout = <String>[];
      final stderr = <String>[];

      process.stdout.transform(utf8.decoder).listen((data) {
        stdout.add(data);
      });

      process.stderr.transform(utf8.decoder).listen((data) {
        stderr.add(data);
      });

      // Wait for process with timeout
      final exitCode = await process.exitCode.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          process.kill();
          return -1;
        },
      );

      // Clean up temp file
      if (await tempInputFile.exists()) {
        await tempInputFile.delete();
      }

      if (exitCode == -1) {
        return {
          'success': false,
          'error': 'Function execution timed out (30s)',
          'result': null,
        };
      }

      if (exitCode != 0) {
        return {
          'success': false,
          'error': 'Function exited with code $exitCode: ${stderr.join()}',
          'result': null,
        };
      }

      // Try to parse output as JSON, otherwise return as string
      final output = stdout.join().trim();
      dynamic result;

      try {
        result = jsonDecode(output);
      } catch (e) {
        result = output;
      }

      return {'success': true, 'error': null, 'result': result};
    } catch (e) {
      return {'success': false, 'error': 'Execution error: $e', 'result': null};
    }
  }
}
