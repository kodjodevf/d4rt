import 'dart:io';
import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/map.dart'; // For named args

class FileSystemEntityIo implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Define abstract type names
    environment.define(
        'FileSystemEntity',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return FileSystemEntity; // Abstract class
        }, arity: 0, name: 'FileSystemEntity'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is FileSystemEntity) {
      switch (name) {
        case 'exists':
          return target.exists();
        case 'existsSync':
          return target.existsSync();
        case 'delete':
          return target.delete(
              recursive: namedArguments.get<bool?>('recursive') ?? false);
        case 'deleteSync':
          target.deleteSync(
              recursive: namedArguments.get<bool?>('recursive') ?? false);
          return null;
        case 'rename':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'FileSystemEntity.rename requires one String argument (newPath).');
          }
          return target.rename(arguments[0] as String);
        case 'renameSync':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'FileSystemEntity.renameSync requires one String argument (newPath).');
          }
          target.renameSync(arguments[0] as String);
          return null;
        case 'stat':
          return target.stat();
        case 'statSync':
          return target.statSync();
        case 'watch':
          return target.watch(
              events: namedArguments.get<int?>('events') ?? FileSystemEvent.all,
              recursive: namedArguments.get<bool?>('recursive') ?? false);
        case 'absolute': // Getter
          return target.absolute;
        case 'uri': // Getter
          return target.uri;
        case 'parent': // Getter
          return target.parent;
        case 'path': // Getter
          return target.path;
        case 'isAbsolute': // Getter
          return target.isAbsolute;
        case 'resolveSymbolicLinks':
          return target.resolveSymbolicLinks();
        case 'resolveSymbolicLinksSync':
          return target.resolveSymbolicLinksSync();
        // Common Object methods
        case 'runtimeType':
          return target.runtimeType;
        case 'hashCode':
          return target.hashCode;
        case 'toString':
          return target.toString();
        default:
          throw RuntimeError(
              'FileSystemEntity has no method/getter mapping for "$name"');
      }
    } else {
      // Handle top-level static methods related to FileSystemEntity
      switch (name) {
        case 'identical':
          if (arguments.length != 2 ||
              arguments[0] is! String ||
              arguments[1] is! String) {
            throw RuntimeError(
                'FileSystemEntity.identical requires two String arguments (path1, path2).');
          }
          return FileSystemEntity.identical(
              arguments[0] as String, arguments[1] as String);
        case 'identicalSync':
          if (arguments.length != 2 ||
              arguments[0] is! String ||
              arguments[1] is! String) {
            throw RuntimeError(
                'FileSystemEntity.identicalSync requires two String arguments (path1, path2).');
          }
          return FileSystemEntity.identicalSync(
              arguments[0] as String, arguments[1] as String);
        case 'isDirectory':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'FileSystemEntity.isDirectory requires one String argument (path).');
          }
          return FileSystemEntity.isDirectory(arguments[0] as String);
        case 'isDirectorySync':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'FileSystemEntity.isDirectorySync requires one String argument (path).');
          }
          return FileSystemEntity.isDirectorySync(arguments[0] as String);
        case 'isFile':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'FileSystemEntity.isFile requires one String argument (path).');
          }
          return FileSystemEntity.isFile(arguments[0] as String);
        case 'isFileSync':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'FileSystemEntity.isFileSync requires one String argument (path).');
          }
          return FileSystemEntity.isFileSync(arguments[0] as String);
        case 'isLink':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'FileSystemEntity.isLink requires one String argument (path).');
          }
          return FileSystemEntity.isLink(arguments[0] as String);
        case 'isLinkSync':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'FileSystemEntity.isLinkSync requires one String argument (path).');
          }
          return FileSystemEntity.isLinkSync(arguments[0] as String);
        case 'type':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'FileSystemEntity.type requires one String argument (path).');
          }
          return FileSystemEntity.type(arguments[0] as String,
              followLinks: namedArguments.get<bool?>('followLinks') ?? true);
        case 'typeSync':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'FileSystemEntity.typeSync requires one String argument (path).');
          }
          return FileSystemEntity.typeSync(arguments[0] as String,
              followLinks: namedArguments.get<bool?>('followLinks') ?? true);

        default:
          throw RuntimeError(
              'FileSystemEntity static scope has no mapping for "$name"');
      }
    }
  }
}

class FileStatIo implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'FileStat',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return FileStat; // Usually obtained from stat()
        }, arity: 0, name: 'FileStat'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is FileStat) {
      switch (name) {
        case 'accessed': // Getter
          return target.accessed;
        case 'changed': // Getter
          return target.changed;
        case 'mode': // Getter
          return target.mode;
        case 'modified': // Getter
          return target.modified;
        case 'size': // Getter
          return target.size;
        case 'type': // Getter
          return target.type;
        case 'modeString': // Added method
          return target.modeString();
        // Common Object methods
        case 'runtimeType':
          return target.runtimeType;
        case 'hashCode':
          return target.hashCode;
        case 'toString':
          return target.toString();
        default:
          throw RuntimeError(
              'FileStat has no method/getter mapping for "$name"');
      }
    }

    throw RuntimeError(
        'Unsupported target for FileStat: ${target.runtimeType}');
  }
}

class FileSystemEntityTypeIo implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'FileSystemEntityType',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return FileSystemEntityType; // Container for static constants
        }, arity: 0, name: 'FileSystemEntityType'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    switch (name) {
      case 'file':
        return FileSystemEntityType.file;
      case 'directory':
        return FileSystemEntityType.directory;
      case 'link':
        return FileSystemEntityType.link;
      case 'notFound':
        return FileSystemEntityType.notFound;
      default:
        throw RuntimeError(
            'FileSystemEntityType has no static mapping for "$name"');
    }
  }
}

class FileSystemEventIo implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'FileSystemEvent',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return FileSystemEvent; // Abstract, container for constants
        }, arity: 0, name: 'FileSystemEvent'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is FileSystemEvent) {
      // Handle events (e.g., isCreate, isModify, path, type)
      switch (name) {
        case 'isCreate':
          return target.type == FileSystemEvent.create;
        case 'isModify':
          return target.type == FileSystemEvent.modify;
        case 'isDelete':
          return target.type == FileSystemEvent.delete;
        case 'isMove':
          return target.type == FileSystemEvent.move;
        case 'path':
          return target.path;
        case 'type':
          return target.type;
        default:
          throw RuntimeError(
              'FileSystemEvent has no property mapping for "$name"');
      }
    }

    throw RuntimeError(
        'Unsupported target for FileSystemEvent: ${target.runtimeType}');
  }
}
