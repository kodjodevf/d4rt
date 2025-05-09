import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart'; // Assuming extension is here

class PatternCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Define Pattern and Match types
    environment.define(
        'Pattern',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return Pattern;
        }, arity: 0, name: 'Pattern'));
    environment.define(
        'Match',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Match objects are usually returned by Pattern methods, not constructed directly.
          return Match;
        }, arity: 0, name: 'Match'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is Pattern) {
      // Note: Pattern itself doesn't have many methods, usually implemented by String or RegExp
      switch (name) {
        case 'allMatches':
          return target.allMatches(
              arguments[0] as String, arguments.get<int>(1) ?? 0);
        case 'matchAsPrefix':
          // Caution: matchAsPrefix returns Match?, handle null
          return target.matchAsPrefix(
              arguments[0] as String, arguments.get<int>(1) ?? 0);
        // Add hashCode, toString if needed
        case 'hashCode':
          return target.hashCode;
        case 'toString':
          return target.toString();
        default:
          throw RuntimeError(
              'Pattern has no instance method mapping for "$name"');
      }
    }
    // Should not happen if target is Match or Pattern
    throw RuntimeError(
        'Target must be a Match or Pattern, but was ${target?.runtimeType}');
  }
}

class MatchCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'Match',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Match objects are usually returned by Pattern methods, not constructed directly.
          return Match;
        }, arity: 0, name: 'Match'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is Match) {
      switch (name) {
        case 'end':
          return target.end;
        case 'groupCount':
          return target.groupCount;
        case 'input':
          return target.input;
        case 'start':
          return target.start;
        case 'group':
          return target.group(arguments[0] as int);
        case 'groups':
          return target.groups(arguments[0] as List<int>);
        // Add pattern, [], hashCode, toString if needed
        case 'pattern':
          return target.pattern; // Assuming Match has pattern property
        case '[]': // Index operator for groups
          if (arguments.length != 1 || arguments[0] is! int) {
            throw RuntimeError(
                'Match index operator [] requires one integer argument (group index).');
          }
          return target[arguments[0] as int];
        case 'hashCode':
          return target.hashCode;
        case 'toString':
          return target.toString();
        default:
          throw RuntimeError(
              'Match has no instance method mapping for "$name"');
      }
    }
    // Should not happen if target is Match or Pattern
    throw RuntimeError(
        'Target must be a Match or Pattern, but was ${target?.runtimeType}');
  }
}
