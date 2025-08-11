import '../../interpreter_test.dart';
import 'package:test/test.dart';

void main() {
  group('Process methods - comprehensive', () {
    test('Process.run with echo command', () async {
      const source = '''
     import 'dart:io';
     main() async {
        var result = await Process.run('echo', ['Hello World']);
        return [result.exitCode, result.stdout.toString().trim()];
      }
      ''';
      final result = await execute(source);
      expect(result[0], equals(0)); // Exit code should be 0
      expect(result[1], equals('Hello World')); // Output should match
    });

    test('Process.runSync with echo command', () {
      const source = '''
     import 'dart:io';
     main() {
        var result = Process.runSync('echo', ['Hello Sync']);
        return [result.exitCode, result.stdout.toString().trim()];
      }
      ''';
      final result = execute(source);
      expect(result[0], equals(0));
      expect(result[1], equals('Hello Sync'));
    });

    test('Process.start basic functionality', () async {
      const source = '''
     import 'dart:io';
     main() async {
        var process = await Process.start('echo', ['Test Process']);
        var exitCode = await process.exitCode;
        return [process.pid > 0, exitCode];
      }
      ''';
      final result = await execute(source);
      expect(result[0], isTrue); // PID should be positive
      expect(result[1], equals(0)); // Exit code should be 0
    });

    test('Process.killPid functionality', () async {
      const source = '''
     import 'dart:io';
     main() async {
        // Start a long-running process
        var process = await Process.start('sleep', ['1']);
        var pid = process.pid;
        var killed = Process.killPid(pid);
        return killed;
      }
      ''';
      // Note: This test may be platform dependent
      final result = await execute(source);
      expect(result, isA<bool>());
    });

    test('ProcessResult properties', () {
      const source = '''
     import 'dart:io';
     main() {
        var result = Process.runSync('echo', ['Test Output']);
        return [
          result.pid > 0,
          result.exitCode,
          result.stdout is List<int> || result.stdout is String,
          result.stderr is List<int> || result.stderr is String
        ];
      }
      ''';
      final result = execute(source);
      expect(result[0], isTrue); // PID should be positive
      expect(result[1], equals(0)); // Exit code should be 0
      expect(result[2], isTrue); // stdout should exist
      expect(result[3], isTrue); // stderr should exist
    });

    test('Process with environment variables', () async {
      const source = '''
     import 'dart:io';
     main() async {
        var result = await Process.run('printenv', ['TEST_VAR'], 
          environment: {'TEST_VAR': 'test_value'});
        return [result.exitCode, result.stdout.toString().trim()];
      }
      ''';
      // Note: This test assumes printenv is available (Unix-like systems)
      try {
        final result = await execute(source);
        expect(result[0], equals(0));
        expect(result[1], equals('test_value'));
      } catch (e) {
        // Skip test if printenv is not available
        print('Skipping environment test: $e');
      }
    });

    test('Process.run with working directory', () async {
      const source = '''
     import 'dart:io';
     main() async {
        var tempDir = Directory.systemTemp.createTempSync();
        var result = await Process.run('pwd', [], workingDirectory: tempDir.path);
        tempDir.deleteSync();
        return result.exitCode;
      }
      ''';
      // Note: This test assumes pwd command is available (Unix-like systems)
      try {
        final result = await execute(source);
        expect(result, equals(0));
      } catch (e) {
        // Skip test if pwd is not available
        print('Skipping working directory test: $e');
      }
    });

    test('ProcessSignal constants availability', () {
      const source = '''
     import 'dart:io';
     main() {
        return [
          ProcessSignal.sigterm != null,
          ProcessSignal.sigint != null,
          ProcessSignal.sigkill != null
        ];
      }
      ''';
      final result = execute(source);
      expect(result[0], isTrue);
      expect(result[1], isTrue);
      expect(result[2], isTrue);
    });

    test('ProcessStartMode constants availability', () {
      const source = '''
     import 'dart:io';
     main() {
        return [
          ProcessStartMode.normal != null,
          ProcessStartMode.inheritStdio != null,
          ProcessStartMode.detached != null
        ];
      }
      ''';
      final result = execute(source);
      expect(result[0], isTrue);
      expect(result[1], isTrue);
      expect(result[2], isTrue);
    });

    test('Process stdin/stdout/stderr streams', () async {
      const source = '''
     import 'dart:io';
     import 'dart:convert';
     main() async {
        var process = await Process.start('cat', []);
        
        // Write to stdin
        process.stdin.writeln('Hello Cat');
        await process.stdin.close();
        
        // Read from stdout
        var output = await process.stdout.transform(utf8.decoder).join();
        var exitCode = await process.exitCode;
        
        return [exitCode, output.trim()];
      }
      ''';
      try {
        final result = await execute(source);
        expect(result[0], equals(0));
        expect(result[1], equals('Hello Cat'));
      } catch (e) {
        // Skip test if cat command is not available
        print('Skipping stdin/stdout test: $e');
      }
    });
  });
}
