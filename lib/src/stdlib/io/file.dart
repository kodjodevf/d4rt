import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:d4rt/d4rt.dart';

/// File mode for opening files
class FileModeIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: FileMode,
        name: 'FileMode',
        typeParameterCount: 0,
        staticGetters: {
          'read': (visitor) => FileMode.read,
          'write': (visitor) => FileMode.write,
          'append': (visitor) => FileMode.append,
          'writeOnly': (visitor) => FileMode.writeOnly,
          'writeOnlyAppend': (visitor) => FileMode.writeOnlyAppend,
        },
      );
}

/// File lock types
class FileLockIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: FileLock,
        name: 'FileLock',
        typeParameterCount: 0,
        staticGetters: {
          'shared': (visitor) => FileLock.shared,
          'exclusive': (visitor) => FileLock.exclusive,
          'blockingShared': (visitor) => FileLock.blockingShared,
          'blockingExclusive': (visitor) => FileLock.blockingExclusive,
        },
      );
}

/// Random access file operations
class RandomAccessFileIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: RandomAccessFile,
        name: 'RandomAccessFile',
        typeParameterCount: 0,
        methods: {
          'close': (visitor, target, positionalArgs, namedArgs) =>
              (target as RandomAccessFile).close(),
          'closeSync': (visitor, target, positionalArgs, namedArgs) {
            (target as RandomAccessFile).closeSync();
            return null;
          },
          'readByte': (visitor, target, positionalArgs, namedArgs) =>
              (target as RandomAccessFile).readByte(),
          'readByteSync': (visitor, target, positionalArgs, namedArgs) =>
              (target as RandomAccessFile).readByteSync(),
          'read': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! int) {
              throw RuntimeError(
                  'RandomAccessFile.read requires one int argument (count).');
            }
            return (target as RandomAccessFile).read(positionalArgs[0] as int);
          },
          'readSync': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! int) {
              throw RuntimeError(
                  'RandomAccessFile.readSync requires one int argument (count).');
            }
            return (target as RandomAccessFile)
                .readSync(positionalArgs[0] as int);
          },
          'readInto': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty || positionalArgs[0] is! List) {
              throw RuntimeError(
                  'RandomAccessFile.readInto requires a List<int> buffer.');
            }
            final buffer = positionalArgs[0] as List<int>;
            final start =
                positionalArgs.length > 1 ? positionalArgs[1] as int? ?? 0 : 0;
            final end =
                positionalArgs.length > 2 ? positionalArgs[2] as int? : null;
            return (target as RandomAccessFile).readInto(buffer, start, end);
          },
          'readIntoSync': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty || positionalArgs[0] is! List) {
              throw RuntimeError(
                  'RandomAccessFile.readIntoSync requires a List<int> buffer.');
            }
            final buffer = positionalArgs[0] as List<int>;
            final start =
                positionalArgs.length > 1 ? positionalArgs[1] as int? ?? 0 : 0;
            final end =
                positionalArgs.length > 2 ? positionalArgs[2] as int? : null;
            return (target as RandomAccessFile)
                .readIntoSync(buffer, start, end);
          },
          'writeByte': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! int) {
              throw RuntimeError(
                  'RandomAccessFile.writeByte requires one int argument (value).');
            }
            return (target as RandomAccessFile)
                .writeByte(positionalArgs[0] as int);
          },
          'writeByteSync': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! int) {
              throw RuntimeError(
                  'RandomAccessFile.writeByteSync requires one int argument (value).');
            }
            return (target as RandomAccessFile)
                .writeByteSync(positionalArgs[0] as int);
          },
          'writeFrom': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty || positionalArgs[0] is! List) {
              throw RuntimeError(
                  'RandomAccessFile.writeFrom requires a List<int> buffer.');
            }
            final buffer = positionalArgs[0] as List<int>;
            final start =
                positionalArgs.length > 1 ? positionalArgs[1] as int? ?? 0 : 0;
            final end =
                positionalArgs.length > 2 ? positionalArgs[2] as int? : null;
            return (target as RandomAccessFile).writeFrom(buffer, start, end);
          },
          'writeFromSync': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty || positionalArgs[0] is! List) {
              throw RuntimeError(
                  'RandomAccessFile.writeFromSync requires a List<int> buffer.');
            }
            final buffer = positionalArgs[0] as List<int>;
            final start =
                positionalArgs.length > 1 ? positionalArgs[1] as int? ?? 0 : 0;
            final end =
                positionalArgs.length > 2 ? positionalArgs[2] as int? : null;
            (target as RandomAccessFile).writeFromSync(buffer, start, end);
            return null;
          },
          'writeString': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'RandomAccessFile.writeString requires one String argument.');
            }
            final encoding = namedArgs['encoding'] as Encoding? ?? utf8;
            return (target as RandomAccessFile)
                .writeString(positionalArgs[0] as String, encoding: encoding);
          },
          'writeStringSync': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'RandomAccessFile.writeStringSync requires one String argument.');
            }
            final encoding = namedArgs['encoding'] as Encoding? ?? utf8;
            (target as RandomAccessFile).writeStringSync(
                positionalArgs[0] as String,
                encoding: encoding);
            return null;
          },
          'position': (visitor, target, positionalArgs, namedArgs) =>
              (target as RandomAccessFile).position(),
          'positionSync': (visitor, target, positionalArgs, namedArgs) =>
              (target as RandomAccessFile).positionSync(),
          'setPosition': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! int) {
              throw RuntimeError(
                  'RandomAccessFile.setPosition requires one int argument (position).');
            }
            return (target as RandomAccessFile)
                .setPosition(positionalArgs[0] as int);
          },
          'setPositionSync': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! int) {
              throw RuntimeError(
                  'RandomAccessFile.setPositionSync requires one int argument (position).');
            }
            (target as RandomAccessFile)
                .setPositionSync(positionalArgs[0] as int);
            return null;
          },
          'truncate': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! int) {
              throw RuntimeError(
                  'RandomAccessFile.truncate requires one int argument (length).');
            }
            return (target as RandomAccessFile)
                .truncate(positionalArgs[0] as int);
          },
          'truncateSync': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! int) {
              throw RuntimeError(
                  'RandomAccessFile.truncateSync requires one int argument (length).');
            }
            (target as RandomAccessFile).truncateSync(positionalArgs[0] as int);
            return null;
          },
          'length': (visitor, target, positionalArgs, namedArgs) =>
              (target as RandomAccessFile).length(),
          'lengthSync': (visitor, target, positionalArgs, namedArgs) =>
              (target as RandomAccessFile).lengthSync(),
          'flush': (visitor, target, positionalArgs, namedArgs) =>
              (target as RandomAccessFile).flush(),
          'flushSync': (visitor, target, positionalArgs, namedArgs) {
            (target as RandomAccessFile).flushSync();
            return null;
          },
          'lock': (visitor, target, positionalArgs, namedArgs) {
            final mode = namedArgs['mode'] as FileLock? ?? FileLock.exclusive;
            final start = namedArgs['start'] as int? ?? 0;
            final end = namedArgs['end'] as int? ?? -1;
            return (target as RandomAccessFile).lock(mode, start, end);
          },
          'lockSync': (visitor, target, positionalArgs, namedArgs) {
            final mode = namedArgs['mode'] as FileLock? ?? FileLock.exclusive;
            final start = namedArgs['start'] as int? ?? 0;
            final end = namedArgs['end'] as int? ?? -1;
            (target as RandomAccessFile).lockSync(mode, start, end);
            return null;
          },
          'unlock': (visitor, target, positionalArgs, namedArgs) {
            final start = namedArgs['start'] as int? ?? 0;
            final end = namedArgs['end'] as int? ?? -1;
            return (target as RandomAccessFile).unlock(start, end);
          },
          'unlockSync': (visitor, target, positionalArgs, namedArgs) {
            final start = namedArgs['start'] as int? ?? 0;
            final end = namedArgs['end'] as int? ?? -1;
            (target as RandomAccessFile).unlockSync(start, end);
            return null;
          },
          'toString': (visitor, target, positionalArgs, namedArgs) =>
              (target as RandomAccessFile).toString(),
        },
        getters: {
          'path': (visitor, target) => (target as RandomAccessFile).path,
        },
      );
}

