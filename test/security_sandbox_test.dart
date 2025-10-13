import 'dart:io' as io;
import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('Security Sandboxing', () {
    // Cleanup files after each test
    tearDown(() {
      final testFiles = ['test.txt', 'data.txt'];
      for (final fileName in testFiles) {
        final file = io.File(fileName);
        if (file.existsSync()) {
          file.deleteSync();
        }
      }
    });
    test('Blocks access to dart:io without permission', () {
      final interpreter = D4rt();

      expect(() {
        interpreter.execute(source: '''
          import 'dart:io';
          void main() {
            File('test.txt').existsSync();
          }
        ''');
      },
          throwsA(isA<RuntimeError>().having((e) => e.message, 'message',
              contains('dart:io requires FilesystemPermission'))));
    });

    test('Blocks access to dart:isolate without permission', () {
      final interpreter = D4rt();

      expect(() {
        interpreter.execute(source: '''
          import 'dart:isolate';
          void main() {
            Isolate.spawnUri(Uri.parse('dummy.dart'), [], null);
          }
        ''');
      },
          throwsA(isA<RuntimeError>().having((e) => e.message, 'message',
              contains('dart:isolate requires IsolatePermission'))));
    });

    test('Allows access to dart:io with permission', () {
      final interpreter = D4rt();
      interpreter.grant(FilesystemPermission.any);

      expect(() {
        interpreter.execute(source: '''
          import 'dart:io';
          void main() {
            bool exists = File('test.txt').existsSync();
            Directory('.').listSync();
          }
        ''');
        // Should not throw an error
      }, returnsNormally);
    });

    test('Allows access to dart:isolate with permission', () {
      final interpreter = D4rt();
      interpreter.grant(IsolatePermission.any);

      expect(() {
        interpreter.execute(source: '''
          import 'dart:isolate';
          void main() {
            var capability = Capability();
          }
        ''');
        // Should not throw an error
      }, returnsNormally);
    });

    test('Permission methods work correctly', () {
      final interpreter = D4rt();

      // Initially no permissions
      expect(interpreter.hasPermission(FilesystemPermission.any), isFalse);

      // Grant permission
      interpreter.grant(FilesystemPermission.any);
      expect(interpreter.hasPermission(FilesystemPermission.any), isTrue);

      // Revoke permission
      interpreter.revoke(FilesystemPermission.any);
      expect(interpreter.hasPermission(FilesystemPermission.any), isFalse);
    });

    group('Specific Permissions', () {
      test('FilesystemPermission.path allows specific path access', () {
        final interpreter = D4rt();
        interpreter.grant(FilesystemPermission.path('/tmp'));

        expect(() {
          interpreter.execute(source: '''
            import 'dart:io';
            void main() {
              Directory('/tmp').existsSync();
            }
          ''');
        }, returnsNormally);
      });

      test('FilesystemPermission.read allows read operations', () {
        final interpreter = D4rt();
        interpreter.grant(FilesystemPermission.read);

        expect(() {
          interpreter.execute(source: '''
            import 'dart:io';
            void main() {
              Directory('/tmp').existsSync();
            }
          ''');
        }, returnsNormally);
      });

      test('FilesystemPermission.write allows write operations', () {
        final interpreter = D4rt();
        interpreter.grant(FilesystemPermission.write);

        expect(() {
          interpreter.execute(source: '''
            import 'dart:io';
            void main() {
              File('test.txt').writeAsStringSync('test');
            }
          ''');
        }, returnsNormally);
      });

      test('ProcessRunPermission.command allows specific command', () {
        final interpreter = D4rt();
        interpreter.grant(ProcessRunPermission.command('ls'));
        interpreter
            .grant(FilesystemPermission.any); // Process needs filesystem access

        expect(() {
          interpreter.execute(source: '''
            import 'dart:io';
            void main() {
              Process.runSync('echo', ['hello']);
            }
          ''');
        }, returnsNormally);
      });

      test('NetworkPermission.connect allows specific host', () {
        final interpreter = D4rt();
        interpreter.grant(NetworkPermission.connectTo('localhost'));
        interpreter.grant(FilesystemPermission
            .any); // Network operations need filesystem access

        expect(() {
          interpreter.execute(source: '''
            import 'dart:io';
            void main() {
              InternetAddress.lookup('localhost');
            }
          ''');
        }, returnsNormally);
      });
    });

    group('Permission Combinations', () {
      test('Multiple filesystem permissions work together', () {
        final interpreter = D4rt();
        interpreter.grant(FilesystemPermission.read);
        interpreter.grant(
            FilesystemPermission.write); // Need write permission to create file
        interpreter.grant(FilesystemPermission.path('/tmp'));

        expect(() {
          interpreter.execute(source: '''
            import 'dart:io';
            void main() {
              File('test.txt').writeAsStringSync('test content');
              String content = File('test.txt').readAsStringSync();
              Directory('/tmp').existsSync();
            }
          ''');
        }, returnsNormally);
      });

      test('Mixed permission types work together', () {
        final interpreter = D4rt();
        interpreter.grant(FilesystemPermission.any);
        interpreter.grant(NetworkPermission.any);
        interpreter.grant(ProcessRunPermission.any);
        interpreter.grant(IsolatePermission.any);

        expect(() {
          interpreter.execute(source: '''
            import 'dart:io';
            import 'dart:isolate';
            void main() {
              File('test.txt').existsSync();
              var capability = Capability();
              Process.runSync('echo', ['hello']);
            }
          ''');
        }, returnsNormally);
      });

      test('Partial permissions allow limited access', () {
        // Create test file first
        io.File('test.txt').writeAsStringSync('test content');

        final interpreter = D4rt();
        interpreter.grant(FilesystemPermission.read);
        // Don't grant write permission

        expect(() {
          interpreter.execute(source: '''
            import 'dart:io';
            void main() {
              String content = File('test.txt').readAsStringSync();
            }
          ''');
        }, returnsNormally);
      });
    });

    group('Permission Revocation', () {
      test('Revoking specific permission blocks access', () {
        final interpreter = D4rt();
        interpreter.grant(FilesystemPermission.any);
        interpreter.revoke(FilesystemPermission.any);

        expect(() {
          interpreter.execute(source: '''
            import 'dart:io';
            void main() {
              File('test.txt').existsSync();
            }
          ''');
        },
            throwsA(isA<RuntimeError>().having((e) => e.message, 'message',
                contains('dart:io requires FilesystemPermission'))));
      });

      test('Revoking one permission keeps others active', () {
        final interpreter = D4rt();
        interpreter.grant(FilesystemPermission.any);
        interpreter.grant(NetworkPermission.any);
        interpreter.revoke(FilesystemPermission.any);

        // Network should still work
        expect(() {
          interpreter.execute(source: '''
            import 'dart:io';
            void main() {
              InternetAddress.lookup('localhost');
            }
          ''');
        },
            throwsA(isA<RuntimeError>().having((e) => e.message, 'message',
                contains('dart:io requires FilesystemPermission'))));
      });
    });

    group('Safe Modules', () {
      test('Safe modules work without permissions', () {
        final interpreter = D4rt();

        expect(() {
          interpreter.execute(source: '''
            import 'dart:core';
            import 'dart:math';
            import 'dart:collection';
            void main() {
              List<int> numbers = [1, 2, 3, 4, 5];
              numbers.sort();
              double sqrt = sqrt(16.0);
            }
          ''');
        }, returnsNormally);
      });

      test('Mixed safe and dangerous modules', () {
        final interpreter = D4rt();
        // Only grant permission for dangerous module
        interpreter.grant(FilesystemPermission.any);

        expect(() {
          interpreter.execute(source: '''
            import 'dart:core';
            import 'dart:math';
            import 'dart:io';
            void main() {
              List<int> numbers = [1, 2, 3, 4, 5];
              numbers.sort();
              double sqrt = sqrt(16.0);
              File('test.txt').existsSync();
            }
          ''');
        }, returnsNormally);
      });
    });

    group('Import Scenarios', () {
      test('Import with prefix works with permissions', () {
        final interpreter = D4rt();
        interpreter.grant(FilesystemPermission.any);

        expect(() {
          interpreter.execute(source: '''
            import 'dart:io';
            void main() {
              File('test.txt').writeAsStringSync('test');
            }
          ''');
        }, returnsNormally);
      });

      test('Import with show/hide works with permissions', () {
        final interpreter = D4rt();
        interpreter.grant(FilesystemPermission.any);

        expect(() {
          interpreter.execute(source: '''
            import 'dart:io' show File;
            void main() {
              File('test.txt').writeAsStringSync('test');
            }
          ''');
        }, returnsNormally);
      });

      test('Multiple imports require permissions for each dangerous module',
          () {
        final interpreter = D4rt();
        interpreter.grant(FilesystemPermission.any);
        // Don't grant isolate permission

        expect(() {
          interpreter.execute(source: '''
            import 'dart:io';
            import 'dart:isolate';
            void main() {
              File('test.txt').existsSync();
              Capability();
            }
          ''');
        },
            throwsA(isA<RuntimeError>().having((e) => e.message, 'message',
                contains('dart:isolate requires IsolatePermission'))));
      });
    });

    group('Complex Scenarios', () {
      test('Permission inheritance in module loading', () {
        final interpreter = D4rt();
        interpreter.grant(FilesystemPermission.any);

        expect(() {
          interpreter.execute(sources: {
            'package:main/main.dart': '''
              import 'dart:io';
              import 'package:main/utils.dart';
              void main() {
                File('test.txt').existsSync();
                helper();
              }
            ''',
            'package:main/utils.dart': '''
              import 'dart:io';
              void helper() {
                Directory('.').listSync();
              }
            '''
          }, library: 'package:main/main.dart');
        }, returnsNormally);
      });

      test('Permission checking with complex module structure', () {
        final interpreter = D4rt();
        interpreter.grant(FilesystemPermission.any);
        interpreter.grant(IsolatePermission.any);

        expect(() {
          interpreter.execute(sources: {
            'package:app/main.dart': '''
              import 'dart:io';
              import 'dart:isolate';
              void main() {
                File('data.txt').writeAsStringSync('data');
                var capability = Capability();
              }
            '''
          }, library: 'package:app/main.dart');
        }, returnsNormally);
      });
    });
  });
}
