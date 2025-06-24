import 'dart:io';
import 'dart:typed_data';
import 'package:d4rt/d4rt.dart';

class DirectoryIo {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: Directory,
        name: 'Directory',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'Directory constructor requires one String argument (path).');
            }
            return Directory(positionalArgs[0] as String);
          },
        },
        staticMethods: {
          'fromRawPath': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! Uint8List) {
              throw RuntimeError(
                  'Directory.fromRawPath requires one Uint8List argument.');
            }
            return Directory.fromRawPath(positionalArgs[0] as Uint8List);
          },
          'fromUri': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! Uri) {
              throw RuntimeError(
                  'Directory.fromUri requires one Uri argument.');
            }
            return Directory.fromUri(positionalArgs[0] as Uri);
          },
        },
        methods: {
          'exists': (visitor, target, positionalArgs, namedArgs) {
            return (target as Directory).exists();
          },
          'existsSync': (visitor, target, positionalArgs, namedArgs) {
            return (target as Directory).existsSync();
          },
          'create': (visitor, target, positionalArgs, namedArgs) {
            return (target as Directory)
                .create(recursive: namedArgs['recursive'] as bool? ?? false);
          },
          'createSync': (visitor, target, positionalArgs, namedArgs) {
            (target as Directory).createSync(
                recursive: namedArgs['recursive'] as bool? ?? false);
            return null;
          },
          'delete': (visitor, target, positionalArgs, namedArgs) {
            return (target as Directory)
                .delete(recursive: namedArgs['recursive'] as bool? ?? false);
          },
          'deleteSync': (visitor, target, positionalArgs, namedArgs) {
            (target as Directory).deleteSync(
                recursive: namedArgs['recursive'] as bool? ?? false);
            return null;
          },
          'list': (visitor, target, positionalArgs, namedArgs) {
            return (target as Directory).list(
                recursive: namedArgs['recursive'] as bool? ?? false,
                followLinks: namedArgs['followLinks'] as bool? ?? true);
          },
          'listSync': (visitor, target, positionalArgs, namedArgs) {
            return (target as Directory).listSync(
                recursive: namedArgs['recursive'] as bool? ?? false,
                followLinks: namedArgs['followLinks'] as bool? ?? true);
          },
          'rename': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'Directory.rename requires one String argument (newPath).');
            }
            return (target as Directory).rename(positionalArgs[0] as String);
          },
          'renameSync': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'Directory.renameSync requires one String argument (newPath).');
            }
            (target as Directory).renameSync(positionalArgs[0] as String);
            return null;
          },
          'stat': (visitor, target, positionalArgs, namedArgs) {
            return (target as Directory).stat();
          },
          'statSync': (visitor, target, positionalArgs, namedArgs) {
            return (target as Directory).statSync();
          },
          'watch': (visitor, target, positionalArgs, namedArgs) {
            return (target as Directory).watch(
                events: namedArgs['events'] as int? ?? FileSystemEvent.all,
                recursive: namedArgs['recursive'] as bool? ?? false);
          },
          'resolveSymbolicLinks': (visitor, target, positionalArgs, namedArgs) {
            return (target as Directory).resolveSymbolicLinks();
          },
          'resolveSymbolicLinksSync':
              (visitor, target, positionalArgs, namedArgs) {
            return (target as Directory).resolveSymbolicLinksSync();
          },
          'createTemp': (visitor, target, positionalArgs, namedArgs) {
            return (target as Directory).createTemp(positionalArgs.isNotEmpty
                ? positionalArgs[0] as String?
                : null);
          },
          'createTempSync': (visitor, target, positionalArgs, namedArgs) {
            return (target as Directory).createTempSync(
                positionalArgs.isNotEmpty
                    ? positionalArgs[0] as String?
                    : null);
          },
        },
        getters: {
          'path': (visitor, target) => (target as Directory).path,
          'absolute': (visitor, target) => (target as Directory).absolute,
          'uri': (visitor, target) => (target as Directory).uri,
          'parent': (visitor, target) => (target as Directory).parent,
          'isAbsolute': (visitor, target) => (target as Directory).isAbsolute,
        },
        staticGetters: {
          'systemTemp': (visitor) => Directory.systemTemp,
          'current': (visitor) => Directory.current,
        },
        staticSetters: {
          'current': (visitor, value) {
            Directory.current = value;
            return;
          },
        },
      );
}
