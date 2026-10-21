import 'dart:io';
import 'dart:typed_data';
import 'package:d4rt/d4rt.dart';
import 'package:path/path.dart' as p;

import 'filesystem_permission_helper.dart';
import 'secure_file_opener.dart';

class DirectoryIo {
  static BridgedClass get definition => BridgedClass(
    nativeType: Directory,
    name: 'Directory',
    typeParameterCount: 0,
    isSubtypeOfFunc: (value) => value is Directory,
    constructors: {
      '': (visitor, positionalArgs, namedArgs) {
        if (positionalArgs.isEmpty || positionalArgs[0] is! String) {
          throw RuntimeError(
            'Directory constructor requires one String argument (path).',
          );
        }
        return Directory(positionalArgs[0] as String);
      },
    },
    staticMethods: {
      'fromRawPath': (visitor, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! Uint8List) {
          throw RuntimeError(
            'Directory.fromRawPath requires one Uint8List argument.',
          );
        }
        return Directory.fromRawPath(positionalArgs[0] as Uint8List);
      },
      'fromUri': (visitor, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! Uri) {
          throw RuntimeError('Directory.fromUri requires one Uri argument.');
        }
        return Directory.fromUri(positionalArgs[0] as Uri);
      },
    },
    methods: {
      'exists': (visitor, target, positionalArgs, namedArgs) {
        final directory = target as Directory;
        checkFilesystemReadPermission(
          visitor,
          directory.path,
          operation: 'check directory existence',
        );
        return directory.exists();
      },
      'existsSync': (visitor, target, positionalArgs, namedArgs) {
        final directory = target as Directory;
        checkFilesystemReadPermission(
          visitor,
          directory.path,
          operation: 'check directory existence',
        );
        return directory.existsSync();
      },
      'create': (visitor, target, positionalArgs, namedArgs) {
        final directory = target as Directory;
        final recursive = namedArgs['recursive'] as bool? ?? false;
        final targetInfo = checkFilesystemNamespaceWritePermission(
          visitor,
          directory.path,
          operation: 'create directory',
        );
        if (SecureFileOpener.isSupported) {
          SecureFileOpener.createDirectory(
            p.join(targetInfo.parent, targetInfo.name),
            recursive: recursive,
          );
          return Future<Directory>.value(directory);
        }
        return directory.create(recursive: recursive);
      },
      'createSync': (visitor, target, positionalArgs, namedArgs) {
        final directory = target as Directory;
        final recursive = namedArgs['recursive'] as bool? ?? false;
        final targetInfo = checkFilesystemNamespaceWritePermission(
          visitor,
          directory.path,
          operation: 'create directory',
        );
        if (SecureFileOpener.isSupported) {
          SecureFileOpener.createDirectory(
            p.join(targetInfo.parent, targetInfo.name),
            recursive: recursive,
          );
          return null;
        }
        directory.createSync(recursive: recursive);
        return null;
      },
      'delete': (visitor, target, positionalArgs, namedArgs) {
        final directory = target as Directory;
        final recursive = namedArgs['recursive'] as bool? ?? false;
        final targetInfo = checkFilesystemNamespaceWritePermission(
          visitor,
          directory.path,
          operation: 'delete directory',
        );
        if (SecureFileOpener.isSupported) {
          final securePath = p.join(targetInfo.parent, targetInfo.name);
          if (recursive) {
            SecureFileOpener.deletePathRecursive(securePath);
          } else {
            SecureFileOpener.deleteDirectory(securePath);
          }
          return Future<Directory>.value(directory);
        }
        return directory.delete(recursive: recursive);
      },
      'deleteSync': (visitor, target, positionalArgs, namedArgs) {
        final directory = target as Directory;
        final recursive = namedArgs['recursive'] as bool? ?? false;
        final targetInfo = checkFilesystemNamespaceWritePermission(
          visitor,
          directory.path,
          operation: 'delete directory',
        );
        if (SecureFileOpener.isSupported) {
          final securePath = p.join(targetInfo.parent, targetInfo.name);
          if (recursive) {
            SecureFileOpener.deletePathRecursive(securePath);
          } else {
            SecureFileOpener.deleteDirectory(securePath);
          }
          return null;
        }
        directory.deleteSync(recursive: recursive);
        return null;
      },
      'list': (visitor, target, positionalArgs, namedArgs) {
        final directory = target as Directory;
        checkFilesystemReadPermission(
          visitor,
          directory.path,
          operation: 'list directory',
        );
        return directory
            .list(
              recursive: namedArgs['recursive'] as bool? ?? false,
              followLinks: namedArgs['followLinks'] as bool? ?? true,
            )
            .map((entity) {
              checkFilesystemReadPermission(
                visitor,
                entity.path,
                operation: 'list directory',
              );
              return entity;
            });
      },
      'listSync': (visitor, target, positionalArgs, namedArgs) {
        final directory = target as Directory;
        checkFilesystemReadPermission(
          visitor,
          directory.path,
          operation: 'list directory',
        );
        final entities = directory.listSync(
          recursive: namedArgs['recursive'] as bool? ?? false,
          followLinks: namedArgs['followLinks'] as bool? ?? true,
        );
        for (final entity in entities) {
          checkFilesystemReadPermission(
            visitor,
            entity.path,
            operation: 'list directory',
          );
        }
        return entities;
      },
      'rename': (visitor, target, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
          throw RuntimeError(
            'Directory.rename requires one String argument (newPath).',
          );
        }
        final directory = target as Directory;
        final newPath = positionalArgs[0] as String;
        final oldTarget = checkFilesystemNamespaceWritePermission(
          visitor,
          directory.path,
          operation: 'rename directory',
        );
        final newTarget = checkFilesystemNamespaceWritePermission(
          visitor,
          newPath,
          operation: 'rename directory',
        );
        if (SecureFileOpener.isSupported) {
          SecureFileOpener.renamePath(
            p.join(oldTarget.parent, oldTarget.name),
            p.join(newTarget.parent, newTarget.name),
          );
          return Future<Directory>.value(Directory(newPath));
        }
        return directory.rename(newPath);
      },
      'renameSync': (visitor, target, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
          throw RuntimeError(
            'Directory.renameSync requires one String argument (newPath).',
          );
        }
        final directory = target as Directory;
        final newPath = positionalArgs[0] as String;
        final oldTarget = checkFilesystemNamespaceWritePermission(
          visitor,
          directory.path,
          operation: 'rename directory',
        );
        final newTarget = checkFilesystemNamespaceWritePermission(
          visitor,
          newPath,
          operation: 'rename directory',
        );
        if (SecureFileOpener.isSupported) {
          SecureFileOpener.renamePath(
            p.join(oldTarget.parent, oldTarget.name),
            p.join(newTarget.parent, newTarget.name),
          );
          return null;
        }
        directory.renameSync(newPath);
        return null;
      },
      'stat': (visitor, target, positionalArgs, namedArgs) {
        final directory = target as Directory;
        checkFilesystemReadPermission(
          visitor,
          directory.path,
          operation: 'stat directory',
        );
        return directory.stat();
      },
      'statSync': (visitor, target, positionalArgs, namedArgs) {
        final directory = target as Directory;
        checkFilesystemReadPermission(
          visitor,
          directory.path,
          operation: 'stat directory',
        );
        return directory.statSync();
      },
      'watch': (visitor, target, positionalArgs, namedArgs) {
        final directory = target as Directory;
        checkFilesystemReadPermission(
          visitor,
          directory.path,
          operation: 'watch directory',
        );
        return directory
            .watch(
              events: namedArgs['events'] as int? ?? FileSystemEvent.all,
              recursive: namedArgs['recursive'] as bool? ?? false,
            )
            .map((event) {
              checkFilesystemReadPermission(
                visitor,
                event.path,
                operation: 'watch directory',
              );
              return event;
            });
      },
      'resolveSymbolicLinks': (visitor, target, positionalArgs, namedArgs) {
        final directory = target as Directory;
        checkFilesystemReadPermission(
          visitor,
          directory.path,
          operation: 'resolve links',
        );
        return directory.resolveSymbolicLinks();
      },
      'resolveSymbolicLinksSync': (visitor, target, positionalArgs, namedArgs) {
        final directory = target as Directory;
        checkFilesystemReadPermission(
          visitor,
          directory.path,
          operation: 'resolve links',
        );
        return directory.resolveSymbolicLinksSync();
      },
      'createTemp': (visitor, target, positionalArgs, namedArgs) {
        final directory = target as Directory;
        checkFilesystemWritePermission(
          visitor,
          directory.path,
          operation: 'create temporary directory',
        );
        _checkTemporaryDirectoryPrefix(visitor, directory, positionalArgs);
        return directory.createTemp(
          positionalArgs.isNotEmpty ? positionalArgs[0] as String? : null,
        );
      },
      'createTempSync': (visitor, target, positionalArgs, namedArgs) {
        final directory = target as Directory;
        checkFilesystemWritePermission(
          visitor,
          directory.path,
          operation: 'create temporary directory',
        );
        _checkTemporaryDirectoryPrefix(visitor, directory, positionalArgs);
        return directory.createTempSync(
          positionalArgs.isNotEmpty ? positionalArgs[0] as String? : null,
        );
      },
      'toString': (visitor, target, positionalArgs, namedArgs) =>
          (target as Directory).toString(),
    },
    getters: {
      'path': (visitor, target) => (target as Directory).path,
      'absolute': (visitor, target) => (target as Directory).absolute,
      'uri': (visitor, target) => (target as Directory).uri,
      'parent': (visitor, target) => (target as Directory).parent,
      'isAbsolute': (visitor, target) => (target as Directory).isAbsolute,
    },
    staticGetters: {
      'systemTemp': (visitor) {
        final directory = Directory.systemTemp;
        checkFilesystemReadPermission(
          visitor,
          directory.path,
          operation: 'access system temp directory',
        );
        return directory;
      },
      'current': (visitor) {
        final directory = Directory.current;
        checkFilesystemReadPermission(
          visitor,
          directory.path,
          operation: 'access current directory',
        );
        return directory;
      },
    },
    staticSetters: {
      'current': (visitor, value) {
        final String newPath;
        if (value is Directory) {
          newPath = value.path;
        } else if (value is String) {
          newPath = value;
        } else {
          throw RuntimeError(
            'Directory.current requires a Directory or String value.',
          );
        }

        checkFilesystemWritePermission(
          visitor,
          Directory.current.path,
          operation: 'change current directory',
        );
        checkFilesystemWritePermission(
          visitor,
          newPath,
          operation: 'change current directory',
        );
        Directory.current = newPath;
        return;
      },
    },
  );
}

/// `Directory.createTemp` treats its prefix as a relative path, including
/// `..` components. Validate the resulting location so a scoped write cannot
/// escape its directory through the prefix.
void _checkTemporaryDirectoryPrefix(
  InterpreterVisitor visitor,
  Directory directory,
  List<Object?> positionalArgs,
) {
  if (positionalArgs.isEmpty) return;

  final prefix = positionalArgs[0];
  if (prefix is! String || prefix.isEmpty) return;

  final candidate = p.isAbsolute(prefix)
      ? prefix
      : p.join(directory.path, prefix);
  checkFilesystemWritePermission(
    visitor,
    candidate,
    operation: 'create temporary directory',
  );
}
