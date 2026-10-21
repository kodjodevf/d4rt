import 'dart:io' as io;

import 'package:d4rt/d4rt.dart';
import 'package:d4rt/src/stdlib/io/secure_file_opener.dart';
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

  group('Host capability enforcement', () {
    test('Isolate.spawnUri requires dangerous code evaluation permission', () {
      final d4rt = D4rt()..grant(IsolatePermission.any);

      expect(
        () => d4rt.execute(
          source: '''
          import 'dart:isolate';
          void main() {
            Isolate.spawnUri(Uri.file('/tmp/d4rt-missing.dart'), [], null);
          }
        ''',
        ),
        throwsA(
          isA<RuntimeError>().having(
            (e) => e.message,
            'message',
            contains('DangerousPermission.codeEvaluation'),
          ),
        ),
      );
    });

    test('native process execution requires dangerous process permission', () {
      final d4rt = D4rt()
        ..grant(FilesystemPermission.read)
        ..grant(ProcessRunPermission.any);

      expect(
        () => d4rt.execute(
          source: '''
          import 'dart:io';
          void main() {
            Process.runSync('echo', ['should-not-run']);
          }
        ''',
        ),
        throwsA(
          isA<RuntimeError>().having(
            (e) => e.message,
            'message',
            contains('DangerousPermission.processExecution'),
          ),
        ),
      );
    });

    test('runInShell requires unrestricted process permission', () {
      final d4rt = D4rt()
        ..grant(FilesystemPermission.read)
        ..grant(ProcessRunPermission.command('echo'))
        ..grant(DangerousPermission.processExecution);

      expect(
        () => d4rt.execute(
          source: '''
          import 'dart:io';
          void main() {
            Process.runSync('echo', ['x'], runInShell: true);
          }
        ''',
        ),
        throwsA(
          isA<RuntimeError>().having(
            (e) => e.message,
            'message',
            contains('ProcessRunPermission.any'),
          ),
        ),
      );
    });

    test('ProcessSignal.watch requires unrestricted process permission', () {
      final d4rt = D4rt()
        ..grant(FilesystemPermission.read)
        ..grant(ProcessRunPermission.command('echo'));

      expect(
        () => d4rt.execute(
          source: '''
          import 'dart:io';
          void main() {
            ProcessSignal.sigint.watch();
          }
        ''',
        ),
        throwsA(
          isA<RuntimeError>().having(
            (e) => e.message,
            'message',
            contains('Process signal handling denied'),
          ),
        ),
      );
    });

    test('ProcessSignal.watch also requires dangerous process permission', () {
      final d4rt = D4rt()
        ..grant(FilesystemPermission.read)
        ..grant(ProcessRunPermission.any);

      expect(
        () => d4rt.execute(
          source: '''
          import 'dart:io';
          void main() {
            ProcessSignal.sigint.watch();
          }
        ''',
        ),
        throwsA(
          isA<RuntimeError>().having(
            (e) => e.message,
            'message',
            contains('DangerousPermission.processExecution'),
          ),
        ),
      );
    });
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

    test(
      'reading link targets requires access to both link and target',
      () async {
        final root = io.Directory.systemTemp.createTempSync('d4rt-link-read-');
        final allowed = io.Directory(p.join(root.path, 'allowed'))
          ..createSync();
        final outside = io.Directory(p.join(root.path, 'outside'))
          ..createSync();
        final insideTarget = io.File(p.join(allowed.path, 'inside.txt'))
          ..writeAsStringSync('inside');
        final outsideTarget = io.File(p.join(outside.path, 'outside.txt'))
          ..writeAsStringSync('outside');
        final inward = io.Link(p.join(outside.path, 'inward'))
          ..createSync(insideTarget.path);
        final outward = io.Link(p.join(allowed.path, 'outward'))
          ..createSync(outsideTarget.path);
        final internal = io.Link(p.join(allowed.path, 'internal'))
          ..createSync(insideTarget.path);

        try {
          final d4rt = D4rt()
            ..grant(FilesystemPermission.readPath(allowed.path));

          final target = await d4rt.execute(
            source:
                '''
            import 'dart:io';
            Future<String> main() async =>
                Link(${_dartString(internal.path)}).target();
          ''',
          );
          expect(target, insideTarget.path);

          for (final path in [inward.path, outward.path]) {
            expect(
              () => d4rt.execute(
                source:
                    '''
              import 'dart:io';
              String main() => Link(${_dartString(path)}).targetSync();
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
          }
        } finally {
          if (root.existsSync()) root.deleteSync(recursive: true);
        }
      },
    );

    test('FileStat static methods enforce read permissions', () async {
      final root = io.Directory.systemTemp.createTempSync('d4rt-stat-');
      final allowed = io.Directory(p.join(root.path, 'allowed'))..createSync();
      final outside = io.Directory(p.join(root.path, 'outside'))..createSync();
      final inside = io.File(p.join(allowed.path, 'inside.txt'))
        ..writeAsStringSync('inside');
      final secret = io.File(p.join(outside.path, 'secret.txt'))
        ..writeAsStringSync('secret');

      try {
        final d4rt = D4rt()..grant(FilesystemPermission.readPath(allowed.path));

        expect(
          () => d4rt.execute(
            source:
                '''
              import 'dart:io';
              void main() {
                FileStat.statSync(${_dartString(secret.path)});
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

        await expectLater(
          d4rt.execute(
            source:
                '''
              import 'dart:io';
              Future<void> main() async {
                await FileStat.stat(${_dartString(secret.path)});
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

        final size = await d4rt.execute(
          source:
              '''
            import 'dart:io';
            int main() => FileStat.statSync(${_dartString(inside.path)}).size;
          ''',
        );
        expect(size, inside.lengthSync());
      } finally {
        if (root.existsSync()) root.deleteSync(recursive: true);
      }
    });

    test(
      'instance stat and existence checks use descriptor-backed metadata',
      () async {
        final root = io.Directory.systemTemp.createTempSync(
          'd4rt-stat-instance-',
        );
        final allowed = io.Directory(p.join(root.path, 'allowed'))
          ..createSync();
        final file = io.File(p.join(allowed.path, 'inside.txt'))
          ..writeAsStringSync('hello');
        final directory = io.Directory(p.join(allowed.path, 'child'))
          ..createSync();
        final link = io.Link(p.join(allowed.path, 'link'))
          ..createSync(file.path);

        try {
          final d4rt = D4rt()
            ..grant(FilesystemPermission.readPath(allowed.path));
          final result = await d4rt.execute(
            source:
                '''
            import 'dart:io';
            Future<bool> main() async {
              final file = File(${_dartString(file.path)});
              final directory = Directory(${_dartString(directory.path)});
              final link = Link(${_dartString(link.path)});
              final asyncStat = await file.stat();
              final fileStat = await FileStat.stat(${_dartString(file.path)});
              return file.existsSync() &&
                  directory.existsSync() &&
                  !File(${_dartString(directory.path)}).existsSync() &&
                  !Directory(${_dartString(file.path)}).existsSync() &&
                  await file.exists() &&
                  await directory.exists() &&
                  file.statSync().size == 5 &&
                  asyncStat.size == 5 &&
                  fileStat.size == 5 &&
                  directory.statSync().size >= 0 &&
                  link.statSync().size == 5 &&
                  FileStat.statSync(${_dartString(file.path)}).size == 5;
            }
          ''',
          );
          expect(result, isTrue);
        } finally {
          if (root.existsSync()) root.deleteSync(recursive: true);
        }
      },
    );

    test('temporary directory prefixes cannot escape a write scope', () {
      final root = io.Directory.systemTemp.createTempSync('d4rt-temp-');
      final allowed = io.Directory(p.join(root.path, 'allowed'))..createSync();
      final outside = io.Directory(p.join(root.path, 'outside'))..createSync();

      try {
        final d4rt = D4rt()
          ..grant(FilesystemPermission.writePath(allowed.path));

        for (final prefix in [
          '../outside/escape',
          p.join(outside.path, 'absolute'),
        ]) {
          expect(
            () => d4rt.execute(
              source:
                  '''
              import 'dart:io';
              void main() {
                Directory(${_dartString(allowed.path)}).createTempSync(
                  ${_dartString(prefix)},
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
        }
        expect(outside.listSync(), isEmpty);
      } finally {
        if (outside.existsSync()) outside.deleteSync(recursive: true);
        if (allowed.existsSync()) allowed.deleteSync(recursive: true);
        if (root.existsSync()) root.deleteSync(recursive: true);
      }
    });

    test(
      'descriptor opener rejects symlinks introduced after canonicalization',
      () {
        final root = io.Directory.systemTemp.createTempSync('d4rt-fd-race-');
        final allowed = io.Directory(p.join(root.path, 'allowed'))
          ..createSync();
        final outside = io.Directory(p.join(root.path, 'outside'))
          ..createSync();
        final outsideFile = io.File(p.join(outside.path, 'secret.txt'))
          ..writeAsStringSync('secret');

        try {
          final canonicalAllowed = allowed.resolveSymbolicLinksSync();
          final finalLink = io.Link(p.join(allowed.path, 'escape'))
            ..createSync(outsideFile.path);
          final parentLink = io.Link(p.join(allowed.path, 'parent'))
            ..createSync(outside.path);
          final insideFile = io.File(p.join(allowed.path, 'inside.txt'))
            ..writeAsStringSync('inside');

          expect(
            () => SecureFileOpener.openRead(
              p.join(canonicalAllowed, p.basename(finalLink.path)),
            ),
            throwsA(isA<io.FileSystemException>()),
          );
          expect(
            () => SecureFileOpener.openRead(
              p.join(
                canonicalAllowed,
                p.basename(parentLink.path),
                p.basename(outsideFile.path),
              ),
            ),
            throwsA(isA<io.FileSystemException>()),
          );

          final escapedStat = SecureFileOpener.stat(
            p.join(canonicalAllowed, p.basename(finalLink.path)),
          );
          expect(escapedStat?.type, io.FileSystemEntityType.notFound);
          expect(
            SecureFileOpener.existsAs(
              p.join(canonicalAllowed, p.basename(finalLink.path)),
              io.FileSystemEntityType.file,
            ),
            isFalse,
          );
          expect(
            SecureFileOpener.stat(
              p.join(
                canonicalAllowed,
                p.basename(parentLink.path),
                p.basename(outsideFile.path),
              ),
            )?.type,
            io.FileSystemEntityType.notFound,
          );

          final handle = SecureFileOpener.openRead(
            p.join(canonicalAllowed, p.basename(insideFile.path)),
          );
          expect(handle, isNotNull);
          expect(io.File(handle!.path).readAsStringSync(), 'inside');
          handle.close();

          final insideStat = SecureFileOpener.stat(
            p.join(canonicalAllowed, p.basename(insideFile.path)),
          );
          expect(insideStat?.type, io.FileSystemEntityType.file);
          expect(insideStat?.size, 6);
        } finally {
          if (root.existsSync()) root.deleteSync(recursive: true);
        }
      },
      skip: !SecureFileOpener.isSupported,
    );

    test(
      'descriptor namespace operations reject symlink parents and preserve targets',
      () {
        final root = io.Directory.systemTemp.createTempSync('d4rt-fd-ns-');
        final allowed = io.Directory(p.join(root.path, 'allowed'))
          ..createSync();
        final outside = io.Directory(p.join(root.path, 'outside'))
          ..createSync();

        try {
          final canonicalAllowed = allowed.resolveSymbolicLinksSync();
          final outsideFile = io.File(p.join(outside.path, 'secret.txt'))
            ..writeAsStringSync('secret');
          final outsideDir = io.Directory(p.join(outside.path, 'dir'))
            ..createSync();
          final escapeParent = io.Link(p.join(allowed.path, 'escape'))
            ..createSync(outside.path);

          expect(
            () => SecureFileOpener.createFile(
              p.join(
                canonicalAllowed,
                p.basename(escapeParent.path),
                'pwn.txt',
              ),
            ),
            throwsA(isA<io.FileSystemException>()),
          );
          expect(
            io.File(p.join(outside.path, 'pwn.txt')).existsSync(),
            isFalse,
          );

          final canonicalOutsideDir = outsideDir.resolveSymbolicLinksSync();
          final linkToDir = io.Link(p.join(allowed.path, 'link-to-dir'))
            ..createSync(canonicalOutsideDir);
          SecureFileOpener.deleteDirectory(
            p.join(canonicalAllowed, p.basename(linkToDir.path)),
          );
          expect(linkToDir.existsSync(), isFalse);
          expect(outsideDir.existsSync(), isTrue);
          expect(outsideFile.existsSync(), isTrue);

          final tree = io.Directory(p.join(allowed.path, 'tree'))..createSync();
          final nested = io.Directory(p.join(tree.path, 'nested'))
            ..createSync();
          io.File(p.join(nested.path, 'data.txt')).writeAsStringSync('data');
          io.Link(
            p.join(tree.path, 'outside-link'),
          ).createSync(outsideFile.path);
          SecureFileOpener.deletePathRecursive(
            p.join(canonicalAllowed, p.basename(tree.path)),
          );
          expect(tree.existsSync(), isFalse);
          expect(outsideFile.existsSync(), isTrue);
        } finally {
          if (root.existsSync()) root.deleteSync(recursive: true);
        }
      },
      skip: !SecureFileOpener.isSupported,
    );

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
