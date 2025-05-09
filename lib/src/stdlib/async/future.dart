import 'dart:async';
import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart';
import 'package:d4rt/src/utils/extensions/map.dart';

class FutureAsync implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'Future',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Future<T>(FutureOr<T> computation()) constructor
          if (arguments.length == 1 && arguments[0] is InterpretedFunction) {
            final computation = arguments[0] as InterpretedFunction;
            // Wrap the interpreted function call
            return Future(() => computation.call(visitor, []));
          } else if (arguments.isEmpty) {
            // Allow getting the Future type itself
            return Future;
          }
          throw RuntimeError('Invalid arguments for Future constructor.');
        }, arity: 1, name: 'Future')); // Arity 1 (computation), or 0 for type
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is Future) {
      switch (name) {
        case 'then':
          final onValue = arguments[0];
          final onError = namedArguments.get<InterpretedFunction?>('onError');
          if (onValue is! InterpretedFunction) {
            throw RuntimeError(
                'Future.then requires an InterpretedFunction for onValue.');
          }
          return target.then((value) => onValue.call(visitor, [value]),
              onError: onError == null
                  ? null
                  : (error, stackTrace) => onError
                      .call(visitor, [error, stackTrace]) // Pass stackTrace too
              );
        case 'catchError':
          final onError = arguments[0];
          final test = namedArguments.get<InterpretedFunction?>('test');
          if (onError is! InterpretedFunction) {
            throw RuntimeError(
                'Future.catchError requires an InterpretedFunction for onError.');
          }
          return target.catchError(
              (error, stackTrace) =>
                  onError.call(visitor, [error, stackTrace]), // Pass stackTrace
              test: test == null
                  ? null
                  : (error) => test.call(visitor, [error]) as bool);
        case 'whenComplete':
          final action = arguments[0];
          if (action is! InterpretedFunction) {
            throw RuntimeError(
                'Future.whenComplete requires an InterpretedFunction for action.');
          }
          return target.whenComplete(() => action.call(visitor, []));
        case 'timeout':
          final timeLimit = arguments[0] as Duration;
          final onTimeout =
              namedArguments.get<InterpretedFunction?>('onTimeout');
          return target.timeout(timeLimit,
              onTimeout:
                  onTimeout == null ? null : () => onTimeout.call(visitor, []));
        case 'asStream': // Added
          return target.asStream();
        default:
          throw RuntimeError(
              'Future has no instance method mapping for "$name"');
      }
    } else if (target == Future) {
      // Static methods called on Future type
      switch (name) {
        case 'delayed':
          final duration = arguments[0] as Duration;
          final computation = arguments.get<InterpretedFunction?>(1);
          return Future.delayed(
            duration,
            computation == null ? null : () => computation.call(visitor, []),
          );
        case 'value':
          return Future.value(
              arguments.get<dynamic>(0)); // Allow any value type
        case 'error':
          final error = arguments[0];
          if (error == null) {
            throw RuntimeError(
                'Future.error requires a non-null error object.');
          }
          final stackTrace = arguments.get<StackTrace?>(1);
          return Future.error(error, stackTrace);
        case 'microtask':
          final computation = arguments[0];
          if (computation is! InterpretedFunction) {
            throw RuntimeError(
                'Future.microtask requires an InterpretedFunction.');
          }
          return Future.microtask(() => computation.call(visitor, []));
        case 'sync': // Added
          final computation = arguments[0];
          if (computation is! InterpretedFunction) {
            throw RuntimeError('Future.sync requires an InterpretedFunction.');
          }
          return Future.sync(() => computation.call(visitor, []));
        case 'wait': // Added
          final futures = arguments[0];
          if (futures is! Iterable) {
            throw RuntimeError('Future.wait requires an Iterable.');
          }
          final eagerError = namedArguments.get<bool?>('eagerError') ?? false;
          final cleanUp = namedArguments.get<InterpretedFunction?>('cleanUp');
          return Future.wait(futures.cast(),
              eagerError: eagerError,
              cleanUp: cleanUp == null
                  ? null
                  : (successValue) => cleanUp.call(visitor, [successValue]));
        case 'any': // Added
          final futures = arguments[0];
          if (futures is! Iterable) {
            throw RuntimeError('Future.any requires an Iterable.');
          }
          return Future.any(futures.cast());
        case 'forEach': // Added
          final elements = arguments[0] as Iterable;
          final action = arguments[1];
          if (action is! InterpretedFunction) {
            throw RuntimeError(
                'Future.forEach requires an InterpretedFunction for action.');
          }
          return Future.forEach(elements,
              (element) => action.call(visitor, [element]) as FutureOr<void>);
        case 'doWhile': // Added
          final action = arguments[0];
          if (action is! InterpretedFunction) {
            throw RuntimeError(
                'Future.doWhile requires an InterpretedFunction for action.');
          }
          return Future.doWhile(
              () => action.call(visitor, []) as FutureOr<bool>);
        default:
          throw RuntimeError('Future has no static method mapping for "$name"');
      }
    } else {
      throw RuntimeError(
          'Invalid target for Future method call: ${target?.runtimeType}');
    }
  }
}
