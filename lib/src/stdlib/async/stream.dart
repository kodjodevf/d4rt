import 'dart:async';
import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart';
import 'package:d4rt/src/utils/extensions/map.dart';

// Helper function (adapt if already defined elsewhere)
FutureOr<T> _runAction<T>(
    InterpreterVisitor visitor, InterpretedFunction? func, List<dynamic> args) {
  try {
    return func?.call(visitor, args) as FutureOr<T>;
  } catch (e) {
    // Handle potential errors during callback execution if needed
    // For now, rethrow to let the stream handle it.
    rethrow;
  }
}

class StreamAsync implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Define the Stream type
    environment.define(
        'Stream',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return Stream;
        }, arity: 0, name: 'Stream'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is Stream) {
      switch (name) {
        case 'cast':
          return target.cast();
        // Properties
        case 'isBroadcast':
          return target.isBroadcast;
        case 'first':
          return target.first;
        case 'last':
          return target.last;
        case 'length':
          return target.length;
        case 'isEmpty':
          return target.isEmpty;
        case 'hashCode':
          return target.hashCode;
        case 'runtimeType':
          return target.runtimeType;

        // Core Methods
        case 'listen':
          final onData = arguments.get<InterpretedFunction?>(0);
          final onError = namedArguments.get<InterpretedFunction?>('onError');
          final onDone = namedArguments.get<InterpretedFunction?>('onDone');
          final cancelOnError = namedArguments.get<bool?>('cancelOnError');

          // Create native wrappers calling Interpreted functions via visitor
          void onDataWrapper(dynamic data) =>
              _runAction<void>(visitor, onData!, [data]);
          Function? onErrorWrapper = onError == null
              ? null
              : (Object error, [StackTrace? stackTrace]) =>
                  _runAction<void>(visitor, onError, [error, stackTrace]);
          void Function()? onDoneWrapper = onDone == null
              ? null
              : () => _runAction<void>(visitor, onDone, []);

          return target.listen(
            onData != null ? onDataWrapper : null,
            onError: onErrorWrapper,
            onDone: onDoneWrapper,
            cancelOnError: cancelOnError,
          ); // Returns StreamSubscription

        case 'map':
          final mapper = arguments[0];
          if (mapper is! InterpretedFunction) {
            throw RuntimeError(
                'Stream.map requires an InterpretedFunction mapper argument.');
          }
          return target
              .map((event) => _runAction<dynamic>(visitor, mapper, [event]));

        case 'where':
          final predicate = arguments[0];
          if (predicate is! InterpretedFunction) {
            throw RuntimeError(
                'Stream.where requires an InterpretedFunction predicate argument.');
          }
          return target.where((event) {
            final result = _runAction<dynamic>(visitor, predicate, [event]);
            return result is bool && result;
          });

        case 'expand':
          final converter = arguments[0];
          if (converter is! InterpretedFunction) {
            throw RuntimeError(
                'Stream.expand requires an InterpretedFunction converter argument.');
          }
          return target.expand((event) {
            final result = _runAction<dynamic>(visitor, converter, [event]);
            return result is Iterable ? result : const [];
          });

        case 'transform':
          final streamTransformer = arguments[0];
          if (streamTransformer is! StreamTransformer) {
            throw RuntimeError(
                'Stream.transform requires a StreamTransformer argument.');
          }
          return target.transform(streamTransformer);

        case 'take':
          final count = arguments[0];
          if (count is! int) {
            throw RuntimeError(
                'Stream.take requires an integer count argument.');
          }
          return target.take(count);

        case 'skip':
          final count = arguments[0];
          if (count is! int) {
            throw RuntimeError(
                'Stream.skip requires an integer count argument.');
          }
          return target.skip(count);

        case 'takeWhile':
          final predicate = arguments[0];
          if (predicate is! InterpretedFunction) {
            throw RuntimeError(
                'Stream.takeWhile requires an InterpretedFunction predicate argument.');
          }
          return target.takeWhile((event) {
            final result = _runAction<dynamic>(visitor, predicate, [event]);
            return result is bool && result;
          });

        case 'skipWhile':
          final predicate = arguments[0];
          if (predicate is! InterpretedFunction) {
            throw RuntimeError(
                'Stream.skipWhile requires an InterpretedFunction predicate argument.');
          }
          return target.skipWhile((event) {
            final result = _runAction<dynamic>(visitor, predicate, [event]);
            return result is bool && result;
          });

        case 'distinct':
          final equals = arguments.get<InterpretedFunction?>(0);
          if (equals == null) {
            return target.distinct();
          } else {
            return target.distinct((p, n) {
              final result = _runAction<dynamic>(visitor, equals, [p, n]);
              return result is bool && result;
            });
          }

        case 'toList':
          return target.toList();

        case 'toSet':
          return target.toSet();

        case 'join':
          final separator = arguments.get<String?>(0) ?? '';
          return target.join(separator);

        case 'pipe':
          final streamConsumer = arguments[0];
          if (streamConsumer is! StreamConsumer) {
            throw RuntimeError(
                'Stream.pipe requires a StreamConsumer argument.');
          }
          return target.pipe(streamConsumer);

        case 'any':
          final predicate = arguments[0];
          if (predicate is! InterpretedFunction) {
            throw RuntimeError(
                'Stream.any requires an InterpretedFunction predicate argument.');
          }
          return target.any((event) {
            final result = _runAction<dynamic>(visitor, predicate, [event]);
            return result is bool && result;
          });

        case 'contains':
          if (arguments.isEmpty) {
            throw RuntimeError('Stream.contains requires an element argument.');
          }
          return target.contains(arguments[0]);

        case 'drain': // Added
          final futureValue = arguments.get<dynamic>(0); // Optional value
          return target.drain(futureValue);

        case 'elementAt': // Added
          final index = arguments[0];
          if (index is! int) {
            throw RuntimeError(
                'Stream.elementAt requires an integer index argument.');
          }
          return target.elementAt(index);

        case 'every':
          final predicate = arguments[0];
          if (predicate is! InterpretedFunction) {
            throw RuntimeError(
                'Stream.every requires an InterpretedFunction predicate argument.');
          }
          return target.every((event) {
            final result = _runAction<dynamic>(visitor, predicate, [event]);
            return result is bool && result;
          });

        case 'firstWhere':
          final predicate = arguments[0];
          final orElse = namedArguments.get<InterpretedFunction?>('orElse');
          if (predicate is! InterpretedFunction) {
            throw RuntimeError(
                'Stream.firstWhere requires an InterpretedFunction predicate argument.');
          }
          dynamic Function()? orElseWrapper = orElse == null
              ? null
              : () => _runAction<dynamic>(visitor, orElse, []);
          return target.firstWhere(
            (event) {
              final result = _runAction<dynamic>(visitor, predicate, [event]);
              return result is bool && result;
            },
            orElse: orElseWrapper,
          );

        case 'fold':
          final initialValue = arguments[0];
          final combine = arguments[1];
          if (combine is! InterpretedFunction) {
            throw RuntimeError(
                'Stream.fold requires an InterpretedFunction combiner.');
          }
          return target.fold(initialValue, (previous, element) {
            return _runAction<dynamic>(visitor, combine, [previous, element]);
          });

        case 'forEach':
          final action = arguments[0];
          if (action is! InterpretedFunction) {
            throw RuntimeError(
                'Stream.forEach requires an InterpretedFunction action argument.');
          }
          return target
              .forEach((event) => _runAction<void>(visitor, action, [event]));

        case 'handleError':
          final onError = arguments[0];
          final test = namedArguments.get<InterpretedFunction?>('test');
          if (onError is! InterpretedFunction) {
            throw RuntimeError(
                'Stream.handleError requires an InterpretedFunction handler argument.');
          }
          bool Function(dynamic error)? testWrapper;
          if (test != null) {
            testWrapper = (error) {
              final result = _runAction<dynamic>(visitor, test, [error]);
              return result is bool && result;
            };
          }
          return target.handleError(
              (error, stackTrace) => _runAction<void>(
                  visitor, onError, [error, stackTrace]), // Pass stackTrace
              test: testWrapper);

        case 'lastWhere':
          final predicate = arguments[0];
          final orElse = namedArguments.get<InterpretedFunction?>('orElse');
          if (predicate is! InterpretedFunction) {
            throw RuntimeError(
                'Stream.lastWhere requires an InterpretedFunction predicate argument.');
          }
          dynamic Function()? orElseWrapper = orElse == null
              ? null
              : () => _runAction<dynamic>(visitor, orElse, []);
          return target.lastWhere(
            (event) {
              final result = _runAction<dynamic>(visitor, predicate, [event]);
              return result is bool && result;
            },
            orElse: orElseWrapper,
          );

        case 'reduce':
          final combine = arguments[0];
          if (combine is! InterpretedFunction) {
            throw RuntimeError(
                'Stream.reduce requires an InterpretedFunction combiner.');
          }
          return target.reduce((previous, element) {
            return _runAction<dynamic>(visitor, combine, [previous, element]);
          });

        case 'single':
          return target.single;

        case 'singleWhere':
          final predicate = arguments[0];
          final orElse = namedArguments.get<InterpretedFunction?>('orElse');
          if (predicate is! InterpretedFunction) {
            throw RuntimeError(
                'Stream.singleWhere requires an InterpretedFunction predicate argument.');
          }
          dynamic Function()? orElseWrapper = orElse == null
              ? null
              : () => _runAction<dynamic>(visitor, orElse, []);
          return target.singleWhere(
            (event) {
              final result = _runAction<dynamic>(visitor, predicate, [event]);
              return result is bool && result;
            },
            orElse: orElseWrapper,
          );

        case 'timeout':
          final timeLimit = arguments[0] as Duration;
          final onTimeout =
              namedArguments.get<InterpretedFunction?>('onTimeout');
          void Function(EventSink sink)? onTimeoutWrapper;
          if (onTimeout != null) {
            // The onTimeout callback receives the EventSink
            onTimeoutWrapper = (EventSink sink) =>
                _runAction<void>(visitor, onTimeout, [sink]);
          }
          return target.timeout(timeLimit, onTimeout: onTimeoutWrapper);

        case 'asBroadcastStream':
          final onListen = namedArguments.get<InterpretedFunction?>('onListen');
          final onCancel = namedArguments.get<InterpretedFunction?>('onCancel');
          void Function(StreamSubscription subscription)? onListenWrapper;
          void Function(StreamSubscription subscription)? onCancelWrapper;
          if (onListen != null) {
            onListenWrapper = (StreamSubscription sub) =>
                _runAction<void>(visitor, onListen, [sub]);
          }
          if (onCancel != null) {
            onCancelWrapper = (StreamSubscription sub) =>
                _runAction<void>(visitor, onCancel, [sub]);
          }
          return target.asBroadcastStream(
              onListen: onListenWrapper, onCancel: onCancelWrapper);

        default:
          throw RuntimeError(
              'Stream has no instance method/getter mapping for "$name"');
      }
    } else if (target == Stream) {
      switch (name) {
        case 'fromFuture':
          if (arguments.length != 1 || arguments[0] is! Future) {
            throw RuntimeError('Stream.fromFuture requires a Future argument.');
          }
          return Stream.fromFuture(arguments[0] as Future);
        case 'fromFutures':
          if (arguments.length != 1 || arguments[0] is! Iterable) {
            throw RuntimeError(
                'Stream.fromFutures requires an Iterable argument.');
          }
          return Stream.fromFutures((arguments[0] as Iterable).cast());
        case 'fromIterable':
          if (arguments.length != 1 || arguments[0] is! Iterable) {
            throw RuntimeError(
                'Stream.fromIterable requires an Iterable argument.');
          }
          return Stream.fromIterable((arguments[0] as Iterable).cast());
        case 'periodic':
          final period = arguments[0] as Duration;
          final computation = arguments.get<InterpretedFunction?>(1);
          if (computation != null) {
            return Stream.periodic(period,
                (count) => _runAction<dynamic>(visitor, computation, [count]));
          } else {
            return Stream.periodic(period);
          }
        case 'value':
          return Stream.value(arguments.get<dynamic>(0));
        case 'error':
          final error = arguments[0];
          if (error == null) {
            throw RuntimeError(
                'Stream.error requires a non-null error object.');
          }
          return Stream.error(error, arguments.get<StackTrace?>(1));
        case 'eventTransformed':
          final source = arguments[0];
          final onEvent = arguments[1];
          if (source is! Stream || onEvent is! Function) {
            throw RuntimeError(
                'Stream.eventTransformed requires a Stream and a Function.');
          }
          // The sinkMapping Function needs careful handling if it's interpreted
          return Stream.eventTransformed(source, (EventSink sink) {
            // This part is complex: how to represent the sink mapping?
            // Maybe require a native sink mapping function?
            throw UnimplementedError(
                'Interpreted sinkMapping for Stream.eventTransformed not implemented.');
          });
        case 'multi':
          final onListen = arguments[0];
          final isBroadcast = namedArguments.get<bool?>('isBroadcast') ?? false;
          if (onListen is! InterpretedFunction) {
            throw RuntimeError(
                'Stream.multi requires an InterpretedFunction for onListen.');
          }
          // The onListen callback receives a StreamController
          return Stream.multi((StreamController controller) {
            _runAction<void>(visitor, onListen, [controller]);
          }, isBroadcast: isBroadcast);
        case 'empty':
          return Stream.empty();
        default:
          throw RuntimeError('Stream has no static method mapping for "$name"');
      }
    }

    throw RuntimeError(
        'Invalid target for async method call: ${target?.runtimeType}');
  }
}

