import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart';
import 'package:d4rt/src/utils/extensions/map.dart';
import 'dart:core'; // For RegExp, RegExpMatch

class RegExpCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'RegExp',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return arguments.isEmpty
              ? RegExp
              : RegExp(arguments[0] as String,
                  multiLine: namedArguments.get<bool?>('multiLine') ?? false,
                  caseSensitive:
                      namedArguments.get<bool?>('caseSensitive') ?? true,
                  unicode: namedArguments.get<bool?>('unicode') ?? false,
                  dotAll: namedArguments.get<bool?>('dotAll') ?? false);
        },
            arity: 1, // 1 required positional, rest named
            name: 'RegExp'));

    environment.define(
        'RegExpMatch',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return RegExpMatch;
        }, arity: 0, name: 'RegExpMatch'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is RegExp) {
      switch (name) {
        case 'hasMatch':
          return target.hasMatch(arguments[0] as String);
        case 'allMatches':
          return target.allMatches(
              arguments[0] as String, arguments.get<int>(1) ?? 0);
        case 'stringMatch':
          return target.stringMatch(arguments[0] as String);
        case 'toString':
          return target.toString();
        case 'matchAsPrefix':
          return target.matchAsPrefix(
              arguments[0] as String, arguments.get<int>(1) ?? 0);
        case 'firstMatch':
          return target.firstMatch(arguments[0] as String);
        case 'isCaseSensitive':
          return target.isCaseSensitive;
        case 'isDotAll':
          return target.isDotAll;
        case 'isMultiLine':
          return target.isMultiLine;
        case 'isUnicode':
          return target.isUnicode;
        case 'pattern':
          return target.pattern;
        case 'hashCode':
          return target.hashCode;
        default:
          throw RuntimeError(
              'RegExp has no instance method/getter mapping for "$name"');
      }
    } else {
      switch (name) {
        case 'escape':
          return RegExp.escape(arguments[0] as String);
        default:
          throw RuntimeError('RegExp has no static method mapping for "$name"');
      }
    }
  }
}
