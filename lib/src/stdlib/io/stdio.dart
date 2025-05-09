import 'dart:io';
import 'dart:async'; // For Future/Stream
import 'dart:convert'; // For Encoding

import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart'; // For safe list access
import 'package:d4rt/src/utils/extensions/map.dart'; // For named args

class StdinIo implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Define global instances
    environment.define('stdin', stdin);
    environment.define('stdin', stdin);
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is Stdin) {
      // Methods specific to Stdin + Stream methods
      switch (name) {
        case 'readLineSync':
          return target.readLineSync(
              encoding:
                  namedArguments.get<Encoding?>('encoding') ?? systemEncoding,
              retainNewlines:
                  namedArguments.get<bool?>('retainNewlines') ?? false);
        case 'readByteSync':
          return target.readByteSync();
        case 'hasTerminal': // Getter
          return target.hasTerminal;
        case 'echoMode':
          return target.echoMode;
        case 'lineMode':
          return target.lineMode;
        case 'echoNewlineMode': // Added getter/setter
          return target.echoNewlineMode;
        // Inherited Stream methods (handle common ones)
        case 'listen':
          final onData = arguments.get<InterpretedFunction?>(0);
          final onError = namedArguments.get<InterpretedFunction?>('onError');
          final onDone = namedArguments.get<InterpretedFunction?>('onDone');
          final cancelOnError = namedArguments.get<bool?>('cancelOnError');
          if (onData == null) {
            throw RuntimeError('listen requires an onData callback.');
          }
          // Return the StreamSubscription
          return target.listen((data) => onData.call(visitor, [data]),
              onError: onError == null
                  ? null
                  : (error, stackTrace) =>
                      onError.call(visitor, [error, stackTrace]),
              onDone: onDone == null ? null : () => onDone.call(visitor, []),
              cancelOnError: cancelOnError);
        // Add other Stream methods as needed (e.g., map, where, etc.)
        default:
          throw RuntimeError('Stdin has no method/getter mapping for "$name"');
      }
    } else {
      throw RuntimeError(
          'Unsupported target for StdinIo: ${target.runtimeType}');
    }
  }
}

class StdoutIo implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Define global instances
    environment.define('stdout', stdout);
    environment.define('stderr', stderr);
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is Stdout) {
      // Covers both stdout and stderr
      // Methods for IOSink
      switch (name) {
        case 'write':
          target.write(arguments.get<Object?>(0));
          return null;
        case 'writeln':
          target.writeln(arguments.get<Object?>(0) ?? '');
          return null;
        case 'writeAll':
          if (arguments.isEmpty || arguments[0] is! Iterable) {
            throw RuntimeError('writeAll requires an Iterable argument.');
          }
          target.writeAll(arguments[0] as Iterable<dynamic>,
              arguments.get<String?>(1) ?? '');
          return null;
        case 'add':
          if (arguments.length != 1 || arguments[0] is! List) {
            throw RuntimeError('add requires a List<int> argument.');
          }
          target.add(arguments[0] as List<int>);
          return null;
        case 'addStream': // Added
          if (arguments.length != 1 || arguments[0] is! Stream<List<int>>) {
            throw RuntimeError(
                'addStream requires a Stream<List<int>> argument.');
          }
          return target.addStream(arguments[0] as Stream<List<int>>);
        case 'flush':
          return target.flush();
        case 'close':
          return target.close();
        case 'encoding': // Getter/Setter
          if (arguments.isEmpty && namedArguments.isEmpty) {
            return target.encoding; // Getter
          }
          if (arguments.length != 1 || arguments[0] is! Encoding) {
            throw RuntimeError(
                'encoding setter requires an Encoding argument.');
          }
          target.encoding = arguments[0] as Encoding;
          return null;
        case 'done': // Getter (Future)
          return target.done;
        // Inherited StreamConsumer methods
        case 'addError': // Added
          if (arguments.isEmpty) {
            throw RuntimeError(
                'addError requires at least one argument (error).');
          }
          target.addError(arguments[0]!, arguments.get<StackTrace?>(1));
          return null;
        case 'supportsAnsiEscapes': // Getter specific to stdout/stderr (via Terminal)
          return target.supportsAnsiEscapes;
        case 'terminalLines': // Getter specific to stdout (via Terminal)
          return target.terminalLines;
        case 'terminalColumns': // Getter specific to stdout (via Terminal)
          return target.terminalColumns;
        case 'hasTerminal': // Getter specific to stdout/stderr (via Terminal)
          // Check if the underlying sink is connected to a terminal
          // dart:io doesn't expose this directly on IOSink after creation,
          // only on Stdin/Stdout directly. We approximate.
          return target.hasTerminal;
        // Common Object methods
        case 'runtimeType':
          return target.runtimeType;
        case 'hashCode':
          return target.hashCode;
        case 'toString':
          return target.toString();
        default:
          // Distinguish between stdout and stderr if necessary
          final targetName = identical(target, stdout)
              ? 'Stdout'
              : (identical(target, stderr) ? 'Stderr' : 'IOSink');
          throw RuntimeError(
              '$targetName has no method/getter mapping for "$name"');
      }
    } else {
      throw RuntimeError(
          'Unsupported target for StdoutIo: ${target.runtimeType}');
    }
  }
}

class StdioTypeIo implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'StdioType',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return StdioType;
        }, arity: 0, name: 'StdioType'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    switch (name) {
      case 'terminal':
        return StdioType.terminal;
      case 'pipe':
        return StdioType.pipe;
      case 'file':
        return StdioType.file;
      case 'other':
        return StdioType.other;
      default:
        throw RuntimeError('StdioType has no static member named "$name"');
    }
  }
}
