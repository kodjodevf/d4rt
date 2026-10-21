import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:d4rt/d4rt.dart';
import 'package:path/path.dart' as p;

import 'filesystem_permission_helper.dart';
import 'secure_file_opener.dart';

final Expando<String> _originalRandomAccessFilePaths = Expando(
  'd4rt.randomAccessFile.originalPath',
);

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
            'RandomAccessFile.read requires one int argument (count).',
          );
        }
        return (target as RandomAccessFile).read(positionalArgs[0] as int);
      },
      'readSync': (visitor, target, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! int) {
          throw RuntimeError(
            'RandomAccessFile.readSync requires one int argument (count).',
          );
        }
        return (target as RandomAccessFile).readSync(positionalArgs[0] as int);
      },
      'readInto': (visitor, target, positionalArgs, namedArgs) {
        if (positionalArgs.isEmpty || positionalArgs[0] is! List) {
          throw RuntimeError(
            'RandomAccessFile.readInto requires a List<int> buffer.',
          );
        }
        final buffer = positionalArgs[0] as List<int>;
        final start = positionalArgs.length > 1
            ? positionalArgs[1] as int? ?? 0
            : 0;
        final end = positionalArgs.length > 2
            ? positionalArgs[2] as int?
            : null;
        return (target as RandomAccessFile).readInto(buffer, start, end);
      },
      'readIntoSync': (visitor, target, positionalArgs, namedArgs) {
        if (positionalArgs.isEmpty || positionalArgs[0] is! List) {
          throw RuntimeError(
            'RandomAccessFile.readIntoSync requires a List<int> buffer.',
          );
        }
        final buffer = positionalArgs[0] as List<int>;
        final start = positionalArgs.length > 1
            ? positionalArgs[1] as int? ?? 0
            : 0;
        final end = positionalArgs.length > 2
            ? positionalArgs[2] as int?
            : null;
        return (target as RandomAccessFile).readIntoSync(buffer, start, end);
      },
      'writeByte': (visitor, target, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! int) {
          throw RuntimeError(
            'RandomAccessFile.writeByte requires one int argument (value).',
          );
        }
        return (target as RandomAccessFile).writeByte(positionalArgs[0] as int);
      },
      'writeByteSync': (visitor, target, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! int) {
          throw RuntimeError(
            'RandomAccessFile.writeByteSync requires one int argument (value).',
          );
        }
        return (target as RandomAccessFile).writeByteSync(
          positionalArgs[0] as int,
        );
      },
      'writeFrom': (visitor, target, positionalArgs, namedArgs) {
        if (positionalArgs.isEmpty || positionalArgs[0] is! List) {
          throw RuntimeError(
            'RandomAccessFile.writeFrom requires a List<int> buffer.',
          );
        }
        final buffer = positionalArgs[0] as List<int>;
        final start = positionalArgs.length > 1
            ? positionalArgs[1] as int? ?? 0
            : 0;
        final end = positionalArgs.length > 2
            ? positionalArgs[2] as int?
            : null;
        return (target as RandomAccessFile).writeFrom(buffer, start, end);
      },
      'writeFromSync': (visitor, target, positionalArgs, namedArgs) {
        if (positionalArgs.isEmpty || positionalArgs[0] is! List) {
          throw RuntimeError(
            'RandomAccessFile.writeFromSync requires a List<int> buffer.',
          );
        }
        final buffer = positionalArgs[0] as List<int>;
        final start = positionalArgs.length > 1
            ? positionalArgs[1] as int? ?? 0
            : 0;
        final end = positionalArgs.length > 2
            ? positionalArgs[2] as int?
            : null;
        (target as RandomAccessFile).writeFromSync(buffer, start, end);
        return null;
      },
      'writeString': (visitor, target, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
          throw RuntimeError(
            'RandomAccessFile.writeString requires one String argument.',
          );
        }
        final encoding = namedArgs['encoding'] as Encoding? ?? utf8;
        return (target as RandomAccessFile).writeString(
          positionalArgs[0] as String,
          encoding: encoding,
        );
      },
      'writeStringSync': (visitor, target, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
          throw RuntimeError(
            'RandomAccessFile.writeStringSync requires one String argument.',
          );
        }
        final encoding = namedArgs['encoding'] as Encoding? ?? utf8;
        (target as RandomAccessFile).writeStringSync(
          positionalArgs[0] as String,
          encoding: encoding,
        );
        return null;
      },
      'position': (visitor, target, positionalArgs, namedArgs) =>
          (target as RandomAccessFile).position(),
      'positionSync': (visitor, target, positionalArgs, namedArgs) =>
          (target as RandomAccessFile).positionSync(),
      'setPosition': (visitor, target, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! int) {
          throw RuntimeError(
            'RandomAccessFile.setPosition requires one int argument (position).',
          );
        }
        return (target as RandomAccessFile).setPosition(
          positionalArgs[0] as int,
        );
      },
      'setPositionSync': (visitor, target, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! int) {
          throw RuntimeError(
            'RandomAccessFile.setPositionSync requires one int argument (position).',
          );
        }
        (target as RandomAccessFile).setPositionSync(positionalArgs[0] as int);
        return null;
      },
      'truncate': (visitor, target, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! int) {
          throw RuntimeError(
            'RandomAccessFile.truncate requires one int argument (length).',
          );
        }
        return (target as RandomAccessFile).truncate(positionalArgs[0] as int);
      },
      'truncateSync': (visitor, target, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! int) {
          throw RuntimeError(
            'RandomAccessFile.truncateSync requires one int argument (length).',
          );
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
      'toString': (visitor, target, positionalArgs, namedArgs) {
        final file = target as RandomAccessFile;
        return _originalRandomAccessFilePaths[file] ?? file.toString();
      },
    },
    getters: {
      'path': (visitor, target) {
        final file = target as RandomAccessFile;
        return _originalRandomAccessFilePaths[file] ?? file.path;
      },
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
      'message': (visitor, target) => (target as FileSystemException).message,
      'path': (visitor, target) => (target as FileSystemException).path,
      'osError': (visitor, target) => (target as FileSystemException).osError,
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
            'PathAccessException requires path and osError arguments.',
          );
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
      'message': (visitor, target) => (target as PathAccessException).message,
      'path': (visitor, target) => (target as PathAccessException).path,
      'osError': (visitor, target) => (target as PathAccessException).osError,
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
            'PathExistsException requires path and osError arguments.',
          );
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
      'message': (visitor, target) => (target as PathExistsException).message,
      'path': (visitor, target) => (target as PathExistsException).path,
      'osError': (visitor, target) => (target as PathExistsException).osError,
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
            'PathNotFoundException requires path and osError arguments.',
          );
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
      'message': (visitor, target) => (target as PathNotFoundException).message,
      'path': (visitor, target) => (target as PathNotFoundException).path,
      'osError': (visitor, target) => (target as PathNotFoundException).osError,
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
      'createSync': (visitor, positionalArgs, namedArgs) => Pipe.createSync(),
    },
    getters: {
      'read': (visitor, target) => (target as Pipe).read,
      'write': (visitor, target) => (target as Pipe).write,
    },
  );
}

