import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:d4rt/d4rt.dart';

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
              (target as File)
                  .create(recursive: namedArgs['recursive'] as bool? ?? false),
          'createSync': (visitor, target, positionalArgs, namedArgs) {
            (target as File).createSync(
                recursive: namedArgs['recursive'] as bool? ?? false);
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