/// FileSystemException base class
class FileSystemExceptionIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: FileSystemException,
        name: 'FileSystemException',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final message = positionalArgs.isNotEmpty
                ? positionalArgs[0] as String? ?? ""
                : "";
            final path = positionalArgs.length > 1
                ? positionalArgs[1] as String? ?? ""
                : "";
            final osError = positionalArgs.length > 2
                ? positionalArgs[2] as OSError?
                : null;
            return FileSystemException(message, path, osError);
          },
        },
        methods: {
          'toString': (visitor, target, positionalArgs, namedArgs) =>
              (target as FileSystemException).toString(),
        },
        getters: {
          'message': (visitor, target) =>
              (target as FileSystemException).message,
          'path': (visitor, target) => (target as FileSystemException).path,
          'osError': (visitor, target) =>
              (target as FileSystemException).osError,
        },
      );
}

/// PathAccessException for access denied errors
class PathAccessExceptionIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: PathAccessException,
        name: 'PathAccessException',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length < 2) {
              throw RuntimeError(
                  'PathAccessException requires path and osError arguments.');
            }
            final path = positionalArgs[0] as String;
            final osError = positionalArgs[1] as OSError;
            final message = positionalArgs.length > 2
                ? positionalArgs[2] as String? ?? ""
                : "";
            return PathAccessException(path, osError, message);
          },
        },
        methods: {
          'toString': (visitor, target, positionalArgs, namedArgs) =>
              (target as PathAccessException).toString(),
        },
        getters: {
          'message': (visitor, target) =>
              (target as PathAccessException).message,
          'path': (visitor, target) => (target as PathAccessException).path,
          'osError': (visitor, target) =>
              (target as PathAccessException).osError,
        },
      );
}

