import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';

class IteratorCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Iterator is usually obtained from an Iterable, not constructed directly.
    // Define the type name.
    environment.define(
        'Iterator',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return Iterator;
        }, arity: 0, name: 'Iterator'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    // It might be a native Dart iterator or potentially a wrapped one.
    // For now, assume it responds to the basic Iterator interface.
    if (target is! Iterator) {
      throw RuntimeError(
          'Target for Iterator method call must be an Iterator.');
    }

    switch (name) {
      case 'moveNext':
        // Ensure no arguments are passed
        if (arguments.isNotEmpty || namedArguments.isNotEmpty) {
          throw RuntimeError('moveNext expects no arguments.');
        }
        return target.moveNext();
      case 'current':
        // Ensure no arguments are passed
        if (arguments.isNotEmpty || namedArguments.isNotEmpty) {
          throw RuntimeError('current expects no arguments.');
        }
        return target.current;
      // Add other properties like hashCode, runtimeType if needed
      case 'hashCode':
        return target.hashCode;
      case 'toString':
        return target.toString();
      default:
        throw RuntimeError('Iterator has no method mapping for "$name"');
    }
  }
}
