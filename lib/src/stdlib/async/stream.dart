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

class StreamAsync {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: Stream,
        name: 'Stream',
        typeParameterCount: 1,
        nativeNames: [
          '_MultiStream',
          '_ControllerStream',
          '_BroadcastStream',
          '_SingleSubscriptionStream',
          '_StreamIterator',
          '_EmptyStream',
          '_SingleStream',
          '_ErrorStream',
          '_PeriodicStream',
          '_FromIterableStream',
          '_ForwardingStream',
          '_AsBroadcastStream',
          '_StreamHandlerTransformer',
          '_BoundSinkStream',
          '_HandlerEventSink',
          '_TakeStream',
          '_MapStream',
          '_WhereStream',
          '_ExpandStream',
          '_SkipStream',
          '_TakeWhileStream',
          '_SkipWhileStream',
          '_DistinctStream',
        ],
        constructors: {},
        staticMethods: {
          'value': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw RuntimeError('Stream.value requires one argument.');
            }
            return Stream.value(positionalArgs[0]);
          },
          'error': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw RuntimeError(
                  'Stream.error requires at least one argument.');
            }
            final error = positionalArgs[0];
            if (error == null) {
              throw RuntimeError('Stream.error requires a non-null error.');
            }
            final stackTrace = positionalArgs.length > 1
                ? positionalArgs[1] as StackTrace?
                : null;
            return Stream.error(error, stackTrace);
          },
          'empty': (visitor, positionalArgs, namedArgs) => Stream.empty(),
          'fromIterable': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! Iterable) {
              throw RuntimeError(
                  'Stream.fromIterable requires an Iterable argument.');
            }
            return Stream.fromIterable(positionalArgs[0] as Iterable);
          },
          'periodic': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty || positionalArgs[0] is! Duration) {
              throw RuntimeError(
                  'Stream.periodic requires a Duration argument.');
            }
            final callback = positionalArgs.length > 1
                ? positionalArgs[1] as InterpretedFunction?
                : null;
            return Stream.periodic(
              positionalArgs[0] as Duration,
              callback == null
                  ? null
                  : (i) => _runAction(visitor, callback, [i]),
            );
          },
          'fromFuture': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! Future) {
              throw RuntimeError(
                  'Stream.fromFuture requires a Future argument.');
            }
            return Stream.fromFuture(positionalArgs[0] as Future);
          },
          'fromFutures': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! Iterable) {
              throw RuntimeError(
                  'Stream.fromFutures requires an Iterable argument.');
            }
            return Stream.fromFutures((positionalArgs[0] as Iterable).cast());
          },
        },
        methods: {
          'listen': (visitor, target, positionalArgs, namedArgs) {
            final onData = positionalArgs.isNotEmpty
                ? positionalArgs[0] as InterpretedFunction?
                : null;
            final onError = namedArgs['onError'] as InterpretedFunction?;
            final onDone = namedArgs['onDone'] as InterpretedFunction?;
            final cancelOnError = namedArgs['cancelOnError'] as bool?;

            void onDataWrapper(dynamic data) =>
                _runAction<void>(visitor, onData!, [data]);
            Function? onErrorWrapper = onError == null
                ? null
                : (Object error, [StackTrace? stackTrace]) =>
                    _runAction<void>(visitor, onError, [error, stackTrace]);
            void Function()? onDoneWrapper = onDone == null
                ? null
                : () => _runAction<void>(visitor, onDone, []);

            return (target as Stream).listen(
              onData != null ? onDataWrapper : null,
              onError: onErrorWrapper,
              onDone: onDoneWrapper,
              cancelOnError: cancelOnError,
            );
          },
          'map': (visitor, target, positionalArgs, namedArgs) {
            final mapper = positionalArgs[0];
            if (mapper is! InterpretedFunction) {
              throw RuntimeError(
                  'Stream.map requires an InterpretedFunction mapper argument.');
            }
            return (target as Stream)
                .map((event) => _runAction<dynamic>(visitor, mapper, [event]));
          },
          'where': (visitor, target, positionalArgs, namedArgs) {
            final predicate = positionalArgs[0];
            if (predicate is! InterpretedFunction) {
              throw RuntimeError(
                  'Stream.where requires an InterpretedFunction predicate argument.');
            }
            return (target as Stream).where((event) {
              final result = _runAction<dynamic>(visitor, predicate, [event]);
              return result is bool && result;
            });
          },
          'expand': (visitor, target, positionalArgs, namedArgs) {
            final converter = positionalArgs[0];
            if (converter is! InterpretedFunction) {
              throw RuntimeError(
                  'Stream.expand requires an InterpretedFunction converter argument.');
            }
            return (target as Stream).expand((event) {
              final result = _runAction<dynamic>(visitor, converter, [event]);
              return result is Iterable ? result : const [];
            });
          },
          'transform': (visitor, target, positionalArgs, namedArgs) {
            final streamTransformer = positionalArgs[0];
            if (streamTransformer is! StreamTransformer) {
              throw RuntimeError(
                  'Stream.transform requires a StreamTransformer argument.');
            }
            return (target as Stream).transform(streamTransformer);
          },
          'take': (visitor, target, positionalArgs, namedArgs) {
            final count = positionalArgs[0];
            if (count is! int) {
              throw RuntimeError(
                  'Stream.take requires an integer count argument.');
            }
            return (target as Stream).take(count);
          },
          'skip': (visitor, target, positionalArgs, namedArgs) {
            final count = positionalArgs[0];
            if (count is! int) {
              throw RuntimeError(
                  'Stream.skip requires an integer count argument.');
            }
            return (target as Stream).skip(count);
          },
          'takeWhile': (visitor, target, positionalArgs, namedArgs) {
            final predicate = positionalArgs[0];
            if (predicate is! InterpretedFunction) {
              throw RuntimeError(
                  'Stream.takeWhile requires an InterpretedFunction predicate argument.');
            }
            return (target as Stream).takeWhile((event) {
              final result = _runAction<dynamic>(visitor, predicate, [event]);
              return result is bool && result;
            });
          },
          'skipWhile': (visitor, target, positionalArgs, namedArgs) {
            final predicate = positionalArgs[0];
            if (predicate is! InterpretedFunction) {
              throw RuntimeError(
                  'Stream.skipWhile requires an InterpretedFunction predicate argument.');
            }
            return (target as Stream).skipWhile((event) {
              final result = _runAction<dynamic>(visitor, predicate, [event]);
              return result is bool && result;
            });
          },
          'distinct': (visitor, target, positionalArgs, namedArgs) {
            final equals = positionalArgs.isNotEmpty
                ? positionalArgs[0] as InterpretedFunction?
                : null;
            if (equals == null) {
              return (target as Stream).distinct();
            } else {
              return (target as Stream).distinct((p, n) {
                final result = _runAction<dynamic>(visitor, equals, [p, n]);
                return result is bool && result;
              });
            }
          },
          'toList': (visitor, target, positionalArgs, namedArgs) =>
              (target as Stream).toList(),
          'toSet': (visitor, target, positionalArgs, namedArgs) =>
              (target as Stream).toSet(),
          'join': (visitor, target, positionalArgs, namedArgs) {
            final separator = positionalArgs.isNotEmpty
                ? positionalArgs[0] as String? ?? ''
                : '';
            return (target as Stream).join(separator);
          },
          'pipe': (visitor, target, positionalArgs, namedArgs) {
            final streamConsumer = positionalArgs[0];
            if (streamConsumer is! StreamConsumer) {
              throw RuntimeError(
                  'Stream.pipe requires a StreamConsumer argument.');
            }
            return (target as Stream).pipe(streamConsumer);
          },
          'any': (visitor, target, positionalArgs, namedArgs) {
            final predicate = positionalArgs[0];
            if (predicate is! InterpretedFunction) {
              throw RuntimeError(
                  'Stream.any requires an InterpretedFunction predicate argument.');
            }
            return (target as Stream).any((event) {
              final result = _runAction<dynamic>(visitor, predicate, [event]);
              return result is bool && result;
            });
          },
          'contains': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw RuntimeError(
                  'Stream.contains requires an element argument.');
            }
            return (target as Stream).contains(positionalArgs[0]);
          },
          'every': (visitor, target, positionalArgs, namedArgs) {
            final predicate = positionalArgs[0];
            if (predicate is! InterpretedFunction) {
              throw RuntimeError(
                  'Stream.every requires an InterpretedFunction predicate argument.');
            }
            return (target as Stream).every((event) {
              final result = _runAction<dynamic>(visitor, predicate, [event]);
              return result is bool && result;
            });
          },
          'fold': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length < 2 ||
                positionalArgs[1] is! InterpretedFunction) {
              throw RuntimeError(
                  'Stream.fold requires initial value and InterpretedFunction combine arguments.');
            }
            final initialValue = positionalArgs[0];
            final combine = positionalArgs[1] as InterpretedFunction;
            return (target as Stream).fold(
              initialValue,
              (previous, element) =>
                  _runAction<dynamic>(visitor, combine, [previous, element]),
            );
          },
          'reduce': (visitor, target, positionalArgs, namedArgs) {
            final combine = positionalArgs[0];
            if (combine is! InterpretedFunction) {
              throw RuntimeError(
                  'Stream.reduce requires an InterpretedFunction combine argument.');
            }
            return (target as Stream).reduce(
              (previous, element) =>
                  _runAction<dynamic>(visitor, combine, [previous, element]),
            );
          },
          'forEach': (visitor, target, positionalArgs, namedArgs) {
            final action = positionalArgs[0];
            if (action is! InterpretedFunction) {
              throw RuntimeError(
                  'Stream.forEach requires an InterpretedFunction action argument.');
            }
            return (target as Stream).forEach(
              (element) => _runAction<void>(visitor, action, [element]),
            );
          },
          'cast': (visitor, target, positionalArgs, namedArgs) =>
              (target as Stream).cast(),
          'asBroadcastStream': (visitor, target, positionalArgs, namedArgs) {
            final onListen = namedArgs['onListen'] as InterpretedFunction?;
            final onCancel = namedArgs['onCancel'] as InterpretedFunction?;
            return (target as Stream).asBroadcastStream(
              onListen: onListen == null
                  ? null
                  : (subscription) =>
                      _runAction<void>(visitor, onListen, [subscription]),
              onCancel: onCancel == null
                  ? null
                  : (subscription) =>
                      _runAction<void>(visitor, onCancel, [subscription]),
            );
          },
        },
        getters: {
          'isBroadcast': (visitor, target) => (target as Stream).isBroadcast,
          'first': (visitor, target) => (target as Stream).first,
          'last': (visitor, target) => (target as Stream).last,
          'length': (visitor, target) => (target as Stream).length,
          'isEmpty': (visitor, target) => (target as Stream).isEmpty,
          'hashCode': (visitor, target) => (target as Stream).hashCode,
          'runtimeType': (visitor, target) => (target as Stream).runtimeType,
        },
      );
}

