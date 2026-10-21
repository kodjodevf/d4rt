import 'dart:io';
import 'package:d4rt/d4rt.dart';
import 'package:path/path.dart' as p;

import 'filesystem_permission_helper.dart';
import 'secure_file_opener.dart';

class FileSystemEntityIo {
  static BridgedClass get definition => BridgedClass(
    nativeType: FileSystemEntity,
    name: 'FileSystemEntity',
    typeParameterCount: 0,
    isSubtypeOfFunc: (value) => value is FileSystemEntity,
    staticMethods: {
      'identical': (visitor, positionalArgs, namedArgs) {
        if (positionalArgs.length != 2 ||
            positionalArgs[0] is! String ||
            positionalArgs[1] is! String) {
          throw RuntimeError(
            'FileSystemEntity.identical requires two String arguments (path1, path2).',
          );
        }
        checkFilesystemReadPermission(
          visitor,
          positionalArgs[0] as String,
          operation: 'compare file system entities',
        );
        checkFilesystemReadPermission(
          visitor,
          positionalArgs[1] as String,
          operation: 'compare file system entities',
        );
        return FileSystemEntity.identical(
          positionalArgs[0] as String,
          positionalArgs[1] as String,
        );
      },
      'identicalSync': (visitor, positionalArgs, namedArgs) {
        if (positionalArgs.length != 2 ||
            positionalArgs[0] is! String ||
            positionalArgs[1] is! String) {
          throw RuntimeError(
            'FileSystemEntity.identicalSync requires two String arguments (path1, path2).',
          );
        }
        checkFilesystemReadPermission(
          visitor,
          positionalArgs[0] as String,
          operation: 'compare file system entities',
        );
        checkFilesystemReadPermission(
          visitor,
          positionalArgs[1] as String,
          operation: 'compare file system entities',
        );
        return FileSystemEntity.identicalSync(
          positionalArgs[0] as String,
          positionalArgs[1] as String,
        );
      },
      'isDirectory': (visitor, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
          throw RuntimeError(
            'FileSystemEntity.isDirectory requires one String argument (path).',
          );
        }
        checkFilesystemReadPermission(
          visitor,
          positionalArgs[0] as String,
          operation: 'inspect path',
        );
        return FileSystemEntity.isDirectory(positionalArgs[0] as String);
      },
      'isDirectorySync': (visitor, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
          throw RuntimeError(
            'FileSystemEntity.isDirectorySync requires one String argument (path).',
          );
        }
        checkFilesystemReadPermission(
          visitor,
          positionalArgs[0] as String,
          operation: 'inspect path',
        );
        return FileSystemEntity.isDirectorySync(positionalArgs[0] as String);
      },
      'isFile': (visitor, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
          throw RuntimeError(
            'FileSystemEntity.isFile requires one String argument (path).',
          );
        }
        checkFilesystemReadPermission(
          visitor,
          positionalArgs[0] as String,
          operation: 'inspect path',
        );
        return FileSystemEntity.isFile(positionalArgs[0] as String);
      },
      'isFileSync': (visitor, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
          throw RuntimeError(
            'FileSystemEntity.isFileSync requires one String argument (path).',
          );
        }
        checkFilesystemReadPermission(
          visitor,
          positionalArgs[0] as String,
          operation: 'inspect path',
        );
        return FileSystemEntity.isFileSync(positionalArgs[0] as String);
      },
      'isLink': (visitor, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
          throw RuntimeError(
            'FileSystemEntity.isLink requires one String argument (path).',
          );
        }
        checkFilesystemReadPermission(
          visitor,
          positionalArgs[0] as String,
          operation: 'inspect path',
        );
        return FileSystemEntity.isLink(positionalArgs[0] as String);
      },
      'isLinkSync': (visitor, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
          throw RuntimeError(
            'FileSystemEntity.isLinkSync requires one String argument (path).',
          );
        }
        checkFilesystemReadPermission(
          visitor,
          positionalArgs[0] as String,
          operation: 'inspect path',
        );
        return FileSystemEntity.isLinkSync(positionalArgs[0] as String);
      },
      'type': (visitor, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
          throw RuntimeError(
            'FileSystemEntity.type requires one String argument (path).',
          );
        }
        checkFilesystemReadPermission(
          visitor,
          positionalArgs[0] as String,
          operation: 'inspect path',
        );
        return FileSystemEntity.type(
          positionalArgs[0] as String,
          followLinks: namedArgs['followLinks'] as bool? ?? true,
        );
      },
      'typeSync': (visitor, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
          throw RuntimeError(
            'FileSystemEntity.typeSync requires one String argument (path).',
          );
        }
        checkFilesystemReadPermission(
          visitor,
          positionalArgs[0] as String,
          operation: 'inspect path',
        );
        return FileSystemEntity.typeSync(
          positionalArgs[0] as String,
          followLinks: namedArgs['followLinks'] as bool? ?? true,
        );
      },
      'parentOf': (visitor, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
          throw RuntimeError(
            'FileSystemEntity.parentOf requires one String argument (path).',
          );
        }
        checkFilesystemReadPermission(
          visitor,
          positionalArgs[0] as String,
          operation: 'inspect path',
        );
        return FileSystemEntity.parentOf(positionalArgs[0] as String);
      },
    },
    methods: {
      'exists': (visitor, target, positionalArgs, namedArgs) {
        final entity = target as FileSystemEntity;
        final canonical = checkFilesystemReadPermission(
          visitor,
          entity.path,
          operation: 'check existence',
        );
        if (entity is Link) return entity.exists();
        final expected = entity is Directory
            ? FileSystemEntityType.directory
            : FileSystemEntityType.file;
        final secureExists = SecureFileOpener.existsAs(canonical, expected);
        return secureExists == null
            ? entity.exists()
            : Future<bool>.value(secureExists);
      },
      'existsSync': (visitor, target, positionalArgs, namedArgs) {
        final entity = target as FileSystemEntity;
        final canonical = checkFilesystemReadPermission(
          visitor,
          entity.path,
          operation: 'check existence',
        );
        if (entity is Link) return entity.existsSync();
        final expected = entity is Directory
            ? FileSystemEntityType.directory
            : FileSystemEntityType.file;
        return SecureFileOpener.existsAs(canonical, expected) ??
            entity.existsSync();
      },
      'delete': (visitor, target, positionalArgs, namedArgs) {
        final entity = target as FileSystemEntity;
        final recursive = namedArgs['recursive'] as bool? ?? false;
        final entityTarget = checkFilesystemNamespaceWritePermission(
          visitor,
          entity.path,
          operation: 'delete entity',
        );
        if (SecureFileOpener.isSupported) {
          final securePath = p.join(entityTarget.parent, entityTarget.name);
          if (entity is Link) {
            SecureFileOpener.deleteLink(securePath);
          } else if (entity is Directory) {
            if (recursive) {
              SecureFileOpener.deletePathRecursive(securePath);
            } else {
              SecureFileOpener.deleteDirectory(securePath);
            }
          } else if (recursive) {
            SecureFileOpener.deletePathRecursive(securePath);
          } else {
            SecureFileOpener.deleteFile(securePath);
          }
          return Future<FileSystemEntity>.value(entity);
        }
        return entity.delete(recursive: recursive);
      },
      'deleteSync': (visitor, target, positionalArgs, namedArgs) {
        final entity = target as FileSystemEntity;
        final recursive = namedArgs['recursive'] as bool? ?? false;
        final entityTarget = checkFilesystemNamespaceWritePermission(
          visitor,
          entity.path,
          operation: 'delete entity',
        );
        if (SecureFileOpener.isSupported) {
          final securePath = p.join(entityTarget.parent, entityTarget.name);
          if (entity is Link) {
            SecureFileOpener.deleteLink(securePath);
          } else if (entity is Directory) {
            if (recursive) {
              SecureFileOpener.deletePathRecursive(securePath);
            } else {
              SecureFileOpener.deleteDirectory(securePath);
            }
          } else if (recursive) {
            SecureFileOpener.deletePathRecursive(securePath);
          } else {
            SecureFileOpener.deleteFile(securePath);
          }
          return null;
        }
        entity.deleteSync(recursive: recursive);
        return null;
      },
      'rename': (visitor, target, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
          throw RuntimeError(
            'FileSystemEntity.rename requires one String argument (newPath).',
          );
        }
        final entity = target as FileSystemEntity;
        final newPath = positionalArgs[0] as String;
        final oldTarget = checkFilesystemNamespaceWritePermission(
          visitor,
          entity.path,
          operation: 'rename entity',
        );
        final newTarget = checkFilesystemNamespaceWritePermission(
          visitor,
          newPath,
          operation: 'rename entity',
        );
        if (SecureFileOpener.isSupported) {
          SecureFileOpener.renamePath(
            p.join(oldTarget.parent, oldTarget.name),
            p.join(newTarget.parent, newTarget.name),
          );
          if (entity is Directory) {
            return Future<FileSystemEntity>.value(Directory(newPath));
          }
          if (entity is Link) {
            return Future<FileSystemEntity>.value(Link(newPath));
          }
          return Future<FileSystemEntity>.value(File(newPath));
        }
        return entity.rename(newPath);
      },
      'renameSync': (visitor, target, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
          throw RuntimeError(
            'FileSystemEntity.renameSync requires one String argument (newPath).',
          );
        }
        final entity = target as FileSystemEntity;
        final newPath = positionalArgs[0] as String;
        final oldTarget = checkFilesystemNamespaceWritePermission(
          visitor,
          entity.path,
          operation: 'rename entity',
        );
        final newTarget = checkFilesystemNamespaceWritePermission(
          visitor,
          newPath,
          operation: 'rename entity',
        );
        if (SecureFileOpener.isSupported) {
          SecureFileOpener.renamePath(
            p.join(oldTarget.parent, oldTarget.name),
            p.join(newTarget.parent, newTarget.name),
          );
          return null;
        }
        entity.renameSync(newPath);
        return null;
      },
      'stat': (visitor, target, positionalArgs, namedArgs) {
        final entity = target as FileSystemEntity;
        final canonical = checkFilesystemReadPermission(
          visitor,
          entity.path,
          operation: 'stat entity',
        );
        final secureStat = SecureFileOpener.stat(canonical);
        return secureStat == null
            ? entity.stat()
            : Future<FileStat>.value(secureStat);
      },
      'statSync': (visitor, target, positionalArgs, namedArgs) {
        final entity = target as FileSystemEntity;
        final canonical = checkFilesystemReadPermission(
          visitor,
          entity.path,
          operation: 'stat entity',
        );
        return SecureFileOpener.stat(canonical) ?? entity.statSync();
      },
      'watch': (visitor, target, positionalArgs, namedArgs) {
        final entity = target as FileSystemEntity;
        checkFilesystemReadPermission(
          visitor,
          entity.path,
          operation: 'watch entity',
        );
        return entity
            .watch(
              events: namedArgs['events'] as int? ?? FileSystemEvent.all,
              recursive: namedArgs['recursive'] as bool? ?? false,
            )
            .map((event) {
              checkFilesystemReadPermission(
                visitor,
                event.path,
                operation: 'watch entity',
              );
              return event;
            });
      },
      'resolveSymbolicLinks': (visitor, target, positionalArgs, namedArgs) {
        final entity = target as FileSystemEntity;
        checkFilesystemReadPermission(
          visitor,
          entity.path,
          operation: 'resolve symbolic links',
        );
        return entity.resolveSymbolicLinks().then((resolved) {
          checkFilesystemReadPermission(
            visitor,
            resolved,
            operation: 'resolve symbolic links',
          );
          return resolved;
        });
      },
      'resolveSymbolicLinksSync': (visitor, target, positionalArgs, namedArgs) {
        final entity = target as FileSystemEntity;
        checkFilesystemReadPermission(
          visitor,
          entity.path,
          operation: 'resolve symbolic links',
        );
        final resolved = entity.resolveSymbolicLinksSync();
        checkFilesystemReadPermission(
          visitor,
          resolved,
          operation: 'resolve symbolic links',
        );
        return resolved;
      },
    },
    getters: {
      'absolute': (visitor, target) => (target as FileSystemEntity).absolute,
      'uri': (visitor, target) => (target as FileSystemEntity).uri,
      'parent': (visitor, target) => (target as FileSystemEntity).parent,
      'path': (visitor, target) => (target as FileSystemEntity).path,
      'isAbsolute': (visitor, target) =>
          (target as FileSystemEntity).isAbsolute,
    },
    staticGetters: {
      'isWatchSupported': (visitor) => FileSystemEntity.isWatchSupported,
    },
  );
}