T _withSecureReadSync<T>(
  InterpreterVisitor visitor,
  File file,
  String operation,
  T Function(File securedFile) action,
) {
  final canonicalPath = checkFilesystemReadPermission(
    visitor,
    file.path,
    operation: operation,
  );
  final handle = SecureFileOpener.openRead(canonicalPath);
  if (handle == null) return action(file);

  try {
    return action(File(handle.path));
  } finally {
    handle.close();
  }
}

Future<T> _withSecureReadAsync<T>(
  InterpreterVisitor visitor,
  File file,
  String operation,
  Future<T> Function(File securedFile) action,
) async {
  final canonicalPath = checkFilesystemReadPermission(
    visitor,
    file.path,
    operation: operation,
  );
  final handle = SecureFileOpener.openRead(canonicalPath);
  if (handle == null) return action(file);

  try {
    return await action(File(handle.path));
  } finally {
    handle.close();
  }
}

T _withSecureWriteSync<T>(
  InterpreterVisitor visitor,
  File file,
  FileMode mode,
  String operation,
  T Function(File securedFile) action,
) {
  final canonicalPath = checkFilesystemWritePermission(
    visitor,
    file.path,
    operation: operation,
  );
  final handle = SecureFileOpener.openWrite(canonicalPath, mode: mode);
  if (handle == null) return action(file);

  try {
    return action(File(handle.path));
  } finally {
    handle.close();
  }
}

