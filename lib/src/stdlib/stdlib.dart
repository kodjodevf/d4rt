import 'package:d4rt/src/stdlib/core.dart';
import 'package:d4rt/src/stdlib/async.dart';

class Stdlib {
  final Environment environment;

  Stdlib(this.environment);

  void register() {
    CoreStdlib.register(environment);
    AsyncStdlib.register(environment);
  }
}