class FileStatIo {
  static BridgedClass get definition => BridgedClass(
    nativeType: FileStat,
    name: 'FileStat',
    typeParameterCount: 0,
    constructors: {
      // FileStat is typically obtained from stat() operations
    },
    staticMethods: {
      'stat': (visitor, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
          throw RuntimeError(
            'FileStat.stat requires one String argument (path).',
          );
        }
        final path = positionalArgs[0] as String;
        final canonical = checkFilesystemReadPermission(
          visitor,
          path,
          operation: 'stat entity',
        );
        final secureStat = SecureFileOpener.stat(canonical);
        return secureStat == null
            ? FileStat.stat(path)
            : Future<FileStat>.value(secureStat);
      },
      'statSync': (visitor, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
          throw RuntimeError(
            'FileStat.statSync requires one String argument (path).',
          );
        }
        final path = positionalArgs[0] as String;
        final canonical = checkFilesystemReadPermission(
          visitor,
          path,
          operation: 'stat entity',
        );
        return SecureFileOpener.stat(canonical) ?? FileStat.statSync(path);
      },
    },
    methods: {
      'modeString': (visitor, target, positionalArgs, namedArgs) {
        return (target as FileStat).modeString();
      },
      'toString': (visitor, target, positionalArgs, namedArgs) =>
          (target as FileStat).toString(),
    },
    getters: {
      'changed': (visitor, target) => (target as FileStat).changed,
      'modified': (visitor, target) => (target as FileStat).modified,
      'accessed': (visitor, target) => (target as FileStat).accessed,
      'type': (visitor, target) => (target as FileStat).type,
      'mode': (visitor, target) => (target as FileStat).mode,
      'size': (visitor, target) => (target as FileStat).size,
    },
  );
}