/// PathExistsException for file exists errors
class PathExistsExceptionIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: PathExistsException,
        name: 'PathExistsException',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length < 2) {
              throw RuntimeError(
                  'PathExistsException requires path and osError arguments.');
            }
            final path = positionalArgs[0] as String;
            final osError = positionalArgs[1] as OSError;
            final message = positionalArgs.length > 2
                ? positionalArgs[2] as String? ?? ""
                : "";
            return PathExistsException(path, osError, message);
          },
        },
        methods: {
          'toString': (visitor, target, positionalArgs, namedArgs) =>
              (target as PathExistsException).toString(),
        },
        getters: {
          'message': (visitor, target) =>
              (target as PathExistsException).message,
          'path': (visitor, target) => (target as PathExistsException).path,
          'osError': (visitor, target) =>
              (target as PathExistsException).osError,
        },
      );
}

/// PathNotFoundException for file not found errors
class PathNotFoundExceptionIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: PathNotFoundException,
        name: 'PathNotFoundException',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length < 2) {
              throw RuntimeError(
                  'PathNotFoundException requires path and osError arguments.');
            }
            final path = positionalArgs[0] as String;
            final osError = positionalArgs[1] as OSError;
            final message = positionalArgs.length > 2
                ? positionalArgs[2] as String? ?? ""
                : "";
            return PathNotFoundException(path, osError, message);
          },
        },
        methods: {
          'toString': (visitor, target, positionalArgs, namedArgs) =>
              (target as PathNotFoundException).toString(),
        },
        getters: {
          'message': (visitor, target) =>
              (target as PathNotFoundException).message,
          'path': (visitor, target) => (target as PathNotFoundException).path,
          'osError': (visitor, target) =>
              (target as PathNotFoundException).osError,
        },
      );
}

/// Pipe for interprocess communication
class PipeIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: Pipe,
        name: 'Pipe',
        typeParameterCount: 0,
        staticMethods: {
          'create': (visitor, positionalArgs, namedArgs) => Pipe.create(),
          'createSync': (visitor, positionalArgs, namedArgs) =>
              Pipe.createSync(),
        },
        getters: {
          'read': (visitor, target) => (target as Pipe).read,
          'write': (visitor, target) => (target as Pipe).write,
        },
      );
}

class FileIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: File,
        name: 'File',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'File constructor requires one String argument (path).');
            }
            return File(positionalArgs[0] as String);
          },
        },
        staticMethods: {
          'fromRawPath': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! Uint8List) {
              throw RuntimeError(
                  'File.fromRawPath requires one Uint8List argument.');
            }
            return File.fromRawPath(positionalArgs[0] as Uint8List);
          },
          'fromUri': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! Uri) {
              throw RuntimeError('File.fromUri requires one Uri argument.');
            }
            return File.fromUri(positionalArgs[0] as Uri);
          },
        },
        methods: {
          'exists': (visitor, target, positionalArgs, namedArgs) =>
              (target as File).exists(),
          'existsSync': (visitor, target, positionalArgs, namedArgs) =>
              (target as File).existsSync(),
          'readAsString': (visitor, target, positionalArgs, namedArgs) =>
              (target as File).readAsString(
                  encoding: namedArgs['encoding'] as Encoding? ?? utf8),
          'readAsStringSync': (visitor, target, positionalArgs, namedArgs) =>
              (target as File).readAsStringSync(
                  encoding: namedArgs['encoding'] as Encoding? ?? utf8),
          'readAsBytes': (visitor, target, positionalArgs, namedArgs) =>
              (target as File).readAsBytes(),
          'readAsBytesSync': (visitor, target, positionalArgs, namedArgs) =>
              (target as File).readAsBytesSync(),
          'readAsLines': (visitor, target, positionalArgs, namedArgs) =>
              (target as File).readAsLines(
                  encoding: namedArgs['encoding'] as Encoding? ?? utf8),
          'readAsLinesSync': (visitor, target, positionalArgs, namedArgs) =>
              (target as File).readAsLinesSync(
                  encoding: namedArgs['encoding'] as Encoding? ?? utf8),
          'writeAsString': (visitor, target, positionalArgs, namedArgs) {
            final file = target as File;
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'File.writeAsString requires one String argument (contents).');
            }
            return file.writeAsString(
              positionalArgs[0] as String,
              mode: namedArgs['mode'] as FileMode? ?? FileMode.write,
              encoding: namedArgs['encoding'] as Encoding? ?? utf8,
              flush: namedArgs['flush'] as bool? ?? false,
            );
          },
          'writeAsStringSync': (visitor, target, positionalArgs, namedArgs) {
            final file = target as File;
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'File.writeAsStringSync requires one String argument (contents).');
            }
            file.writeAsStringSync(
              positionalArgs[0] as String,
              mode: namedArgs['mode'] as FileMode? ?? FileMode.write,
              encoding: namedArgs['encoding'] as Encoding? ?? utf8,
              flush: namedArgs['flush'] as bool? ?? false,
            );
            return null;
          },
          'writeAsBytes': (visitor, target, positionalArgs, namedArgs) {
            final file = target as File;
            if (positionalArgs.length != 1 || positionalArgs[0] is! List) {
              throw RuntimeError(
                  'File.writeAsBytes requires one List<int> argument (bytes).');
            }
            return file.writeAsBytes(
              (positionalArgs[0] as List).cast(),
              mode: namedArgs['mode'] as FileMode? ?? FileMode.write,
              flush: namedArgs['flush'] as bool? ?? false,
            );
          },
          'writeAsBytesSync': (visitor, target, positionalArgs, namedArgs) {
            final file = target as File;
            if (positionalArgs.length != 1 || positionalArgs[0] is! List) {
              throw RuntimeError(
                  'File.writeAsBytesSync requires one List<int> argument (bytes).');
            }
            file.writeAsBytesSync(
              (positionalArgs[0] as List).cast(),
              mode: namedArgs['mode'] as FileMode? ?? FileMode.write,
              flush: namedArgs['flush'] as bool? ?? false,
            );
            return null;
          },
          'delete': (visitor, target, positionalArgs, namedArgs) =>
              (target as File)
                  .delete(recursive: namedArgs['recursive'] as bool? ?? false),
          'deleteSync': (visitor, target, positionalArgs, namedArgs) {
            (target as File).deleteSync(
                recursive: namedArgs['recursive'] as bool? ?? false);
            return null;
          },
          'rename': (visitor, target, positionalArgs, namedArgs) {
            final file = target as File;
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'File.rename requires one String argument (newPath).');
            }
            return file.rename(positionalArgs[0] as String);
          },
          'renameSync': (visitor, target, positionalArgs, namedArgs) {
            final file = target as File;
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'File.renameSync requires one String argument (newPath).');
            }
            return file.renameSync(positionalArgs[0] as String);
          },
          'copy': (visitor, target, positionalArgs, namedArgs) {
            final file = target as File;
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'File.copy requires one String argument (newPath).');
            }
            return file.copy(positionalArgs[0] as String);
          },
          'copySync': (visitor, target, positionalArgs, namedArgs) {
            final file = target as File;
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'File.copySync requires one String argument (newPath).');
            }
            return file.copySync(positionalArgs[0] as String);
          },
          'length': (visitor, target, positionalArgs, namedArgs) =>
              (target as File).length(),
          'lengthSync': (visitor, target, positionalArgs, namedArgs) =>
              (target as File).lengthSync(),
          'lastAccessed': (visitor, target, positionalArgs, namedArgs) =>
              (target as File).lastAccessed(),
          'lastAccessedSync': (visitor, target, positionalArgs, namedArgs) =>
              (target as File).lastAccessedSync(),
          'setLastAccessed': (visitor, target, positionalArgs, namedArgs) {
            final file = target as File;
            if (positionalArgs.length != 1 || positionalArgs[0] is! DateTime) {
              throw RuntimeError(
                  'File.setLastAccessed requires one DateTime argument.');
            }
            return file.setLastAccessed(positionalArgs[0] as DateTime);
          },
          'setLastAccessedSync': (visitor, target, positionalArgs, namedArgs) {
            final file = target as File;
            if (positionalArgs.length != 1 || positionalArgs[0] is! DateTime) {
              throw RuntimeError(
                  'File.setLastAccessedSync requires one DateTime argument.');
            }
            file.setLastAccessedSync(positionalArgs[0] as DateTime);
            return null;
          },
          'lastModified': (visitor, target, positionalArgs, namedArgs) =>
              (target as File).lastModified(),
          'lastModifiedSync': (visitor, target, positionalArgs, namedArgs) =>
              (target as File).lastModifiedSync(),
          'setLastModified': (visitor, target, positionalArgs, namedArgs) {
            final file = target as File;
            if (positionalArgs.length != 1 || positionalArgs[0] is! DateTime) {
              throw RuntimeError(
                  'File.setLastModified requires one DateTime argument.');
            }
            return file.setLastModified(positionalArgs[0] as DateTime);
          },
          'setLastModifiedSync': (visitor, target, positionalArgs, namedArgs) {
            final file = target as File;
            if (positionalArgs.length != 1 || positionalArgs[0] is! DateTime) {
              throw RuntimeError(
                  'File.setLastModifiedSync requires one DateTime argument.');
            }
            file.setLastModifiedSync(positionalArgs[0] as DateTime);
            return null;
          },
          'open': (visitor, target, positionalArgs, namedArgs) =>
              (target as File)
                  .open(mode: namedArgs['mode'] as FileMode? ?? FileMode.read),
          'openSync': (visitor, target, positionalArgs, namedArgs) => (target
                  as File)
              .openSync(mode: namedArgs['mode'] as FileMode? ?? FileMode.read),
          'openRead': (visitor, target, positionalArgs, namedArgs) =>
              (target as File).openRead(
                  positionalArgs.isNotEmpty ? positionalArgs[0] as int? : null,
                  positionalArgs.length > 1 ? positionalArgs[1] as int? : null),
          'openWrite': (visitor, target, positionalArgs, namedArgs) =>
              (target as File).openWrite(
                mode: namedArgs['mode'] as FileMode? ?? FileMode.write,
                encoding: namedArgs['encoding'] as Encoding? ?? utf8,
              ),
          'stat': (visitor, target, positionalArgs, namedArgs) =>
              (target as File).stat(),
          'statSync': (visitor, target, positionalArgs, namedArgs) =>
              (target as File).statSync(),
          'resolveSymbolicLinks':
              (visitor, target, positionalArgs, namedArgs) =>
                  (target as File).resolveSymbolicLinks(),
          'resolveSymbolicLinksSync':
              (visitor, target, positionalArgs, namedArgs) =>
                  (target as File).resolveSymbolicLinksSync(),
          'create': (visitor, target, positionalArgs, namedArgs) =>
              (target as File).create(
                  recursive: namedArgs['recursive'] as bool? ?? false,
                  exclusive: namedArgs['exclusive'] as bool? ?? false),
          'createSync': (visitor, target, positionalArgs, namedArgs) {
            (target as File).createSync(
                recursive: namedArgs['recursive'] as bool? ?? false,
                exclusive: namedArgs['exclusive'] as bool? ?? false);
            return null;
          },
          'watch': (visitor, target, positionalArgs, namedArgs) =>
              (target as File).watch(
                  events: namedArgs['events'] as int? ?? FileSystemEvent.all,
                  recursive: namedArgs['recursive'] as bool? ?? false),
          'toString': (visitor, target, positionalArgs, namedArgs) =>
              (target as File).toString(),
        },
        getters: {
          'path': (visitor, target) => (target as File).path,
          'absolute': (visitor, target) => (target as File).absolute,
          'parent': (visitor, target) => (target as File).parent,
          'isAbsolute': (visitor, target) => (target as File).isAbsolute,
          'uri': (visitor, target) => (target as File).uri,
          'runtimeType': (visitor, target) => (target as File).runtimeType,
          'hashCode': (visitor, target) => (target as File).hashCode,
        },
      );
}
