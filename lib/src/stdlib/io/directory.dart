import 'dart:io';
import 'dart:typed_data'; // For Uint8List
import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart';
import 'package:d4rt/src/utils/extensions/map.dart'; // For named args

class DirectoryIo implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'Directory',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return arguments.isNotEmpty
              ? Directory(arguments[0] as String)
              : Directory;
        }, arity: 1, name: 'Directory'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is Directory) {
      switch (name) {
        case 'exists':
          return target.exists();
        case 'existsSync':
          return target.existsSync();
        case 'create':
          return target.create(
              recursive: namedArguments.get<bool?>('recursive') ?? false);
        case 'createSync':
          target.createSync(
              recursive: namedArguments.get<bool?>('recursive') ?? false);
          return null; // Sync methods often return void
        case 'delete':
          return target.delete(
              recursive: namedArguments.get<bool?>('recursive') ?? false);
        case 'deleteSync':
          target.deleteSync(
              recursive: namedArguments.get<bool?>('recursive') ?? false);
          return null;
        case 'list':
          return target.list(
              recursive: namedArguments.get<bool?>('recursive') ?? false,
              followLinks: namedArguments.get<bool?>('followLinks') ?? true);
        case 'listSync':
          return target.listSync(
              recursive: namedArguments.get<bool?>('recursive') ?? false,
              followLinks: namedArguments.get<bool?>('followLinks') ?? true);
        case 'path': // Getter
          return target.path;
        case 'rename':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'Directory.rename requires one String argument (newPath).');
          }
          return target.rename(arguments[0] as String);
        case 'renameSync':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'Directory.renameSync requires one String argument (newPath).');
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
        case 'resolveSymbolicLinks':
          return target.resolveSymbolicLinks();
        case 'resolveSymbolicLinksSync':
          return target.resolveSymbolicLinksSync();
        case 'createTemp': // Added async version
          return target.createTemp(arguments.get<String?>(0));
        case 'createTempSync':
          return target.createTempSync(arguments.get<String?>(0));
        // Methods from FileSystemEntity
        case 'isAbsolute': // Getter
          return target.isAbsolute;
        case 'runtimeType': // From Object
          return target.runtimeType;
        case 'hashCode': // From Object
          return target.hashCode;
        case 'toString': // From Object
          return target.toString();
        default:
          throw RuntimeError(
              'Directory has no method/getter mapping for "$name"');
      }
    } else {
      // Static methods/getters for Directory
      switch (name) {
        case 'systemTemp': // Static Getter
          return Directory.systemTemp;
        case 'current': // Static Getter/Setter
          if (arguments.isEmpty && namedArguments.isEmpty) {
            // Getter
            return Directory.current;
          } else {
            // Setter
            if (arguments.length != 1 ||
                (arguments[0] is! String && arguments[0] is! Directory)) {
              throw RuntimeError(
                  'Directory.current setter requires one String or Directory argument.');
            }
            Directory.current = arguments[0]!;
            return null;
          }
        case 'fromRawPath': // Static Factory
          if (arguments.length != 1 || arguments[0] is! Uint8List) {
            throw RuntimeError(
                'Directory.fromRawPath requires one Uint8List argument.');
          }
          return Directory.fromRawPath(arguments[0] as Uint8List);
        case 'fromUri': // Static Factory
          if (arguments.length != 1 || arguments[0] is! Uri) {
            throw RuntimeError('Directory.fromUri requires one Uri argument.');
          }
          return Directory.fromUri(arguments[0] as Uri);
        default:
          throw RuntimeError(
              'Directory has no static method/getter mapping for "$name"');
      }
    }
  }
}
