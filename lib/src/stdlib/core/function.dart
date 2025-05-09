import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';

class FunctionCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Defining 'Function' itself might be complex depending on desired semantics.
    // Just making the name resolve for now.
    environment.define(
        'Function',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return Function;
        }, arity: 0, name: 'Function'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    // The target of a method call on a function should be the function itself.
    // We expect it to be a Callable (NativeFunction or InterpretedFunction).
    if (target is Callable) {
      switch (name) {
        case 'call':
          // Directly call the Callable target using the visitor
          // Assumes the arguments passed are positional.
          // Named argument handling for Function.call would need more logic.
          return target.call(visitor, arguments, {});
        case 'hashCode':
          return target.hashCode; // Use the callable's hashCode
        case 'toString':
          return target.toString(); // Use the callable's toString
        default:
          throw RuntimeError(
              'Function has no instance method mapping for "$name"');
      }
    } else {
      switch (name) {
        case 'apply':
          if (arguments.isEmpty || arguments[0] is! Callable) {
            throw RuntimeError(
                'Function.apply requires a Callable as the first argument.');
          }
          final functionToApply = arguments[0] as Callable;
          final positionalArgs = (arguments.length > 1 && arguments[1] is List)
              ? arguments[1] as List<Object?>
              : <Object?>[];
          final namedArgsMap = (arguments.length > 2 && arguments[2] is Map)
              ? (arguments[2] as Map).cast<String, Object?>()
              : <String, Object?>{};

          return functionToApply.call(visitor, positionalArgs, namedArgsMap);
        default:
          throw RuntimeError(
              'Function has no static method mapping for "$name"');
      }
    }
  }
}
