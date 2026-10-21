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
        final canonical = checkFilesystemReadPermission(
          visitor,
          directory.path,
          operation: 'check directory existence',
        );
        final secureExists = SecureFileOpener.existsAs(
          canonical,
          FileSystemEntityType.directory,
        );
        return secureExists == null
            ? directory.exists()
            : Future<bool>.value(secureExists);
      },
      'existsSync': (visitor, target, positionalArgs, namedArgs) {
        final directory = target as Directory;
        final canonical = checkFilesystemReadPermission(
          visitor,
          directory.path,
          operation: 'check directory existence',
        );
        return SecureFileOpener.existsAs(
              canonical,
              FileSystemEntityType.directory,
            ) ??
            directory.existsSync();
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
        final canonical = checkFilesystemReadPermission(
          visitor,
          directory.path,
          operation: 'stat directory',
        );
        final secureStat = SecureFileOpener.stat(canonical);
        return secureStat == null
            ? directory.stat()
            : Future<FileStat>.value(secureStat);
      },
      'statSync': (visitor, target, positionalArgs, namedArgs) {
        final directory = target as Directory;
        final canonical = checkFilesystemReadPermission(
          visitor,
          directory.path,
          operation: 'stat directory',
        );
        return SecureFileOpener.stat(canonical) ?? directory.statSync();
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
        return directory.resolveSymbolicLinks().then((resolved) {
          checkFilesystemReadPermission(
            visitor,
            resolved,
            operation: 'resolve links',
          );
          return resolved;
        });
      },
      'resolveSymbolicLinksSync': (visitor, target, positionalArgs, namedArgs) {
        final directory = target as Directory;
        checkFilesystemReadPermission(
          visitor,
          directory.path,
          operation: 'resolve links',
        );
        final resolved = directory.resolveSymbolicLinksSync();
        checkFilesystemReadPermission(
          visitor,
          resolved,
          operation: 'resolve links',
        );
        return resolved;
      },
      'createTemp': (visitor, target, positionalArgs, namedArgs) {
        final directory = target as Directory;
        final prefix = positionalArgs.isNotEmpty
            ? positionalArgs[0] as String?
            : null;
        checkFilesystemWritePermission(
          visitor,
          directory.path,
          operation: 'create temporary directory',
        );
        final info = _temporaryDirectoryInfo(
          visitor,
          directory,
          positionalArgs,
        );
        if (SecureFileOpener.isSupported) {
          final parent = checkFilesystemWritePermission(
            visitor,
            info.parent,
            operation: 'create temporary directory',
          );
          final suffix = SecureFileOpener.createTempDirectory(
            parent,
            info.namePrefix,
          );
          if (suffix != null) {
            return Future<Directory>.value(
              Directory('${info.fullPrefix}$suffix'),
            );
          }
        }
        return directory.createTemp(prefix);
      },
      'createTempSync': (visitor, target, positionalArgs, namedArgs) {
        final directory = target as Directory;
        final prefix = positionalArgs.isNotEmpty
            ? positionalArgs[0] as String?
            : null;
        checkFilesystemWritePermission(
          visitor,
          directory.path,
          operation: 'create temporary directory',
        );
        final info = _temporaryDirectoryInfo(
          visitor,
          directory,
          positionalArgs,
        );
        if (SecureFileOpener.isSupported) {
          final parent = checkFilesystemWritePermission(
            visitor,
            info.parent,
            operation: 'create temporary directory',
          );
          final suffix = SecureFileOpener.createTempDirectory(
            parent,
            info.namePrefix,
          );
          if (suffix != null) {
            return Directory('${info.fullPrefix}$suffix');
          }
        }
        return directory.createTempSync(prefix);
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

/// Computes the native `Directory.createTemp` prefix layout and validates the
/// requested location before a descriptor-based creation.
({String fullPrefix, String parent, String namePrefix}) _temporaryDirectoryInfo(
  InterpreterVisitor visitor,
  Directory directory,
  List<Object?> positionalArgs,
) {
  final prefix = positionalArgs.isNotEmpty
      ? positionalArgs[0] as String?
      : null;
  final prefixValue = prefix ?? '';
  if (directory.path.isEmpty) {
    throw ArgumentError(
      'Directory.createTemp called with an empty path. '
      'To use the system temp directory, use Directory.systemTemp',
    );
  }

  final fullPrefix = directory.path.endsWith(p.separator)
      ? '${directory.path}$prefixValue'
      : '${directory.path}${p.separator}$prefixValue';
  if (fullPrefix.contains('\u0000')) {
    throw FileSystemException(
      'Filesystem paths cannot contain NUL characters',
      fullPrefix,
    );
  }

  if (prefixValue.isNotEmpty) {
    // Keep the existing fail-closed check for absolute prefixes and `..`
    // traversal. The native API treats an absolute prefix as relative to this
    // directory, but rejecting an out-of-scope absolute prefix is safer for
    // interpreted code.
    final candidate = p.isAbsolute(prefixValue)
        ? prefixValue
        : p.join(directory.path, prefixValue);
    checkFilesystemWritePermission(
      visitor,
      candidate,
      operation: 'create temporary directory',
    );
  }

  final separatorIndex = fullPrefix.lastIndexOf(p.separator);
  final parent = separatorIndex <= 0
      ? (separatorIndex == 0 ? p.separator : '.')
      : fullPrefix.substring(0, separatorIndex);
  final namePrefix = separatorIndex < 0
      ? ''
      : fullPrefix.substring(separatorIndex + 1);

  return (fullPrefix: fullPrefix, parent: parent, namePrefix: namePrefix);
}
