import 'package:d4rt/src/stdlib/core.dart';
import 'package:d4rt/src/stdlib/async.dart';
import 'package:d4rt/src/stdlib/typed_data.dart';

class Stdlib {
  final Environment environment;

  Stdlib(this.environment);

  void register() {
    CoreStdlib.register(environment);
    AsyncStdlib.register(environment);
    TypedDataStdlib.register(environment);
  }
}
