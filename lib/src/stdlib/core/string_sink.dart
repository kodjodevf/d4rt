import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart'; // Assuming extension is here
import 'dart:core'; // For StringSink type

class StringSinkCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // StringSink is abstract, usually implemented by StringBuffer.
    // Define the type name.
    environment.define(
        'StringSink',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return StringSink;
        }, arity: 0, name: 'StringSink'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is! StringSink) {
      // Or check for specific implementations like StringBuffer
      throw RuntimeError(
          'Target for StringSink method call must be a StringSink, but was ${target?.runtimeType}');
    }

    switch (name) {
      case 'write':
        // write takes one argument of type Object?
        if (arguments.length != 1) {
          throw RuntimeError('StringSink.write requires exactly one argument.');
        }
        target.write(arguments[0]);
        return null;
      case 'writeln':
        // writeln takes one optional argument of type Object?
        if (arguments.length > 1) {
          throw RuntimeError('StringSink.writeln takes at most one argument.');
        }
        target.writeln(arguments.get<Object?>(0) ?? "");
        return null;
      case 'writeAll':
        // writeAll takes an Iterable and an optional separator String
        if (arguments.isEmpty ||
            arguments.length > 2 ||
            arguments[0] is! Iterable) {
          throw RuntimeError(
              'StringSink.writeAll requires an Iterable and an optional separator String.');
        }
        target.writeAll(
            arguments[0] as Iterable, arguments.get<String?>(1) ?? "");
        return null;
      case 'writeCharCode':
        if (arguments.length != 1 || arguments[0] is! int) {
          throw RuntimeError(
              'StringSink.writeCharCode requires one integer argument.');
        }
        target.writeCharCode(arguments[0] as int);
        return null;
      // Add hashCode, toString if needed
      case 'hashCode':
        return target.hashCode;
      case 'toString':
        // Note: StringSink itself doesn't guarantee toString returns the content
        // StringBuffer does.
        return target.toString();
      default:
        throw RuntimeError('StringSink has no method mapping for "$name"');
    }
  }
}
