import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/stdlib/async/completer.dart';
import 'package:d4rt/src/stdlib/async/future.dart';
import 'package:d4rt/src/stdlib/async/stream.dart';
import 'package:d4rt/d4rt.dart';
import 'package:d4rt/src/stdlib/async/stream_controller.dart';
import 'package:d4rt/src/stdlib/async/timer.dart';

export 'package:d4rt/src/stdlib/async/completer.dart';
export 'package:d4rt/src/environment.dart';
export 'package:d4rt/src/stdlib/async/future.dart';
export 'package:d4rt/src/stdlib/async/stream.dart';

class AsyncStdlib {
  static void register(Environment environment) {
    CompleterStdlib.register(environment);
    FutureStdlib.register(environment);
    AsyncStreamStdlib.register(environment);
    TimerStdlib.register(environment);
    AsyncStreamControllerStdlib.register(environment);
  }
}