class StreamSubscriptionAsync implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'StreamSubscription',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Not constructable directly
          return StreamSubscription;
        }, arity: 0, name: 'StreamSubscription'));
  }

  @override
  Object? evalMethod(target, name, arguments, namedArguments, visitor) {
    if (target is StreamSubscription) {
      switch (name) {
        case 'cancel':
          return target.cancel(); // Returns Future<void>
        case 'onData':
          final handleData = arguments[0];
          if (handleData is! InterpretedFunction) {
            throw RuntimeError(
                'StreamSubscription.onData requires an InterpretedFunction.');
          }
          target
              .onData((data) => _runAction<void>(visitor, handleData, [data]));
          return null;
        case 'onError':
          final handleError = arguments[0];
          if (handleError is! InterpretedFunction) {
            throw RuntimeError(
                'StreamSubscription.onError requires an InterpretedFunction.');
          }
          // Note: The callback type is Function, might need specific casting or checks
          target.onError((error, [stackTrace]) =>
              _runAction<void>(visitor, handleError, [error, stackTrace]));
          return null;
        case 'onDone':
          final handleDone = arguments[0];
          if (handleDone is! InterpretedFunction) {
            throw RuntimeError(
                'StreamSubscription.onDone requires an InterpretedFunction.');
          }
          target.onDone(() => _runAction<void>(visitor, handleDone, []));
          return null;
        case 'pause':
          final resumeSignal = arguments.get<Future?>(0);
          target.pause(resumeSignal);
          return null;
        case 'resume':
          target.resume();
          return null;
        case 'isPaused':
          return target.isPaused;
        case 'asFuture':
          final futureValue = arguments.get<dynamic>(0);
          return target.asFuture(futureValue); // Returns Future<E>
        case 'hashCode':
          return target.hashCode;
        default:
          throw RuntimeError(
              'StreamSubscription has no method/getter mapping for "$name"');
      }
    } else {
      throw RuntimeError(
          'StreamSubscription has no static method/getter mapping for "$name"');
    }
  }
}