Future<T> _withSecureWriteAsync<T>(
  InterpreterVisitor visitor,
  File file,
  FileMode mode,
  String operation,
  Future<T> Function(File securedFile) action,
) async {
  final canonicalPath = checkFilesystemWritePermission(
    visitor,
    file.path,
    operation: operation,
  );
  final handle = SecureFileOpener.openWrite(canonicalPath, mode: mode);
  if (handle == null) return action(file);

  try {
    return await action(File(handle.path));
  } finally {
    handle.close();
  }
}

SecureFileHandle? _secureReadHandle(
  InterpreterVisitor visitor,
  File file,
  String operation,
) {
  final canonicalPath = checkFilesystemReadPermission(
    visitor,
    file.path,
    operation: operation,
  );
  return SecureFileOpener.openRead(canonicalPath);
}

SecureFileHandle? _secureWriteHandle(
  InterpreterVisitor visitor,
  File file,
  FileMode mode,
  String operation,
) {
  final canonicalPath = checkFilesystemWritePermission(
    visitor,
    file.path,
    operation: operation,
  );
  return SecureFileOpener.openWrite(canonicalPath, mode: mode);
}

Stream<List<int>> _secureOpenRead(
  SecureFileHandle handle,
  int? start,
  int? end,
) {
  late StreamSubscription<List<int>> subscription;
  late StreamController<List<int>> controller;

  controller = StreamController<List<int>>(
    onListen: () {
      try {
        subscription = File(handle.path)
            .openRead(start, end)
            .listen(
              controller.add,
              onError: controller.addError,
              onDone: () {
                handle.close();
                controller.close();
              },
            );
      } catch (error, stackTrace) {
        handle.close();
        controller.addError(error, stackTrace);
        controller.close();
      }
    },
    onPause: () => subscription.pause(),
    onResume: () => subscription.resume(),
    onCancel: () async {
      await subscription.cancel();
      handle.close();
    },
  );

  return controller.stream;
}

Future<void> _copySecureAsync(
  SecureFileHandle source,
  SecureFileHandle destination,
  int sourceMode,
) async {
  final input = await File(source.path).open(mode: FileMode.read);
  RandomAccessFile? output;
  try {
    if (File(source.path).statSync().type == FileSystemEntityType.directory) {
      throw FileSystemException('Cannot copy file', source.path);
    }
    output = await File(destination.path).open(mode: FileMode.write);
    while (true) {
      final chunk = await input.read(64 * 1024);
      if (chunk.isEmpty) break;
      await output.writeFrom(chunk);
    }
    await output.flush();
    SecureFileOpener.setMode(destination, sourceMode);
  } finally {
    await input.close();
    await output?.close();
  }
}

void _copySecureSync(
  SecureFileHandle source,
  SecureFileHandle destination,
  int sourceMode,
) {
  final input = File(source.path).openSync(mode: FileMode.read);
  RandomAccessFile? output;
  try {
    if (File(source.path).statSync().type == FileSystemEntityType.directory) {
      throw FileSystemException('Cannot copy file', source.path);
    }
    output = File(destination.path).openSync(mode: FileMode.write);
    while (true) {
      final chunk = input.readSync(64 * 1024);
      if (chunk.isEmpty) break;
      output.writeFromSync(chunk);
    }
    output.flushSync();
    SecureFileOpener.setMode(destination, sourceMode);
  } finally {
    input.closeSync();
    output?.closeSync();
  }
}

