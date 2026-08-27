import 'dart:async';
import 'package:d4rt/src/stdlib/async/completer.dart';
import 'package:d4rt/src/stdlib/async/future.dart';
import 'package:d4rt/src/stdlib/async/stream.dart';
import 'package:d4rt/d4rt.dart';
import 'package:d4rt/src/stdlib/async/stream_controller.dart';
import 'package:d4rt/src/stdlib/async/timer.dart';
import 'package:d4rt/src/stdlib/async/zone.dart';

export 'package:d4rt/src/stdlib/async/completer.dart';
export 'package:d4rt/src/environment.dart';
export 'package:d4rt/src/stdlib/async/future.dart';
export 'package:d4rt/src/stdlib/async/stream.dart';
export 'package:d4rt/src/stdlib/async/zone.dart';

class AsyncStdlib {
  static void register(Environment environment) {
    CompleterStdlib.register(environment);
    FutureStdlib.register(environment);
    AsyncStreamStdlib.register(environment);
    TimerStdlib.register(environment);
    AsyncStreamControllerStdlib.register(environment);
    environment.defineBridge(ZoneAsync.definition);

    // Register scheduleMicrotask
    environment.define(
        'scheduleMicrotask',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          if (arguments.isEmpty || arguments[0] is! InterpretedFunction) {
            throw RuntimeError('scheduleMicrotask requires a callback function.');
          }
          final callback = arguments[0] as InterpretedFunction;
          scheduleMicrotask(() => callback.call(visitor, []));
          return null;
        }, arity: 1, name: 'scheduleMicrotask'));

    // Register runZoned
    environment.define(
        'runZoned',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          if (arguments.isEmpty || arguments[0] is! InterpretedFunction) {
            throw RuntimeError('runZoned requires a callback function body.');
          }
          final body = arguments[0] as InterpretedFunction;
          final zoneValues = namedArguments['zoneValues'] as Map?;

          return runZoned<Object?>(
            () => body.call(visitor, []),
            zoneValues: zoneValues != null ? Map.from(zoneValues) : null,
          );
        }, arity: 1, name: 'runZoned'));

    // Register runZonedGuarded
    environment.define(
        'runZonedGuarded',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          if (arguments.length < 2 ||
              arguments[0] is! InterpretedFunction ||
              arguments[1] is! InterpretedFunction) {
            throw RuntimeError(
                'runZonedGuarded requires a body function and an onError handler.');
          }
          final body = arguments[0] as InterpretedFunction;
          final onError = arguments[1] as InterpretedFunction;
          final zoneValues = namedArguments['zoneValues'] as Map?;

          return runZonedGuarded<Object?>(
            () => body.call(visitor, []),
            (error, stackTrace) {
              final unwrappedError = error is InternalInterpreterException
                  ? error.originalThrownValue
                  : error;
              onError.call(visitor, [unwrappedError, stackTrace]);
            },
            zoneValues: zoneValues != null ? Map.from(zoneValues) : null,
          );
        }, arity: 2, name: 'runZonedGuarded'));
  }
}
