import 'dart:async';
import 'package:d4rt/d4rt.dart';

class FutureAsync {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: Future,
        name: 'Future',
        typeParameterCount: 1, // Future<T>
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length == 1 &&
                positionalArgs[0] is InterpretedFunction) {
              final computation = positionalArgs[0] as InterpretedFunction;
              return Future(() => computation.call(visitor, []));
            }
            throw RuntimeError('Invalid arguments for Future constructor.');
          },
        },
        staticMethods: {
          'delayed': (visitor, positionalArgs, namedArgs) {
            final duration = positionalArgs[0] as Duration;
            final computation = positionalArgs.get<InterpretedFunction?>(1);
            return Future.delayed(
              duration,
              computation == null ? null : () => computation.call(visitor, []),
            );
          },
          'value': (visitor, positionalArgs, namedArgs) {
            return Future.value(positionalArgs.get<dynamic>(0));
          },
          'error': (visitor, positionalArgs, namedArgs) {
            final error = positionalArgs[0];
            if (error == null) {
              throw RuntimeError(
                  'Future.error requires a non-null error object.');
            }
            final stackTrace = positionalArgs.get<StackTrace?>(1);
            return Future.error(error, stackTrace);
          },
          'microtask': (visitor, positionalArgs, namedArgs) {
            final computation = positionalArgs[0];
            if (computation is! InterpretedFunction) {
              throw RuntimeError(
                  'Future.microtask requires an InterpretedFunction.');
            }
            return Future.microtask(() => computation.call(visitor, []));
          },
          'sync': (visitor, positionalArgs, namedArgs) {
            final computation = positionalArgs[0];
            if (computation is! InterpretedFunction) {
              throw RuntimeError(
                  'Future.sync requires an InterpretedFunction.');
            }
            return Future.sync(() => computation.call(visitor, []));
          },
          'wait': (visitor, positionalArgs, namedArgs) {
            final futures = positionalArgs[0];
            if (futures is! Iterable) {
              throw RuntimeError('Future.wait requires an Iterable.');
            }
            final eagerError = namedArgs.get<bool?>('eagerError') ?? false;
            final cleanUp = namedArgs.get<InterpretedFunction?>('cleanUp');
            return Future.wait(futures.cast(),
                eagerError: eagerError,
                cleanUp: cleanUp == null
                    ? null
                    : (successValue) => cleanUp.call(visitor, [successValue]));
          },
          'any': (visitor, positionalArgs, namedArgs) {
            final futures = positionalArgs[0];
            if (futures is! Iterable) {
              throw RuntimeError('Future.any requires an Iterable.');
            }
            return Future.any(futures.cast());
          },
          'forEach': (visitor, positionalArgs, namedArgs) {
            final elements = positionalArgs[0] as Iterable;
            final action = positionalArgs[1];
            if (action is! InterpretedFunction) {
              throw RuntimeError(
                  'Future.forEach requires an InterpretedFunction for action.');
            }
            return Future.forEach(elements,
                (element) => action.call(visitor, [element]) as FutureOr<void>);
          },
          'doWhile': (visitor, positionalArgs, namedArgs) {
            final action = positionalArgs[0];
            if (action is! InterpretedFunction) {
              throw RuntimeError(
                  'Future.doWhile requires an InterpretedFunction for action.');
            }
            return Future.doWhile(
                () => action.call(visitor, []) as FutureOr<bool>);
          },
        },
        methods: {
          'then': (visitor, target, positionalArgs, namedArgs) {
            final onValue = positionalArgs[0];
            final onError = namedArgs.get<InterpretedFunction?>('onError');
            if (onValue is! InterpretedFunction) {
              throw RuntimeError(
                  'Future.then requires an InterpretedFunction for onValue.');
            }
            return (target as Future).then(
                (value) => onValue.call(visitor, [value]),
                onError: onError == null
                    ? null
                    : (error, stackTrace) =>
                        onError.call(visitor, [error, stackTrace]));
          },
          'catchError': (visitor, target, positionalArgs, namedArgs) {
            final onError = positionalArgs[0];
            final test = namedArgs.get<InterpretedFunction?>('test');
            if (onError is! InterpretedFunction) {
              throw RuntimeError(
                  'Future.catchError requires an InterpretedFunction for onError.');
            }
            return (target as Future).catchError(
                (error, stackTrace) =>
                    onError.call(visitor, [error, stackTrace]),
                test: test == null
                    ? null
                    : (error) => test.call(visitor, [error]) as bool);
          },
          'whenComplete': (visitor, target, positionalArgs, namedArgs) {
            final action = positionalArgs[0];
            if (action is! InterpretedFunction) {
              throw RuntimeError(
                  'Future.whenComplete requires an InterpretedFunction for action.');
            }
            return (target as Future)
                .whenComplete(() => action.call(visitor, []));
          },
          'timeout': (visitor, target, positionalArgs, namedArgs) {
            final timeLimit = positionalArgs[0] as Duration;
            final onTimeout = namedArgs.get<InterpretedFunction?>('onTimeout');
            return (target as Future).timeout(timeLimit,
                onTimeout: onTimeout == null
                    ? null
                    : () => onTimeout.call(visitor, []));
          },
          'asStream': (visitor, target, positionalArgs, namedArgs) {
            return (target as Future).asStream();
          },
        },
        getters: {
          'hashCode': (visitor, target) => (target as Future).hashCode,
          'runtimeType': (visitor, target) => (target as Future).runtimeType,
        },
      );
}

class FutureStdlib {
  static void register(Environment environment) {
    environment.defineBridge(FutureAsync.definition);
  }
}
