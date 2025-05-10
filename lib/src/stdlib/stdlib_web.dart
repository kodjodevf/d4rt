import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/stdlib/core.dart';
import 'package:d4rt/src/stdlib/convert.dart';
import 'package:d4rt/src/stdlib/math.dart';
import 'package:d4rt/src/stdlib/async.dart';

class StdlibIo {
  static void registerStdIoLibs(Environment environment) {}

  static MethodInterface? get(
      Object? target,
      String name,
      List<Object?> arguments,
      Map<String, Object?> namedArguments,
      InterpreterVisitor visitor,
      List<Object?> typeArguments,
      {String? error}) {
    return null;
  }
}