class StreamControllerAsync implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'StreamController',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Handle StreamController constructor arguments (sync, onListen, etc.)
          final sync = namedArguments.get<bool?>('sync') ?? false;
          final onListen = namedArguments.get<InterpretedFunction?>('onListen');
          final onPause = namedArguments.get<InterpretedFunction?>('onPause');
          final onResume = namedArguments.get<InterpretedFunction?>('onResume');
          final onCancel = namedArguments.get<InterpretedFunction?>('onCancel');

          // Need to create wrapped native callbacks for the controller
          void Function()? onListenWrapper = onListen == null
              ? null
              : () => _runAction<void>(visitor, onListen, []);
          void Function()? onPauseWrapper = onPause == null
              ? null
              : () => _runAction<void>(visitor, onPause, []);
          void Function()? onResumeWrapper = onResume == null
              ? null
              : () => _runAction<void>(visitor, onResume, []);
          FutureOr<void> Function()? onCancelWrapper = onCancel == null
              ? null
              : () => _runAction<void>(visitor, onCancel, []);

          return StreamController<dynamic>(
            sync: sync,
            onListen: onListenWrapper,
            onPause: onPauseWrapper,
            onResume: onResumeWrapper,
            onCancel: onCancelWrapper,
          );
        }, arity: 0, name: 'StreamController'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is StreamController) {
      switch (name) {
        case 'stream':
          return target.stream;
        case 'sink':
          return target.sink;
        case 'add':
          target.add(arguments.get<dynamic>(0));
          return null;
        case 'addError':
          final error = arguments[0];
          if (error == null) {
            throw RuntimeError(
                'StreamController.addError requires a non-null error object.');
          }
          target.addError(error, arguments.get<StackTrace?>(1));
          return null;
        case 'close':
          return target.close(); // Returns Future<void>
        case 'addStream':
          final source = arguments[0];
          if (source is! Stream) {
            throw RuntimeError(
                'StreamController.addStream requires a Stream argument.');
          }
          final cancelOnError = namedArguments.get<bool?>('cancelOnError');
          return target.addStream(source,
              cancelOnError: cancelOnError); // Returns Future<void>
        case 'onListen':
          return target.onListen; // Accessor
        case 'onPause':
          return target.onPause; // Accessor
        case 'onResume':
          return target.onResume; // Accessor
        case 'onCancel':
          return target.onCancel; // Accessor
        case 'isClosed':
          return target.isClosed;
        case 'isPaused':
          return target.isPaused;
        case 'hasListener':
          return target.hasListener;
        case 'hashCode':
          return target.hashCode;
        default:
          throw RuntimeError(
              'StreamController has no method/getter mapping for "$name"');
      }
    } else {
      switch (name) {
        case 'broadcast':
          bool sync = namedArguments.get<bool?>('sync') ?? false;
          final onListenFunc =
              namedArguments.get<InterpretedFunction?>('onListen');
          final onCancelFunc =
              namedArguments.get<InterpretedFunction?>('onCancel');
          var onListenWrapper = onListenFunc == null
              ? null
              : () => _runAction<void>(visitor, onListenFunc, []);
          var onCancelWrapper = onCancelFunc == null
              ? null
              : () => _runAction<void>(visitor, onCancelFunc, []);
          return StreamController<Object?>.broadcast(
              onListen: onListenWrapper,
              onCancel: onCancelWrapper, // onCancel is supported
              sync: sync);

        default:
          throw RuntimeError(
              'Target is not a StreamController for method "$name"');
      }
    }
  }
}

