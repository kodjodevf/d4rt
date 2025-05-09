import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/interpreter_visitor.dart';

abstract interface class MethodInterface {
  void setEnvironment(Environment environment);
  Object? evalMethod(Object? target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor);
}
