import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart';

class StringBufferCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'StringBuffer',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return arguments.isEmpty
              ? StringBuffer()
              : StringBuffer(arguments[0] as String);
        }, arity: 1, name: 'StringBuffer'));
  }

  @override
  Object? evalMethod(Object? target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    target = target as StringBuffer;
    switch (name) {
      case 'write':
        target.write(arguments[0]);
        return null;
      case 'writeln':
        target.writeln(arguments.get<Object?>(0) ?? "");
        return null;
      case 'writeAll':
        target.writeAll(
            arguments[0] as Iterable, arguments.get<String?>(1) ?? "");
        return null;
      case 'writeCharCode':
        target.writeCharCode(arguments[0] as int);
        return null;
      case 'clear':
        target.clear();
        return null;
      case 'toString':
        return target.toString();
      case 'length':
        return target.length;
      case 'isEmpty':
        return target.isEmpty;
      case 'isNotEmpty':
        return target.isNotEmpty;
      default:
        throw RuntimeError('StringBuffer has no method mapping for "$name"');
    }
  }
}