class FileSystemEntityTypeIo {
  static BridgedClass get definition => BridgedClass(
    nativeType: FileSystemEntityType,
    name: 'FileSystemEntityType',
    typeParameterCount: 0,
    constructors: {},
    methods: {
      'toString': (visitor, target, positionalArgs, namedArgs) =>
          (target as FileSystemEntityType).toString(),
    },
    staticGetters: {
      'file': (visitor) => FileSystemEntityType.file,
      'directory': (visitor) => FileSystemEntityType.directory,
      'link': (visitor) => FileSystemEntityType.link,
      'unixDomainSock': (visitor) => FileSystemEntityType.unixDomainSock,
      'pipe': (visitor) => FileSystemEntityType.pipe,
      'notFound': (visitor) => FileSystemEntityType.notFound,
    },
    getters: {},
  );
}

class FileSystemEventIo {
  static BridgedClass get definition => BridgedClass(
    nativeType: FileSystemEvent,
    name: 'FileSystemEvent',
    typeParameterCount: 0,
    constructors: {},
    staticGetters: {
      'create': (visitor) => FileSystemEvent.create,
      'delete': (visitor) => FileSystemEvent.delete,
      'modify': (visitor) => FileSystemEvent.modify,
      'move': (visitor) => FileSystemEvent.move,
      'all': (visitor) => FileSystemEvent.all,
    },
    methods: {
      'toString': (visitor, target, positionalArgs, namedArgs) =>
          (target as FileSystemEvent).toString(),
    },
    getters: {
      'type': (visitor, target) => (target as FileSystemEvent).type,
      'path': (visitor, target) => (target as FileSystemEvent).path,
      'isDirectory': (visitor, target) =>
          (target as FileSystemEvent).isDirectory,
      // Convenience getters for type checking
      'isCreate': (visitor, target) =>
          (target as FileSystemEvent).type == FileSystemEvent.create,
      'isModify': (visitor, target) =>
          (target as FileSystemEvent).type == FileSystemEvent.modify,
      'isDelete': (visitor, target) =>
          (target as FileSystemEvent).type == FileSystemEvent.delete,
      'isMove': (visitor, target) =>
          (target as FileSystemEvent).type == FileSystemEvent.move,
    },
  );
}