class FileIo {
  static BridgedClass get definition => BridgedClass(
    nativeType: File,
    name: 'File',
    typeParameterCount: 0,
    isSubtypeOfFunc: (value) => value is File,
    constructors: {
      '': (visitor, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
          throw RuntimeError(
            'File constructor requires one String argument (path).',
          );
        }
        return File(positionalArgs[0] as String);
      },
    },
    staticMethods: {
      'fromRawPath': (visitor, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! Uint8List) {
          throw RuntimeError(
            'File.fromRawPath requires one Uint8List argument.',
          );
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
      'exists': (visitor, target, positionalArgs, namedArgs) => (() {
        final file = target as File;
        checkFilesystemReadPermission(
          visitor,
          file.path,
          operation: 'check existence',
        );
        return file.exists();
      })(),
      'existsSync': (visitor, target, positionalArgs, namedArgs) => (() {
        final file = target as File;
        checkFilesystemReadPermission(
          visitor,
          file.path,
          operation: 'check existence',
        );
        return file.existsSync();
      })(),
      'readAsString': (visitor, target, positionalArgs, namedArgs) =>
          _withSecureReadAsync(
            visitor,
            target as File,
            'read file',
            (file) => file.readAsString(
              encoding: namedArgs['encoding'] as Encoding? ?? utf8,
            ),
          ),
      'readAsStringSync': (visitor, target, positionalArgs, namedArgs) =>
          _withSecureReadSync(
            visitor,
            target as File,
            'read file',
            (file) => file.readAsStringSync(
              encoding: namedArgs['encoding'] as Encoding? ?? utf8,
            ),
          ),
      'readAsBytes': (visitor, target, positionalArgs, namedArgs) =>
          _withSecureReadAsync(
            visitor,
            target as File,
            'read file',
            (file) => file.readAsBytes(),
          ),
      'readAsBytesSync': (visitor, target, positionalArgs, namedArgs) =>
          _withSecureReadSync(
            visitor,
            target as File,
            'read file',
            (file) => file.readAsBytesSync(),
          ),
      'readAsLines': (visitor, target, positionalArgs, namedArgs) =>
          _withSecureReadAsync(
            visitor,
            target as File,
            'read file',
            (file) => file.readAsLines(
              encoding: namedArgs['encoding'] as Encoding? ?? utf8,
            ),
          ),
      'readAsLinesSync': (visitor, target, positionalArgs, namedArgs) =>
          _withSecureReadSync(
            visitor,
            target as File,
            'read file',
            (file) => file.readAsLinesSync(
              encoding: namedArgs['encoding'] as Encoding? ?? utf8,
            ),
          ),
      'writeAsString': (visitor, target, positionalArgs, namedArgs) {
        final file = target as File;
        if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
          throw RuntimeError(
            'File.writeAsString requires one String argument (contents).',
          );
        }
        final mode = namedArgs['mode'] as FileMode? ?? FileMode.write;
        return _withSecureWriteAsync(
          visitor,
          file,
          mode,
          'write file',
          (securedFile) => securedFile.writeAsString(
            positionalArgs[0] as String,
            mode: mode,
            encoding: namedArgs['encoding'] as Encoding? ?? utf8,
            flush: namedArgs['flush'] as bool? ?? false,
          ),
        );
      },
      'writeAsStringSync': (visitor, target, positionalArgs, namedArgs) {
        final file = target as File;
        if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
          throw RuntimeError(
            'File.writeAsStringSync requires one String argument (contents).',
          );
        }
        final mode = namedArgs['mode'] as FileMode? ?? FileMode.write;
        _withSecureWriteSync(
          visitor,
          file,
          mode,
          'write file',
          (securedFile) => securedFile.writeAsStringSync(
            positionalArgs[0] as String,
            mode: mode,
            encoding: namedArgs['encoding'] as Encoding? ?? utf8,
            flush: namedArgs['flush'] as bool? ?? false,
          ),
        );
        return null;
      },
      'writeAsBytes': (visitor, target, positionalArgs, namedArgs) {
        final file = target as File;
        if (positionalArgs.length != 1 || positionalArgs[0] is! List) {
          throw RuntimeError(
            'File.writeAsBytes requires one List<int> argument (bytes).',
          );
        }
        final mode = namedArgs['mode'] as FileMode? ?? FileMode.write;
        return _withSecureWriteAsync(
          visitor,
          file,
          mode,
          'write file',
          (securedFile) => securedFile.writeAsBytes(
            (positionalArgs[0] as List).cast(),
            mode: mode,
            flush: namedArgs['flush'] as bool? ?? false,
          ),
        );
      },
      'writeAsBytesSync': (visitor, target, positionalArgs, namedArgs) {
        final file = target as File;
        if (positionalArgs.length != 1 || positionalArgs[0] is! List) {
          throw RuntimeError(
            'File.writeAsBytesSync requires one List<int> argument (bytes).',
          );
        }
        final mode = namedArgs['mode'] as FileMode? ?? FileMode.write;
        _withSecureWriteSync(
          visitor,
          file,
          mode,
          'write file',
          (securedFile) => securedFile.writeAsBytesSync(
            (positionalArgs[0] as List).cast(),
            mode: mode,
            flush: namedArgs['flush'] as bool? ?? false,
          ),
        );
        return null;
      },
      'delete': (visitor, target, positionalArgs, namedArgs) {
        final file = target as File;
        final targetInfo = checkFilesystemNamespaceWritePermission(
          visitor,
          file.path,
          operation: 'delete file',
        );
        if (SecureFileOpener.isSupported) {
          final securePath = p.join(targetInfo.parent, targetInfo.name);
          if (namedArgs['recursive'] as bool? ?? false) {
            SecureFileOpener.deletePathRecursive(securePath);
          } else {
            SecureFileOpener.deleteFile(securePath);
          }
          return Future<File>.value(file);
        }
        return file.delete(recursive: namedArgs['recursive'] as bool? ?? false);
      },
      'deleteSync': (visitor, target, positionalArgs, namedArgs) {
        final file = target as File;
        final targetInfo = checkFilesystemNamespaceWritePermission(
          visitor,
          file.path,
          operation: 'delete file',
        );
        if (SecureFileOpener.isSupported) {
          final securePath = p.join(targetInfo.parent, targetInfo.name);
          if (namedArgs['recursive'] as bool? ?? false) {
            SecureFileOpener.deletePathRecursive(securePath);
          } else {
            SecureFileOpener.deleteFile(securePath);
          }
          return null;
        }
        file.deleteSync(recursive: namedArgs['recursive'] as bool? ?? false);
        return null;
      },
      'rename': (visitor, target, positionalArgs, namedArgs) {
        final file = target as File;
        if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
          throw RuntimeError(
            'File.rename requires one String argument (newPath).',
          );
        }
        final newPath = positionalArgs[0] as String;
        final oldTarget = checkFilesystemNamespaceWritePermission(
          visitor,
          file.path,
          operation: 'rename file',
        );
        final newTarget = checkFilesystemNamespaceWritePermission(
          visitor,
          newPath,
          operation: 'rename file',
        );
        if (SecureFileOpener.isSupported) {
          SecureFileOpener.renamePath(
            p.join(oldTarget.parent, oldTarget.name),
            p.join(newTarget.parent, newTarget.name),
          );
          return Future<File>.value(File(newPath));
        }
        return file.rename(newPath);
      },
      'renameSync': (visitor, target, positionalArgs, namedArgs) {
        final file = target as File;
        if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
          throw RuntimeError(
            'File.renameSync requires one String argument (newPath).',
          );
        }
        final newPath = positionalArgs[0] as String;
        final oldTarget = checkFilesystemNamespaceWritePermission(
          visitor,
          file.path,
          operation: 'rename file',
        );
        final newTarget = checkFilesystemNamespaceWritePermission(
          visitor,
          newPath,
          operation: 'rename file',
        );
        if (SecureFileOpener.isSupported) {
          SecureFileOpener.renamePath(
            p.join(oldTarget.parent, oldTarget.name),
            p.join(newTarget.parent, newTarget.name),
          );
          return File(newPath);
        }
        return file.renameSync(newPath);
      },
      'copy': (visitor, target, positionalArgs, namedArgs) async {
        final file = target as File;
        if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
          throw RuntimeError(
            'File.copy requires one String argument (newPath).',
          );
        }
        final newPath = positionalArgs[0] as String;
        final sourcePath = checkFilesystemReadPermission(
          visitor,
          file.path,
          operation: 'copy file',
        );
        final destinationPath = checkFilesystemWritePermission(
          visitor,
          newPath,
          operation: 'copy file',
        );
        if (SecureFileOpener.isSupported) {
          if (sourcePath == destinationPath) {
            return File(newPath);
          }
          if (File(newPath).existsSync() &&
              FileSystemEntity.identicalSync(file.path, newPath)) {
            return File(newPath);
          }
          final sourceMode = File(file.path).statSync().mode;
          final source = SecureFileOpener.openRead(sourcePath);
          if (source != null &&
              File(source.path).statSync().type ==
                  FileSystemEntityType.directory) {
            source.close();
            throw FileSystemException('Cannot copy file', file.path);
          }
          final destination = SecureFileOpener.openWrite(
            destinationPath,
            mode: FileMode.write,
          );
          if (source != null && destination != null) {
            try {
              await _copySecureAsync(source, destination, sourceMode);
              return File(newPath);
            } finally {
              source.close();
              destination.close();
            }
          }
          source?.close();
          destination?.close();
        }
        return file.copy(newPath);
      },
      'copySync': (visitor, target, positionalArgs, namedArgs) {
        final file = target as File;
        if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
          throw RuntimeError(
            'File.copySync requires one String argument (newPath).',
          );
        }
        final newPath = positionalArgs[0] as String;
        final sourcePath = checkFilesystemReadPermission(
          visitor,
          file.path,
          operation: 'copy file',
        );
        final destinationPath = checkFilesystemWritePermission(
          visitor,
          newPath,
          operation: 'copy file',
        );
        if (SecureFileOpener.isSupported) {
          if (sourcePath == destinationPath) {
            return File(newPath);
          }
          if (File(newPath).existsSync() &&
              FileSystemEntity.identicalSync(file.path, newPath)) {
            return File(newPath);
          }
          final sourceMode = File(file.path).statSync().mode;
          final source = SecureFileOpener.openRead(sourcePath);
          if (source != null &&
              File(source.path).statSync().type ==
                  FileSystemEntityType.directory) {
            source.close();
            throw FileSystemException('Cannot copy file', file.path);
          }
          final destination = SecureFileOpener.openWrite(
            destinationPath,
            mode: FileMode.write,
          );
          if (source != null && destination != null) {
            try {
              _copySecureSync(source, destination, sourceMode);
              return File(newPath);
            } finally {
              source.close();
              destination.close();
            }
          }
          source?.close();
          destination?.close();
        }
        return file.copySync(newPath);
      },
      'length': (visitor, target, positionalArgs, namedArgs) =>
          _withSecureReadAsync(
            visitor,
            target as File,
            'read file metadata',
            (file) => file.length(),
          ),
      'lengthSync': (visitor, target, positionalArgs, namedArgs) =>
          _withSecureReadSync(
            visitor,
            target as File,
            'read file metadata',
            (file) => file.lengthSync(),
          ),
      'lastAccessed': (visitor, target, positionalArgs, namedArgs) =>
          _withSecureReadAsync(
            visitor,
            target as File,
            'read file metadata',
            (file) => file.lastAccessed(),
          ),
      'lastAccessedSync': (visitor, target, positionalArgs, namedArgs) =>
          _withSecureReadSync(
            visitor,
            target as File,
            'read file metadata',
            (file) => file.lastAccessedSync(),
          ),
      'setLastAccessed': (visitor, target, positionalArgs, namedArgs) {
        final file = target as File;
        if (positionalArgs.length != 1 || positionalArgs[0] is! DateTime) {
          throw RuntimeError(
            'File.setLastAccessed requires one DateTime argument.',
          );
        }
        checkFilesystemWritePermission(
          visitor,
          file.path,
          operation: 'write file metadata',
        );
        return file.setLastAccessed(positionalArgs[0] as DateTime);
      },
      'setLastAccessedSync': (visitor, target, positionalArgs, namedArgs) {
        final file = target as File;
        if (positionalArgs.length != 1 || positionalArgs[0] is! DateTime) {
          throw RuntimeError(
            'File.setLastAccessedSync requires one DateTime argument.',
          );
        }
        checkFilesystemWritePermission(
          visitor,
          file.path,
          operation: 'write file metadata',
        );
        file.setLastAccessedSync(positionalArgs[0] as DateTime);
        return null;
      },
      'lastModified': (visitor, target, positionalArgs, namedArgs) =>
          _withSecureReadAsync(
            visitor,
            target as File,
            'read file metadata',
            (file) => file.lastModified(),
          ),
      'lastModifiedSync': (visitor, target, positionalArgs, namedArgs) =>
          _withSecureReadSync(
            visitor,
            target as File,
            'read file metadata',
            (file) => file.lastModifiedSync(),
          ),
      'setLastModified': (visitor, target, positionalArgs, namedArgs) {
        final file = target as File;
        if (positionalArgs.length != 1 || positionalArgs[0] is! DateTime) {
          throw RuntimeError(
            'File.setLastModified requires one DateTime argument.',
          );
        }
        checkFilesystemWritePermission(
          visitor,
          file.path,
          operation: 'write file metadata',
        );
        return file.setLastModified(positionalArgs[0] as DateTime);
      },
      'setLastModifiedSync': (visitor, target, positionalArgs, namedArgs) {
        final file = target as File;
        if (positionalArgs.length != 1 || positionalArgs[0] is! DateTime) {
          throw RuntimeError(
            'File.setLastModifiedSync requires one DateTime argument.',
          );
        }
        checkFilesystemWritePermission(
          visitor,
          file.path,
          operation: 'write file metadata',
        );
        file.setLastModifiedSync(positionalArgs[0] as DateTime);
        return null;
      },
      'open': (visitor, target, positionalArgs, namedArgs) async {
        final file = target as File;
        final mode = namedArgs['mode'] as FileMode? ?? FileMode.read;
        final handle = mode == FileMode.read
            ? _secureReadHandle(visitor, file, 'open file')
            : _secureWriteHandle(visitor, file, mode, 'open file');
        if (handle == null) return file.open(mode: mode);

        try {
          final randomAccessFile = await File(handle.path).open(mode: mode);
          _originalRandomAccessFilePaths[randomAccessFile] = file.path;
          return randomAccessFile;
        } finally {
          handle.close();
        }
      },
      'openSync': (visitor, target, positionalArgs, namedArgs) {
        final file = target as File;
        final mode = namedArgs['mode'] as FileMode? ?? FileMode.read;
        final handle = mode == FileMode.read
            ? _secureReadHandle(visitor, file, 'open file')
            : _secureWriteHandle(visitor, file, mode, 'open file');
        if (handle == null) return file.openSync(mode: mode);

        try {
          final randomAccessFile = File(handle.path).openSync(mode: mode);
          _originalRandomAccessFilePaths[randomAccessFile] = file.path;
          return randomAccessFile;
        } finally {
          handle.close();
        }
      },
      'openRead': (visitor, target, positionalArgs, namedArgs) {
        final file = target as File;
        final handle = _secureReadHandle(visitor, file, 'open file');
        if (handle == null) {
          return file.openRead(
            positionalArgs.isNotEmpty ? positionalArgs[0] as int? : null,
            positionalArgs.length > 1 ? positionalArgs[1] as int? : null,
          );
        }

        return _secureOpenRead(
          handle,
          positionalArgs.isNotEmpty ? positionalArgs[0] as int? : null,
          positionalArgs.length > 1 ? positionalArgs[1] as int? : null,
        );
      },
      'openWrite': (visitor, target, positionalArgs, namedArgs) {
        final file = target as File;
        final mode = namedArgs['mode'] as FileMode? ?? FileMode.write;
        final handle = _secureWriteHandle(visitor, file, mode, 'open file');
        if (handle == null) {
          return file.openWrite(
            mode: mode,
            encoding: namedArgs['encoding'] as Encoding? ?? utf8,
          );
        }

        try {
          final sink = File(handle.path).openWrite(
            mode: mode,
            encoding: namedArgs['encoding'] as Encoding? ?? utf8,
          );
          sink.done.then<void>(
            (_) => handle.close(),
            onError: (Object _, StackTrace _) => handle.close(),
          );
          return sink;
        } catch (_) {
          handle.close();
          rethrow;
        }
      },
      'stat': (visitor, target, positionalArgs, namedArgs) => (() {
        final file = target as File;
        checkFilesystemReadPermission(
          visitor,
          file.path,
          operation: 'stat file',
        );
        return file.stat();
      })(),
      'statSync': (visitor, target, positionalArgs, namedArgs) => (() {
        final file = target as File;
        checkFilesystemReadPermission(
          visitor,
          file.path,
          operation: 'stat file',
        );
        return file.statSync();
      })(),
      'resolveSymbolicLinks': (visitor, target, positionalArgs, namedArgs) {
        final file = target as File;
        checkFilesystemReadPermission(
          visitor,
          file.path,
          operation: 'resolve file links',
        );
        return file.resolveSymbolicLinks();
      },
      'resolveSymbolicLinksSync': (visitor, target, positionalArgs, namedArgs) {
        final file = target as File;
        checkFilesystemReadPermission(
          visitor,
          file.path,
          operation: 'resolve file links',
        );
        return file.resolveSymbolicLinksSync();
      },
      'create': (visitor, target, positionalArgs, namedArgs) {
        final file = target as File;
        final targetInfo = checkFilesystemNamespaceWritePermission(
          visitor,
          file.path,
          operation: 'create file',
        );
        if (SecureFileOpener.isSupported) {
          SecureFileOpener.createFile(
            p.join(targetInfo.parent, targetInfo.name),
            recursive: namedArgs['recursive'] as bool? ?? false,
            exclusive: namedArgs['exclusive'] as bool? ?? false,
          );
          return Future<File>.value(file);
        }
        return file.create(
          recursive: namedArgs['recursive'] as bool? ?? false,
          exclusive: namedArgs['exclusive'] as bool? ?? false,
        );
      },
      'createSync': (visitor, target, positionalArgs, namedArgs) {
        final file = target as File;
        final targetInfo = checkFilesystemNamespaceWritePermission(
          visitor,
          file.path,
          operation: 'create file',
        );
        if (SecureFileOpener.isSupported) {
          SecureFileOpener.createFile(
            p.join(targetInfo.parent, targetInfo.name),
            recursive: namedArgs['recursive'] as bool? ?? false,
            exclusive: namedArgs['exclusive'] as bool? ?? false,
          );
          return null;
        }
        file.createSync(
          recursive: namedArgs['recursive'] as bool? ?? false,
          exclusive: namedArgs['exclusive'] as bool? ?? false,
        );
        return null;
      },
      'watch': (visitor, target, positionalArgs, namedArgs) => (() {
        final file = target as File;
        checkFilesystemReadPermission(
          visitor,
          file.path,
          operation: 'watch file',
        );
        return file
            .watch(
              events: namedArgs['events'] as int? ?? FileSystemEvent.all,
              recursive: namedArgs['recursive'] as bool? ?? false,
            )
            .map((event) {
              checkFilesystemReadPermission(
                visitor,
                event.path,
                operation: 'watch file',
              );
              return event;
            });
      })(),
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
