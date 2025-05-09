import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart';
import 'package:d4rt/src/utils/extensions/map.dart';

class FileIo implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'File',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'File constructor requires one String argument (path).');
          }
          return File(arguments[0] as String);
        }, arity: 1, name: 'File'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is File) {
      switch (name) {
        case 'exists':
          return target.exists();
        case 'existsSync':
          return target.existsSync();
        case 'readAsString':
          return target.readAsString(
              encoding: namedArguments.get<Encoding?>('encoding') ?? utf8);
        case 'readAsStringSync':
          return target.readAsStringSync(
              encoding: namedArguments.get<Encoding?>('encoding') ?? utf8);
        case 'readAsBytes':
          return target.readAsBytes();
        case 'readAsBytesSync':
          return target.readAsBytesSync();
        case 'readAsLines':
          return target.readAsLines(
              encoding: namedArguments.get<Encoding?>('encoding') ?? utf8);
        case 'readAsLinesSync':
          return target.readAsLinesSync(
              encoding: namedArguments.get<Encoding?>('encoding') ?? utf8);
        case 'writeAsString':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'File.writeAsString requires one String argument (contents).');
          }
          return target.writeAsString(arguments[0] as String,
              mode: namedArguments.get<FileMode?>('mode') ?? FileMode.write,
              encoding: namedArguments.get<Encoding?>('encoding') ?? utf8,
              flush: namedArguments.get<bool?>('flush') ?? false);
        case 'writeAsStringSync':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'File.writeAsStringSync requires one String argument (contents).');
          }
          target.writeAsStringSync(arguments[0] as String,
              mode: namedArguments.get<FileMode?>('mode') ?? FileMode.write,
              encoding: namedArguments.get<Encoding?>('encoding') ?? utf8,
              flush: namedArguments.get<bool?>('flush') ?? false);
          return null;
        case 'writeAsBytes':
          if (arguments.length != 1 || arguments[0] is! List) {
            throw RuntimeError(
                'File.writeAsBytes requires one List<int> argument (bytes).');
          }
          return target.writeAsBytes((arguments[0] as List).cast(),
              mode: namedArguments.get<FileMode?>('mode') ?? FileMode.write,
              flush: namedArguments.get<bool?>('flush') ?? false);
        case 'writeAsBytesSync':
          if (arguments.length != 1 || arguments[0] is! List) {
            throw RuntimeError(
                'File.writeAsBytesSync requires one List<int> argument (bytes).');
          }
          target.writeAsBytesSync((arguments[0] as List).cast(),
              mode: namedArguments.get<FileMode?>('mode') ?? FileMode.write,
              flush: namedArguments.get<bool?>('flush') ?? false);
          return null;
        case 'deleteSync':
          target.deleteSync(
              recursive: namedArguments.get<bool?>('recursive') ?? false);
          return null;
        case 'delete':
          return target.delete(
              recursive: namedArguments.get<bool?>('recursive') ?? false);
        case 'rename':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'File.rename requires one String argument (newPath).');
          }
          return target.rename(arguments[0] as String);
        case 'renameSync':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'File.renameSync requires one String argument (newPath).');
          }
          return target.renameSync(arguments[0] as String);

        case 'copy':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'File.copy requires one String argument (newPath).');
          }
          return target.copy(arguments[0] as String);
        case 'copySync':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'File.copySync requires one String argument (newPath).');
          }
          return target.copySync(arguments[0] as String);
        case 'length':
          return target.length();
        case 'lengthSync':
          return target.lengthSync();
        case 'path':
          return target.path;
        case 'lastAccessed':
          return target.lastAccessed();
        case 'lastAccessedSync':
          return target.lastAccessedSync();
        case 'setLastAccessed':
          if (arguments.length != 1 || arguments[0] is! DateTime) {
            throw RuntimeError(
                'File.setLastAccessed requires one DateTime argument.');
          }
          return target.setLastAccessed(arguments[0] as DateTime);
        case 'setLastAccessedSync':
          if (arguments.length != 1 || arguments[0] is! DateTime) {
            throw RuntimeError(
                'File.setLastAccessedSync requires one DateTime argument.');
          }
          target.setLastAccessedSync(arguments[0] as DateTime);
          return null;
        case 'lastModified':
          return target.lastModified();
        case 'lastModifiedSync':
          return target.lastModifiedSync();
        case 'setLastModified':
          if (arguments.length != 1 || arguments[0] is! DateTime) {
            throw RuntimeError(
                'File.setLastModified requires one DateTime argument.');
          }
          return target.setLastModified(arguments[0] as DateTime);
        case 'setLastModifiedSync':
          if (arguments.length != 1 || arguments[0] is! DateTime) {
            throw RuntimeError(
                'File.setLastModifiedSync requires one DateTime argument.');
          }
          target.setLastModifiedSync(arguments[0] as DateTime);
          return null;
        case 'open':
          return target.open(
              mode: namedArguments.get<FileMode?>('mode') ?? FileMode.read);
        case 'openSync':
          return target.openSync(
              mode: namedArguments.get<FileMode?>('mode') ?? FileMode.read);
        case 'openRead':
          return target.openRead(
              arguments.get<int?>(0), arguments.get<int?>(1));
        case 'openWrite':
          return target.openWrite(
            mode: namedArguments.get<FileMode?>('mode') ?? FileMode.write,
            encoding: namedArguments.get<Encoding?>('encoding') ?? utf8,
          );
        case 'stat':
          return target.stat();
        case 'resolveSymbolicLinks':
          return target.resolveSymbolicLinks();
        case 'resolveSymbolicLinksSync':
          return target.resolveSymbolicLinksSync();
        case 'statSync':
          return target.statSync();
        case 'absolute':
          return target.absolute;
        case 'parent':
          return target.parent;
        case 'create':
          return target.create(
              recursive: namedArguments.get<bool?>('recursive') ?? false);
        case 'createSync':
          target.createSync(
              recursive: namedArguments.get<bool?>('recursive') ?? false);
          return null;
        case 'isAbsolute':
          return target.isAbsolute;
        case 'runtimeType':
          return target.runtimeType;
        case 'hashCode':
          return target.hashCode;
        case 'toString':
          return target.toString();
        case 'uri':
          return target.uri;
        case 'watch':
          return target.watch(
              events: namedArguments.get<int?>('events') ?? FileSystemEvent.all,
              recursive: namedArguments.get<bool?>('recursive') ?? false);
        default:
          throw RuntimeError('File has no method/getter mapping for "$name"');
      }
    } else {
      switch (name) {
        case 'fromRawPath':
          if (arguments.length != 1 || arguments[0] is! Uint8List) {
            throw RuntimeError(
                'File.fromRawPath requires one Uint8List argument.');
          }
          return File.fromRawPath(arguments[0] as Uint8List);
        case 'fromUri':
          if (arguments.length != 1 || arguments[0] is! Uri) {
            throw RuntimeError('File.fromUri requires one Uri argument.');
          }
          return File.fromUri(arguments[0] as Uri);
        default:
          throw RuntimeError(
              'File has no static method/getter mapping for "$name"');
      }
    }
  }
}
