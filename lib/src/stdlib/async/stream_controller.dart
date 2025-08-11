import 'dart:async';
import 'package:d4rt/d4rt.dart';

// Helper function for running interpreted functions
FutureOr<T> _runAction<T>(
    InterpreterVisitor visitor, InterpretedFunction? func, List<dynamic> args) {
  try {
    return func?.call(visitor, args) as FutureOr<T>;
  } catch (e) {
    rethrow;
  }
}

class StreamControllerAsync {
  static BridgedClass get definition => BridgedClass(
        nativeType: StreamController,
        name: 'StreamController',
        typeParameterCount: 1,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final sync = namedArgs['sync'] as bool? ?? false;
            final onListen = namedArgs['onListen'] as InterpretedFunction?;
            final onPause = namedArgs['onPause'] as InterpretedFunction?;
            final onResume = namedArgs['onResume'] as InterpretedFunction?;
            final onCancel = namedArgs['onCancel'] as InterpretedFunction?;

            return StreamController(
              onListen: onListen == null
                  ? null
                  : () => _runAction<void>(visitor, onListen, []),
              onPause: onPause == null
                  ? null
                  : () => _runAction<void>(visitor, onPause, []),
              onResume: onResume == null
                  ? null
                  : () => _runAction<void>(visitor, onResume, []),
              onCancel: onCancel == null
                  ? null
                  : () => _runAction<void>(visitor, onCancel, []),
              sync: sync,
            );
          },
          'broadcast': (visitor, positionalArgs, namedArgs) {
            final sync = namedArgs['sync'] as bool? ?? false;
            final onListen = namedArgs['onListen'] as InterpretedFunction?;
            final onCancel = namedArgs['onCancel'] as InterpretedFunction?;

            return StreamController.broadcast(
              onListen: onListen == null
                  ? null
                  : () => _runAction<void>(visitor, onListen, []),
              onCancel: onCancel == null
                  ? null
                  : () => _runAction<void>(visitor, onCancel, []),
              sync: sync,
            );
          },
        },
        methods: {
          'add': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw RuntimeError(
                  'StreamController.add requires an event argument.');
            }
            (target as StreamController).add(positionalArgs[0]);
            return null;
          },
          'addError': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw RuntimeError(
                  'StreamController.addError requires an error argument.');
            }
            final error = positionalArgs[0];
            if (error == null) {
              throw RuntimeError(
                  'StreamController.addError requires a non-null error.');
            }
            final stackTrace = positionalArgs.length > 1
                ? positionalArgs[1] as StackTrace?
                : null;
            (target as StreamController).addError(error, stackTrace);
            return null;
          },
          'close': (visitor, target, positionalArgs, namedArgs) =>
              (target as StreamController).close(),
          'addStream': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! Stream) {
              throw RuntimeError(
                  'StreamController.addStream requires a Stream argument.');
            }
            final cancelOnError = namedArgs['cancelOnError'] as bool?;
            return (target as StreamController).addStream(
              positionalArgs[0] as Stream,
              cancelOnError: cancelOnError,
            );
          },
        },
        getters: {
          'stream': (visitor, target) => (target as StreamController).stream,
          'sink': (visitor, target) => (target as StreamController).sink,
          'isClosed': (visitor, target) =>
              (target as StreamController).isClosed,
          'isPaused': (visitor, target) =>
              (target as StreamController).isPaused,
          'hasListener': (visitor, target) =>
              (target as StreamController).hasListener,
          'onListen': (visitor, target) =>
              (target as StreamController).onListen,
          'onPause': (visitor, target) => (target as StreamController).onPause,
          'onResume': (visitor, target) =>
              (target as StreamController).onResume,
          'onCancel': (visitor, target) =>
              (target as StreamController).onCancel,
        },
        setters: {
          'onListen': (visitorParam, target, value) {
            final callback = value as InterpretedFunction?;
            final visitor = visitorParam; // Capture reference
            (target as StreamController).onListen = callback == null
                ? null
                : () => _runAction<void>(visitor!, callback, []);
            return;
          },
          'onPause': (visitorParam, target, value) {
            final callback = value as InterpretedFunction?;
            final visitor = visitorParam; // Capture reference
            (target as StreamController).onPause = callback == null
                ? null
                : () => _runAction<void>(visitor!, callback, []);
            return;
          },
          'onResume': (visitorParam, target, value) {
            final callback = value as InterpretedFunction?;
            final visitor = visitorParam; // Capture reference
            (target as StreamController).onResume = callback == null
                ? null
                : () => _runAction<void>(visitor!, callback, []);
            return;
          },
          'onCancel': (visitorParam, target, value) {
            final callback = value as InterpretedFunction?;
            final visitor = visitorParam; // Capture reference
            (target as StreamController).onCancel = callback == null
                ? null
                : () => _runAction<void>(visitor!, callback, []);
            return;
          },
        },
      );
}

class AsyncStreamControllerStdlib {
  static void register(Environment environment) {
    environment.defineBridge(StreamControllerAsync.definition);
  }
}