class StreamSubscriptionAsync {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: StreamSubscription,
        name: 'StreamSubscription',
        typeParameterCount: 1,
        nativeNames: [
          '_ControllerSubscription',
          '_BroadcastSubscription',
          '_BufferingStreamSubscription',
          '_StreamSubscriptionWrapper',
          '_DoneStreamSubscription',
          '_SingleSubscription',
          '_EmptyStreamSubscription',
        ],
        constructors: {},
        methods: {
          'cancel': (visitor, target, positionalArgs, namedArgs) =>
              (target as StreamSubscription).cancel(),
          'pause': (visitor, target, positionalArgs, namedArgs) {
            final resumeSignal =
                positionalArgs.isNotEmpty ? positionalArgs[0] as Future? : null;
            (target as StreamSubscription).pause(resumeSignal);
            return null;
          },
          'resume': (visitor, target, positionalArgs, namedArgs) {
            (target as StreamSubscription).resume();
            return null;
          },
        },
        getters: {
          'isPaused': (visitor, target) =>
              (target as StreamSubscription).isPaused,
        },
        setters: {
          'onData': (visitorParam, target, value) {
            final callback = value as InterpretedFunction?;
            final visitor = visitorParam; // Keep reference for closure
            (target as StreamSubscription).onData(
              callback == null
                  ? null
                  : (data) => _runAction<void>(visitor!, callback, [data]),
            );
            return;
          },
          'onError': (visitorParam, target, value) {
            final callback = value as InterpretedFunction?;
            final visitor = visitorParam; // Keep reference for closure
            (target as StreamSubscription).onError(
              callback == null
                  ? null
                  : (error, stackTrace) =>
                      _runAction<void>(visitor!, callback, [error, stackTrace]),
            );
            return;
          },
          'onDone': (visitorParam, target, value) {
            final callback = value as InterpretedFunction?;
            final visitor = visitorParam; // Keep reference for closure
            (target as StreamSubscription).onDone(
              callback == null
                  ? null
                  : () => _runAction<void>(visitor!, callback, []),
            );
            return;
          },
        },
      );
}

