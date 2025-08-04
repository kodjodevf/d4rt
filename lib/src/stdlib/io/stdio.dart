import 'dart:io';
import 'dart:convert';
import 'package:d4rt/d4rt.dart';

class StdinIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: Stdin,
        name: 'Stdin',
        typeParameterCount: 0,
        methods: {
          'readLineSync': (visitor, target, positionalArgs, namedArgs) =>
              (target as Stdin).readLineSync(
                  encoding:
                      namedArgs['encoding'] as Encoding? ?? systemEncoding,
                  retainNewlines:
                      namedArgs['retainNewlines'] as bool? ?? false),
          'readByteSync': (visitor, target, positionalArgs, namedArgs) =>
              (target as Stdin).readByteSync(),
          'listen': (visitor, target, positionalArgs, namedArgs) {
            final stdin = target as Stdin;
            final onData = positionalArgs[0] as InterpretedFunction?;
            final onError = namedArgs['onError'] as InterpretedFunction?;
            final onDone = namedArgs['onDone'] as InterpretedFunction?;
            final cancelOnError = namedArgs['cancelOnError'] as bool?;

            if (onData == null) {
              throw RuntimeError('listen requires an onData callback.');
            }

            return stdin.listen(
              (data) => onData.call(visitor, [data]),
              onError: onError == null
                  ? null
                  : (error, stackTrace) =>
                      onError.call(visitor, [error, stackTrace]),
              onDone: onDone == null ? null : () => onDone.call(visitor, []),
              cancelOnError: cancelOnError,
            );
          },
        },
        getters: {
          'hasTerminal': (visitor, target) => (target as Stdin).hasTerminal,
          'echoMode': (visitor, target) => (target as Stdin).echoMode,
          'lineMode': (visitor, target) => (target as Stdin).lineMode,
          'echoNewlineMode': (visitor, target) =>
              (target as Stdin).echoNewlineMode,
        },
      );
}

class StdoutIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: Stdout,
        name: 'Stdout',
        typeParameterCount: 0,
        constructors: {},
        methods: {
          'write': (visitor, target, positionalArgs, namedArgs) {
            (target as Stdout).write(positionalArgs[0]);
            return null;
          },
          'writeln': (visitor, target, positionalArgs, namedArgs) {
            (target as Stdout)
                .writeln(positionalArgs.isNotEmpty ? positionalArgs[0] : '');
            return null;
          },
          'writeAll': (visitor, target, positionalArgs, namedArgs) {
            final stdout = target as Stdout;
            if (positionalArgs.isEmpty || positionalArgs[0] is! Iterable) {
              throw RuntimeError('writeAll requires an Iterable argument.');
            }
            stdout.writeAll(
              positionalArgs[0] as Iterable<dynamic>,
              positionalArgs.length > 1 ? positionalArgs[1] as String : '',
            );
            return null;
          },
          'add': (visitor, target, positionalArgs, namedArgs) {
            final stdout = target as Stdout;
            if (positionalArgs.length != 1 || positionalArgs[0] is! List) {
              throw RuntimeError('add requires a List<int> argument.');
            }
            stdout.add(positionalArgs[0] as List<int>);
            return null;
          },
          'addStream': (visitor, target, positionalArgs, namedArgs) {
            final stdout = target as Stdout;
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Stream<List<int>>) {
              throw RuntimeError(
                  'addStream requires a Stream<List<int>> argument.');
            }
            return stdout.addStream(positionalArgs[0] as Stream<List<int>>);
          },
          'flush': (visitor, target, positionalArgs, namedArgs) =>
              (target as Stdout).flush(),
          'close': (visitor, target, positionalArgs, namedArgs) =>
              (target as Stdout).close(),
          'addError': (visitor, target, positionalArgs, namedArgs) {
            final stdout = target as Stdout;
            if (positionalArgs.isEmpty) {
              throw RuntimeError(
                  'addError requires at least one argument (error).');
            }
            stdout.addError(
              positionalArgs[0]!,
              positionalArgs.length > 1
                  ? positionalArgs[1] as StackTrace?
                  : null,
            );
            return null;
          },
          'toString': (visitor, target, positionalArgs, namedArgs) =>
              (target as Stdout).toString(),
        },
        getters: {
          'encoding': (visitor, target) => (target as Stdout).encoding,
          'done': (visitor, target) => (target as Stdout).done,
          'supportsAnsiEscapes': (visitor, target) =>
              (target as Stdout).supportsAnsiEscapes,
          'terminalLines': (visitor, target) =>
              (target as Stdout).terminalLines,
          'terminalColumns': (visitor, target) =>
              (target as Stdout).terminalColumns,
          'hasTerminal': (visitor, target) => (target as Stdout).hasTerminal,
          'runtimeType': (visitor, target) => (target as Stdout).runtimeType,
          'hashCode': (visitor, target) => (target as Stdout).hashCode,
        },
        setters: {
          'encoding': (visitor, target, value) {
            if (value is! Encoding) {
              throw RuntimeError(
                  'encoding setter requires an Encoding argument.');
            }
            (target as Stdout).encoding = value;
            return;
          },
        },
      );
}

class StdioTypeIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: StdioType,
        name: 'StdioType',
        typeParameterCount: 0,
        getters: {
          'terminal': (visitor, target) => StdioType.terminal,
          'pipe': (visitor, target) => StdioType.pipe,
          'file': (visitor, target) => StdioType.file,
          'other': (visitor, target) => StdioType.other,
        },
      );
}

class IoStdioStdlib {
  static void register(Environment environment) {
    // Register classes
    environment.defineBridge(StdinIo.definition);
    environment.defineBridge(StdoutIo.definition);
    environment.defineBridge(StdioTypeIo.definition);
    environment.define('stdin', stdin);
    environment.define('stdout', stdout);
    environment.define('stderr', stderr);
  }
}
