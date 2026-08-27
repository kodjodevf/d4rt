import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('CLI options tests', () {
    test('d4rt --version prints 0.2.3', () {
      final result = Process.runSync(
        Platform.executable,
        ['bin/d4rt.dart', '--version'],
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout.toString().trim(), contains('d4rt version 0.2.3'));
    });

    test('d4rt --help prints usage', () {
      final result = Process.runSync(
        Platform.executable,
        ['bin/d4rt.dart', '--help'],
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('Usage:'));
      expect(result.stdout.toString(), contains('--eval'));
      expect(result.stdout.toString(), contains('--introspection'));
    });

    test('d4rt -e evaluates code directly', () {
      final result = Process.runSync(
        Platform.executable,
        ['bin/d4rt.dart', '-e', 'print("CLI Direct Output: " + (50 * 2).toString());'],
      );

      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('CLI Direct Output: 100'));
    });
  });
}