class StreamSinkAsync implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'StreamSink',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return StreamSink;
        }, arity: 0, name: 'StreamSink'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is StreamSink) {
      switch (name) {
        case 'add':
          if (arguments.isEmpty) {
            throw RuntimeError('StreamSink.add requires an event argument.');
          }
          target.add(arguments[0]);
          return null;
        case 'addError':
          if (arguments.isEmpty) {
            throw RuntimeError(
                'StreamSink.addError requires an error argument.');
          }
          target.addError(arguments[0] as Object,
              arguments.length > 1 ? arguments[1] as StackTrace? : null);
          return null;
        case 'close':
          return target.close();
        case 'done':
          return target.done;

        default:
          throw RuntimeError('StreamSink has no method mapping for "$name"');
      }
    } else {
      throw RuntimeError('Target is not a StreamSink for method "$name"');
    }
  }
}

class StreamTransformerAsync implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'StreamTransformer',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return StreamTransformer;
        }, arity: 0, name: 'StreamTransformer'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is StreamTransformer) {
      switch (name) {
        case 'bind':
          if (arguments.isEmpty || arguments[0] is! Stream) {
            throw RuntimeError(
                'StreamTransformer.bind requires a Stream argument.');
          }
          // The transformer types (S, T) are dynamic here.
          // We cast broadly and let runtime checks handle mismatches.
          return target.bind(arguments[0] as Stream<dynamic>);
        case 'toString':
          return target.toString();
        case 'hashCode':
          return target.hashCode;
        case 'runtimeType':
          return target.runtimeType.toString();
        default:
          throw RuntimeError(
              'StreamTransformer has no method mapping for "$name"');
      }
    } else {
      // Handle static-like methods
      switch (name) {
        case 'fromHandlers':
          final handleDataFunc =
              namedArguments.get<InterpretedFunction?>('handleData');
          final handleErrorFunc =
              namedArguments.get<InterpretedFunction?>('handleError');
          final handleDoneFunc =
              namedArguments.get<InterpretedFunction?>('handleDone');

          if (handleDataFunc == null &&
              handleErrorFunc == null &&
              handleDoneFunc == null) {
            throw RuntimeError(
                'StreamTransformer.fromHandlers requires at least one handler function.');
          }

          void handleDataWrapper(dynamic data, EventSink<dynamic> sink) {
            _runAction<void>(visitor, handleDataFunc, [data, sink]);
          }

          void handleErrorWrapper(
              Object error, StackTrace stackTrace, EventSink<dynamic> sink) {
            _runAction<void>(
                visitor, handleErrorFunc, [error, stackTrace, sink]);
          }

          void handleDoneWrapper(EventSink<dynamic> sink) {
            _runAction<void>(visitor, handleDoneFunc, [sink]);
          }

          return StreamTransformer.fromHandlers(
            handleData: handleDataFunc != null ? handleDataWrapper : null,
            handleError: handleErrorFunc != null ? handleErrorWrapper : null,
            handleDone: handleDoneFunc != null ? handleDoneWrapper : null,
          );

        default:
          throw RuntimeError(
              'StreamTransformer has no static method mapping for "$name"');
      }
    }
  }
}