class StreamControllerAsync {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
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

class StreamSinkAsync {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: StreamSink,
        name: 'StreamSink',
        typeParameterCount: 1,
        constructors: {},
        methods: {
          'add': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw RuntimeError('StreamSink.add requires an event argument.');
            }
            (target as StreamSink).add(positionalArgs[0]);
            return null;
          },
          'addError': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw RuntimeError(
                  'StreamSink.addError requires an error argument.');
            }
            final error = positionalArgs[0];
            if (error == null) {
              throw RuntimeError(
                  'StreamSink.addError requires a non-null error.');
            }
            final stackTrace = positionalArgs.length > 1
                ? positionalArgs[1] as StackTrace?
                : null;
            (target as StreamSink).addError(error, stackTrace);
            return null;
          },
          'close': (visitor, target, positionalArgs, namedArgs) =>
              (target as StreamSink).close(),
        },
        getters: {
          'done': (visitor, target) => (target as StreamSink).done,
        },
      );
}

class StreamTransformerAsync {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: StreamTransformer,
        name: 'StreamTransformer',
        typeParameterCount: 2,
        constructors: {},
        staticMethods: {
          'fromHandlers': (visitor, positionalArgs, namedArgs) {
            final handleData = namedArgs['handleData'] as InterpretedFunction?;
            final handleError =
                namedArgs['handleError'] as InterpretedFunction?;
            final handleDone = namedArgs['handleDone'] as InterpretedFunction?;

            return StreamTransformer.fromHandlers(
              handleData: handleData == null
                  ? null
                  : (data, sink) =>
                      _runAction<void>(visitor, handleData, [data, sink]),
              handleError: handleError == null
                  ? null
                  : (error, stackTrace, sink) => _runAction<void>(
                      visitor, handleError, [error, stackTrace, sink]),
              handleDone: handleDone == null
                  ? null
                  : (sink) => _runAction<void>(visitor, handleDone, [sink]),
            );
          },
        },
        methods: {
          'bind': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! Stream) {
              throw RuntimeError(
                  'StreamTransformer.bind requires a Stream argument.');
            }
            return (target as StreamTransformer)
                .bind(positionalArgs[0] as Stream);
          },
        },
        getters: {},
      );
}

class AsyncStreamStdlib {
  static void register(Environment environment) {
    environment.defineBridge(StreamAsync.definition);
    environment.defineBridge(StreamSubscriptionAsync.definition);
    environment.defineBridge(StreamControllerAsync.definition);
    environment.defineBridge(StreamSinkAsync.definition);
    environment.defineBridge(StreamTransformerAsync.definition);
  }
}
