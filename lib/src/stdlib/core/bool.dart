import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/map.dart'; // Assuming extension is here

class BoolCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'bool',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // The actual bool type/constructor needs careful handling if direct instantiation is needed.
          // For now, just making the name 'bool' resolve to the Dart type.
          return bool;
        }, arity: 0, name: 'bool'));
    // Static methods like parse, tryParse, etc., are handled in evalMethod
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is bool) {
      switch (name) {
        case 'toString':
          return target.toString();
        case 'hashCode':
          return target.hashCode;
        case 'runtimeType':
          return target.runtimeType;
        default:
          // Use RuntimeError as per ListCore
          throw RuntimeError('bool has no instance method mapping for "$name"');
      }
    } else {
      // static methods
      switch (name) {
        case 'parse':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError("bool.parse expects one String argument.");
          }
          // Use namedArguments.get for optional named parameters
          return bool.parse(arguments[0] as String,
              caseSensitive: namedArguments.get<bool?>('caseSensitive') ??
                  true); // Dart default is true
        case 'tryParse':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError("bool.tryParse expects one String argument.");
          }
          // Use namedArguments.get for optional named parameters
          return bool.tryParse(arguments[0] as String,
              caseSensitive: namedArguments.get<bool?>('caseSensitive') ??
                  true); // Dart default is true
        case 'fromEnvironment':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                "bool.fromEnvironment expects one String argument for the name.");
          }
          // Use namedArguments.get for optional named parameters
          return bool.fromEnvironment(arguments[0] as String,
              defaultValue: namedArguments.get<bool?>('defaultValue') ?? false);
        case 'hasEnvironment':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                "bool.hasEnvironment expects one String argument.");
          }
          return bool.hasEnvironment(arguments[0] as String);
        default:
          // Use RuntimeError as per ListCore
          throw RuntimeError('bool has no static method mapping for "$name"');
      }
    }
  }
}
