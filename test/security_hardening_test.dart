import 'dart:io' as io;

import 'package:d4rt/d4rt.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Permission identity', () {
    test('equivalent filesystem permissions can be checked and revoked', () {
      final d4rt = D4rt();
      d4rt.grant(FilesystemPermission.readPath('/tmp/d4rt-scope'));

      expect(
        d4rt.hasPermission(FilesystemPermission.readPath('/tmp/d4rt-scope')),
        isTrue,
      );

      d4rt.revoke(FilesystemPermission.readPath('/tmp/d4rt-scope'));

      expect(
        d4rt.hasPermission(FilesystemPermission.readPath('/tmp/d4rt-scope')),
        isFalse,
      );
    });

    test('scoped network permissions fail closed without a host or port', () {
      final hostOnly = NetworkPermission.connectTo('example.com');
      expect(hostOnly.allows({'type': 'network', 'connect': true}), isFalse);
      expect(
        hostOnly.allows({
          'type': 'network',
          'connect': true,
          'host': 'example.com',
        }),
        isTrue,
      );

      final hostAndPort = NetworkPermission.connectToPort('example.com', 443);
      expect(
        hostAndPort.allows({
          'type': 'network',
          'connect': true,
          'host': 'example.com',
        }),
        isFalse,
      );
      expect(
        hostAndPort.allows({
          'type': 'network',
          'connect': true,
          'host': 'example.com',
          'port': 443,
        }),
        isTrue,
      );
    });

    test('bind and listen permissions cover server operations', () {
      expect(
        NetworkPermission.bind.allows({
          'type': 'network',
          'bind': true,
          'host': '127.0.0.1',
          'port': 0,
        }),
        isTrue,
      );
      expect(
        NetworkPermission.listenOn(8080).allows({
          'type': 'network',
          'listen': true,
          'host': '127.0.0.1',
          'port': 8080,
        }),
        isTrue,
      );
      expect(
        NetworkPermission.listenOn(8080).allows({
          'type': 'network',
          'listen': true,
          'host': '127.0.0.1',
          'port': 8081,
        }),
        isFalse,
      );
    });

    test('command-scoped process permissions accept basenames', () {
      final permission = ProcessRunPermission.command('echo');

      expect(
        permission.allows({
          'type': 'process',
          'command': '/bin/echo',
          'args': ['hello'],
        }),
        isTrue,
      );
      expect(
        permission.allows({
          'type': 'process',
          'command': '/bin/sh',
          'args': ['-c', 'echo hello'],
        }),
        isFalse,
      );
    });

    test('absolute process paths do not authorize same-named binaries', () {
      final permission = ProcessRunPermission.command('/usr/bin/git');

      expect(
        permission.allows({
          'type': 'process',
          'command': '/usr/bin/git',
          'args': ['status'],
        }),
        isTrue,
      );
      expect(
        permission.allows({
          'type': 'process',
          'command': '/tmp/git',
          'args': ['status'],
        }),
        isFalse,
      );
    });

    test('filesystem root scopes include their descendants', () {
      expect(
        FilesystemPermission.path(
          '/',
        ).allows({'type': 'filesystem', 'path': '/tmp/d4rt', 'read': true}),
        isTrue,
      );
    });
  });

  group('Network enforcement', () {
    test('HttpClient methods require a network permission', () {
      final d4rt = D4rt()..grant(FilesystemPermission.any);

      expect(
        () => d4rt.execute(
          source: '''
          import 'dart:io';
          void main() {
            HttpClient().getUrl(Uri.parse('http://127.0.0.1:9/'));
          }
        ''',
        ),
        throwsA(
          isA<RuntimeError>().having(
            (e) => e.message,
            'message',
            contains('Network permission denied'),
          ),
        ),
      );
    });

    test('server sockets require a network permission', () {
      final d4rt = D4rt()..grant(FilesystemPermission.any);

      expect(
        () => d4rt.execute(
          source: '''
          import 'dart:io';
          void main() {
            ServerSocket.bind('127.0.0.1', 0);
          }
        ''',
        ),
        throwsA(
          isA<RuntimeError>().having(
            (e) => e.message,
            'message',
            contains('Network permission denied'),
          ),
        ),
      );
    });

    test('outbound sockets require a network permission', () {
      final d4rt = D4rt()..grant(FilesystemPermission.any);

      expect(
        () => d4rt.execute(
          source: '''
          import 'dart:io';
          void main() {
            Socket.connect('127.0.0.1', 9);
          }
        ''',
        ),
        throwsA(
          isA<RuntimeError>().having(
            (e) => e.message,
            'message',
            contains('Network permission denied'),
          ),
        ),
      );
    });

    test('HTTP proxy endpoints require network permission', () async {
      final d4rt = D4rt()
        ..grant(FilesystemPermission.any)
        ..grant(NetworkPermission.connectTo('example.com'));

      await expectLater(
        Future(
          () => d4rt.execute(
            source: '''
            import 'dart:io';
            Future<void> main() async {
              final client = HttpClient();
              client.findProxy = (uri) => 'PROXY 127.0.0.1:18080';
              final request = await client.getUrl(
                Uri.parse('http://example.com/'),
              );
              await request.close();
            }
          ''',
          ),
        ),
        throwsA(
          isA<RuntimeError>().having(
            (e) => e.message,
            'message',
            contains('connect to proxy'),
          ),
        ),
      );
    });

    test('scoped network permissions disable transparent redirects', () async {
      final d4rt = D4rt()
        ..grant(FilesystemPermission.any)
        ..grant(NetworkPermission.connectTo('example.com'));

      final result = await d4rt.execute(
        source: '''
        import 'dart:io';
        Future<bool> main() async {
          final request = await HttpClient().getUrl(
            Uri.parse('http://example.com/'),
          );
          return request.followRedirects;
        }
      ''',
      );

      expect(result, isFalse);
    });

    test(
      'unrestricted network permissions allow transparent redirects',
      () async {
        final d4rt = D4rt()
          ..grant(FilesystemPermission.any)
          ..grant(NetworkPermission.any);

        final result = await d4rt.execute(
          source: '''
        import 'dart:io';
        Future<bool> main() async {
          final request = await HttpClient().getUrl(
            Uri.parse('http://example.com/'),
          );
          return request.followRedirects;
        }
      ''',
        );

        expect(result, isTrue);
      },
    );
  });

  group('Filesystem canonicalization', () {
    test('symlinks cannot escape a readPath scope', () {
      final root = io.Directory.systemTemp.createTempSync('d4rt-symlink-');
      final allowed = io.Directory(p.join(root.path, 'allowed'))..createSync();
      final outside = io.Directory(p.join(root.path, 'outside'))..createSync();
      final secret = io.File(p.join(outside.path, 'secret.txt'))
        ..writeAsStringSync('secret');
      io.Link(p.join(allowed.path, 'escape')).createSync(outside.path);

      try {
        final d4rt = D4rt()..grant(FilesystemPermission.readPath(allowed.path));
        final escapedPath = p.join(allowed.path, 'escape', 'secret.txt');

        expect(
          () => d4rt.execute(
            source:
                '''
            import 'dart:io';
            String main() => File(${_dartString(escapedPath)}).readAsStringSync();
          ''',
          ),
          throwsA(
            isA<RuntimeError>().having(
              (e) => e.message,
              'message',
              contains('Filesystem permission denied'),
            ),
          ),
        );
      } finally {
        if (secret.existsSync()) secret.deleteSync();
        if (outside.existsSync()) outside.deleteSync(recursive: true);
        if (allowed.existsSync()) allowed.deleteSync(recursive: true);
        if (root.existsSync()) root.deleteSync(recursive: true);
      }
    });

    test('writes through broken symlinks cannot escape a scope', () {
      final root = io.Directory.systemTemp.createTempSync('d4rt-broken-');
      final allowed = io.Directory(p.join(root.path, 'allowed'))..createSync();
      final outside = io.Directory(p.join(root.path, 'outside'))..createSync();
      final escapedTarget = p.join(outside.path, 'created.txt');
      final linkPath = p.join(allowed.path, 'escape');
      io.Link(linkPath).createSync(escapedTarget);

      try {
        final d4rt = D4rt()
          ..grant(FilesystemPermission.writePath(allowed.path));

        expect(
          () => d4rt.execute(
            source:
                '''
            import 'dart:io';
            void main() {
              File(${_dartString(linkPath)}).writeAsStringSync('escaped');
            }
          ''',
          ),
          throwsA(
            isA<RuntimeError>().having(
              (e) => e.message,
              'message',
              contains('Filesystem permission denied'),
            ),
          ),
        );
        expect(io.File(escapedTarget).existsSync(), isFalse);
      } finally {
        if (outside.existsSync()) outside.deleteSync(recursive: true);
        if (allowed.existsSync()) allowed.deleteSync(recursive: true);
        if (root.existsSync()) root.deleteSync(recursive: true);
      }
    });

    test('symlinks cannot target paths outside a write scope', () {
      final root = io.Directory.systemTemp.createTempSync('d4rt-link-');
      final allowed = io.Directory(p.join(root.path, 'allowed'))..createSync();
      final outside = io.Directory(p.join(root.path, 'outside'))..createSync();
      final linkPath = p.join(allowed.path, 'escape');

      try {
        final d4rt = D4rt()
          ..grant(FilesystemPermission.writePath(allowed.path));

        expect(
          () => d4rt.execute(
            source:
                '''
            import 'dart:io';
            void main() {
              Link(${_dartString(linkPath)}).createSync(
                ${_dartString(p.join(outside.path, 'target.txt'))},
              );
            }
          ''',
          ),
          throwsA(
            isA<RuntimeError>().having(
              (e) => e.message,
              'message',
              contains('Filesystem permission denied'),
            ),
          ),
        );
        expect(io.Link(linkPath).existsSync(), isFalse);
      } finally {
        if (outside.existsSync()) outside.deleteSync(recursive: true);
        if (allowed.existsSync()) allowed.deleteSync(recursive: true);
        if (root.existsSync()) root.deleteSync(recursive: true);
      }
    });

    test('resolving a symlink cannot reveal an out-of-scope target', () {
      final root = io.Directory.systemTemp.createTempSync('d4rt-resolve-');
      final allowed = io.Directory(p.join(root.path, 'allowed'))..createSync();
      final outside = io.Directory(p.join(root.path, 'outside'))..createSync();
      final secret = io.File(p.join(outside.path, 'secret.txt'))
        ..writeAsStringSync('secret');
      final linkPath = p.join(allowed.path, 'escape');
      io.Link(linkPath).createSync(secret.path);

      try {
        final d4rt = D4rt()..grant(FilesystemPermission.readPath(allowed.path));

        expect(
          () => d4rt.execute(
            source:
                '''
            import 'dart:io';
            String main() =>
                File(${_dartString(linkPath)}).resolveSymbolicLinksSync();
          ''',
          ),
          throwsA(
            isA<RuntimeError>().having(
              (e) => e.message,
              'message',
              contains('Filesystem permission denied'),
            ),
          ),
        );
      } finally {
        if (outside.existsSync()) outside.deleteSync(recursive: true);
        if (allowed.existsSync()) allowed.deleteSync(recursive: true);
        if (root.existsSync()) root.deleteSync(recursive: true);
      }
    });

    test('directory listings cannot traverse symlinks outside a scope', () {
      final root = io.Directory.systemTemp.createTempSync('d4rt-list-');
      final allowed = io.Directory(p.join(root.path, 'allowed'))..createSync();
      final outside = io.Directory(p.join(root.path, 'outside'))..createSync();
      io.File(p.join(outside.path, 'secret.txt')).writeAsStringSync('secret');
      io.Link(p.join(allowed.path, 'escape')).createSync(outside.path);

      try {
        final d4rt = D4rt()..grant(FilesystemPermission.readPath(allowed.path));

        expect(
          () => d4rt.execute(
            source:
                '''
            import 'dart:io';
            int main() =>
                Directory(${_dartString(allowed.path)})
                    .listSync(recursive: true)
                    .length;
          ''',
          ),
          throwsA(
            isA<RuntimeError>().having(
              (e) => e.message,
              'message',
              contains('Filesystem permission denied'),
            ),
          ),
        );
      } finally {
        if (outside.existsSync()) outside.deleteSync(recursive: true);
        if (allowed.existsSync()) allowed.deleteSync(recursive: true);
        if (root.existsSync()) root.deleteSync(recursive: true);
      }
    });
  });

  group('Analysis and evaluation isolation', () {
    test('analyze does not execute initializers', () {
      var called = false;
      final d4rt = D4rt();
      d4rt.registertopLevelFunction('sideEffect', (
        visitor,
        arguments,
        namedArguments,
        typeArguments,
      ) {
        called = true;
        return 1;
      }, signature: 'int sideEffect()');

      final result = d4rt.analyze(
        source: '''
        import 'package:test/imported.dart';
        final value = sideEffect();
        class Holder {
          static final value = sideEffect();
        }
        void main() {}
      ''',
        sources: {
          'package:test/imported.dart': '''
            final importedValue = sideEffect();
          ''',
        },
      );

      expect(called, isFalse);
      expect(result.variables.map((v) => v.name), contains('value'));
      expect(
        result.classes.firstWhere((c) => c.name == 'Holder').fields,
        contains('value'),
      );
    });

    test('eval requires DangerousPermission.codeEvaluation', () {
      final d4rt = D4rt();
      d4rt.execute(source: 'void main() {}');

      expect(
        () => d4rt.eval('1 + 1'),
        throwsA(
          isA<RuntimeError>().having(
            (e) => e.message,
            'message',
            contains('DangerousPermission.codeEvaluation'),
          ),
        ),
      );

      d4rt.grant(DangerousPermission.codeEvaluation);
      expect(d4rt.eval('1 + 1'), equals(2));
    });

    test('dart:developer requires DangerousPermission.developerTools', () {
      final d4rt = D4rt();

      expect(
        () => d4rt.execute(
          source: '''
          import 'dart:developer';
          void main() {}
        ''',
        ),
        throwsA(
          isA<RuntimeError>().having(
            (e) => e.message,
            'message',
            contains('DangerousPermission.developerTools'),
          ),
        ),
      );

      d4rt.grant(DangerousPermission.developerTools);
      expect(
        () => d4rt.execute(
          source: '''
          import 'dart:developer';
          void main() {
            debugger(when: false);
          }
        ''',
        ),
        returnsNormally,
      );
    });

    test('dart:developer bridges recheck permissions at runtime', () {
      final d4rt = D4rt()..grant(DangerousPermission.developerTools);
      d4rt.registertopLevelFunction('revokeDeveloper', (
        visitor,
        arguments,
        namedArguments,
        typeArguments,
      ) {
        d4rt.revoke(DangerousPermission.developerTools);
        return null;
      });

      expect(
        () => d4rt.execute(
          source: '''
          import 'dart:developer';
          void main() {
            final tag = UserTag('revoked');
            revokeDeveloper();
            tag.makeCurrent();
          }
        ''',
        ),
        throwsA(
          isA<RuntimeError>().having(
            (e) => e.message,
            'message',
            contains('DangerousPermission.developerTools'),
          ),
        ),
      );
    });

    test('isolate permissions separate spawning from communication', () {
      final communicateOnly = D4rt()..grant(IsolatePermission.communicate);
      expect(
        () => communicateOnly.execute(
          source: '''
          import 'dart:isolate';
          void main() {
            Isolate.run(() => 1);
          }
        ''',
        ),
        throwsA(
          isA<RuntimeError>().having(
            (e) => e.message,
            'message',
            contains('IsolatePermission.spawn'),
          ),
        ),
      );

      final spawnOnly = D4rt()..grant(IsolatePermission.spawn);
      expect(
        () => spawnOnly.execute(
          source: '''
          import 'dart:isolate';
          void main() {
            ReceivePort();
          }
        ''',
        ),
        throwsA(
          isA<RuntimeError>().having(
            (e) => e.message,
            'message',
            contains('IsolatePermission.communicate'),
          ),
        ),
      );
    });

    test('stdlib permission checks ignore URI suffixes', () {
      final d4rt = D4rt();

      for (final uri in ['dart:io?bypass', 'dart:io#bypass']) {
        expect(
          () => d4rt.execute(
            source:
                '''
            import '$uri';
            void main() {}
          ''',
          ),
          throwsA(
            isA<RuntimeError>().having(
              (e) => e.message,
              'message',
              contains('FilesystemPermission'),
            ),
          ),
        );
      }

      expect(
        () => d4rt.execute(
          source: '''
          import 'dart:isolate?bypass';
          void main() {}
        ''',
        ),
        throwsA(
          isA<RuntimeError>().having(
            (e) => e.message,
            'message',
            contains('IsolatePermission'),
          ),
        ),
      );

      expect(
        () => d4rt.execute(
          source: '''
          import 'dart:developer?bypass';
          void main() {}
        ''',
        ),
        throwsA(
          isA<RuntimeError>().having(
            (e) => e.message,
            'message',
            contains('DangerousPermission.developerTools'),
          ),
        ),
      );
    });

    test('missing modules are rejected even when other bridges exist', () {
      final d4rt = D4rt();
      d4rt.registerBridgedClass(
        BridgedClass(nativeType: String, name: 'ExistingBridge'),
        'package:existing/existing.dart',
      );

      expect(
        () => d4rt.execute(
          source: '''
          import 'package:missing/missing.dart';
          void main() {}
        ''',
        ),
        throwsA(isA<SourceCodeException>()),
      );
    });

    test('module initializers honor maxSteps', () {
      final d4rt = D4rt();

      expect(
        () => d4rt.execute(
          library: 'package:test/main.dart',
          sources: {
            'package:test/main.dart': '''
              import 'mod.dart';
              void main() {}
            ''',
            'package:test/mod.dart': '''
              int spin() {
                while (true) {}
              }
              final value = spin();
            ''',
          },
          maxSteps: 100,
        ),
        throwsA(isA<ExecutionLimitException>()),
      );
    });
  });
}

String _dartString(String value) {
  return "'${value.replaceAll('\\', '\\\\').replaceAll("'", "\\'")}'";
}
