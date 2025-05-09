import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/stdlib/async/completer.dart';
import 'package:d4rt/src/stdlib/async/future.dart';
import 'package:d4rt/src/stdlib/async/stream.dart';

export 'package:d4rt/src/stdlib/async/completer.dart';
export 'package:d4rt/src/environment.dart';
export 'package:d4rt/src/stdlib/async/future.dart';
export 'package:d4rt/src/stdlib/async/stream.dart';

void registerAsyncLibs(Environment environment) {
  CompleterAsync().setEnvironment(environment);
  FutureAsync().setEnvironment(environment);
  StreamAsync().setEnvironment(environment);
  StreamControllerAsync().setEnvironment(environment);
  StreamSinkAsync().setEnvironment(environment);
  StreamSubscriptionAsync().setEnvironment(environment);
}
