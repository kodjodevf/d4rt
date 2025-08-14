import 'dart:io';
import 'package:d4rt/d4rt.dart';

class FileSystemEntityIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: FileSystemEntity,
        name: 'FileSystemEntity',
        typeParameterCount: 0,
        staticMethods: {
          'identical': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 2 ||
                positionalArgs[0] is! String ||
                positionalArgs[1] is! String) {
              throw RuntimeError(
                  'FileSystemEntity.identical requires two String arguments (path1, path2).');
            }
            return FileSystemEntity.identical(
                positionalArgs[0] as String, positionalArgs[1] as String);
          },
          'identicalSync': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 2 ||
                positionalArgs[0] is! String ||
                positionalArgs[1] is! String) {
              throw RuntimeError(
                  'FileSystemEntity.identicalSync requires two String arguments (path1, path2).');
            }
            return FileSystemEntity.identicalSync(
                positionalArgs[0] as String, positionalArgs[1] as String);
          },
          'isDirectory': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'FileSystemEntity.isDirectory requires one String argument (path).');
            }
            return FileSystemEntity.isDirectory(positionalArgs[0] as String);
          },
          'isDirectorySync': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'FileSystemEntity.isDirectorySync requires one String argument (path).');
            }
            return FileSystemEntity.isDirectorySync(
                positionalArgs[0] as String);
          },
          'isFile': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'FileSystemEntity.isFile requires one String argument (path).');
            }
            return FileSystemEntity.isFile(positionalArgs[0] as String);
          },
          'isFileSync': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'FileSystemEntity.isFileSync requires one String argument (path).');
            }
            return FileSystemEntity.isFileSync(positionalArgs[0] as String);
          },
          'isLink': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'FileSystemEntity.isLink requires one String argument (path).');
            }
            return FileSystemEntity.isLink(positionalArgs[0] as String);
          },
          'isLinkSync': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'FileSystemEntity.isLinkSync requires one String argument (path).');
            }
            return FileSystemEntity.isLinkSync(positionalArgs[0] as String);
          },
          'type': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'FileSystemEntity.type requires one String argument (path).');
            }
            return FileSystemEntity.type(positionalArgs[0] as String,
                followLinks: namedArgs['followLinks'] as bool? ?? true);
          },
          'typeSync': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'FileSystemEntity.typeSync requires one String argument (path).');
            }
            return FileSystemEntity.typeSync(positionalArgs[0] as String,
                followLinks: namedArgs['followLinks'] as bool? ?? true);
          },
          'parentOf': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'FileSystemEntity.parentOf requires one String argument (path).');
            }
            return FileSystemEntity.parentOf(positionalArgs[0] as String);
          },
        },
        methods: {
          'exists': (visitor, target, positionalArgs, namedArgs) {
            return (target as FileSystemEntity).exists();
          },
          'existsSync': (visitor, target, positionalArgs, namedArgs) {
            return (target as FileSystemEntity).existsSync();
          },
          'delete': (visitor, target, positionalArgs, namedArgs) {
            return (target as FileSystemEntity)
                .delete(recursive: namedArgs['recursive'] as bool? ?? false);
          },
          'deleteSync': (visitor, target, positionalArgs, namedArgs) {
            (target as FileSystemEntity).deleteSync(
                recursive: namedArgs['recursive'] as bool? ?? false);
            return null;
          },
          'rename': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'FileSystemEntity.rename requires one String argument (newPath).');
            }
            return (target as FileSystemEntity)
                .rename(positionalArgs[0] as String);
          },
          'renameSync': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'FileSystemEntity.renameSync requires one String argument (newPath).');
            }
            (target as FileSystemEntity)
                .renameSync(positionalArgs[0] as String);
            return null;
          },
          'stat': (visitor, target, positionalArgs, namedArgs) {
            return (target as FileSystemEntity).stat();
          },
          'statSync': (visitor, target, positionalArgs, namedArgs) {
            return (target as FileSystemEntity).statSync();
          },
          'watch': (visitor, target, positionalArgs, namedArgs) {
            return (target as FileSystemEntity).watch(
                events: namedArgs['events'] as int? ?? FileSystemEvent.all,
                recursive: namedArgs['recursive'] as bool? ?? false);
          },
          'resolveSymbolicLinks': (visitor, target, positionalArgs, namedArgs) {
            return (target as FileSystemEntity).resolveSymbolicLinks();
          },
          'resolveSymbolicLinksSync':
              (visitor, target, positionalArgs, namedArgs) {
            return (target as FileSystemEntity).resolveSymbolicLinksSync();
          },
        },
        getters: {
          'absolute': (visitor, target) =>
              (target as FileSystemEntity).absolute,
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
                  'FileStat.stat requires one String argument (path).');
            }
            return FileStat.stat(positionalArgs[0] as String);
          },
          'statSync': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'FileStat.statSync requires one String argument (path).');
            }
            return FileStat.statSync(positionalArgs[0] as String);
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
          // Deprecated but still available
          'NOT_FOUND': (visitor) => FileSystemEntityType.NOT_FOUND,
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
