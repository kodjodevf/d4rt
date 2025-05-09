import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart';
import 'package:d4rt/src/utils/extensions/map.dart';

class StringCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'String',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return String;
        }, arity: 0, name: 'String'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is String) {
      switch (name) {
        case '[]': // Index operator
          if (arguments.length != 1 || arguments[0] is! int) {
            throw RuntimeError(
                'String index operator [] requires one int argument.');
          }
          return target[arguments[0] as int];
        case 'substring':
          return target.substring(arguments[0] as int, arguments.get<int?>(1));
        case 'toUpperCase':
          return target.toUpperCase();
        case 'toLowerCase':
          return target.toLowerCase();
        case 'contains':
          return target.contains(
              arguments[0] as Pattern, arguments.get<int>(1) ?? 0);
        case 'startsWith':
          return target.startsWith(
              arguments[0] as Pattern, arguments.get<int>(1) ?? 0);
        case 'endsWith':
          return target.endsWith(arguments[0] as String);
        case 'indexOf':
          return target.indexOf(
              arguments[0] as Pattern, arguments.get<int>(1) ?? 0);
        case 'lastIndexOf':
          return target.lastIndexOf(
              arguments[0] as Pattern, arguments.get<int?>(1));
        case 'trim':
          return target.trim();
        case 'trimLeft': // Added
          return target.trimLeft();
        case 'trimRight': // Added
          return target.trimRight();
        case 'replaceAll':
          return target.replaceAll(
              arguments[0] as Pattern, arguments[1] as String);
        case 'split':
          return target.split(arguments[0] as Pattern);
        case 'splitMapJoin': // Added
          final pattern = arguments[0] as Pattern;
          final onMatch = namedArguments.get<InterpretedFunction?>('onMatch');
          final onNonMatch =
              namedArguments.get<InterpretedFunction?>('onNonMatch');
          return target.splitMapJoin(
            pattern,
            onMatch: onMatch == null
                ? null
                : (Match m) => onMatch.call(visitor, [m]) as String,
            onNonMatch: onNonMatch == null
                ? null
                : (String s) => onNonMatch.call(visitor, [s]) as String,
          );
        case 'padLeft':
          return target.padLeft(
              arguments[0] as int, arguments.get<String>(1) ?? ' ');
        case 'padRight':
          return target.padRight(
              arguments[0] as int, arguments.get<String>(1) ?? ' ');
        case 'replaceFirst':
          return target.replaceFirst(arguments[0] as Pattern,
              arguments[1] as String, arguments.get<int>(2) ?? 0);
        case 'replaceRange':
          return target.replaceRange(arguments[0] as int,
              arguments.get<int?>(1), arguments[2] as String);
        case 'codeUnitAt':
          return target.codeUnitAt(arguments[0] as int);
        case 'toString':
          return target.toString();
        case 'compareTo':
          return target.compareTo(arguments[0] as String);
        case 'isEmpty':
          return target.isEmpty;
        case 'isNotEmpty':
          return target.isNotEmpty;
        case 'length':
          return target.length;
        case 'codeUnits':
          return target.codeUnits;
        case 'runes':
          return target.runes;
        case 'allMatches':
          return target.allMatches(
              arguments[0] as String, arguments.get<int?>(1) ?? 0);
        case 'replaceAllMapped':
          final pattern = arguments[0] as Pattern;
          final replace = arguments[1];
          if (replace is! InterpretedFunction) {
            throw RuntimeError(
                'Expected an InterpretedFunction for replaceAllMapped');
          }
          return target.replaceAllMapped(pattern, (match) {
            return replace.call(visitor, [match]) as String;
          });
        case 'replaceFirstMapped':
          final pattern = arguments[0] as Pattern;
          final replace = arguments[1];
          if (replace is! InterpretedFunction) {
            throw RuntimeError(
                'Expected an InterpretedFunction for replaceFirstMapped');
          }
          final startIndex = arguments.get<int>(2) ?? 0;
          return target.replaceFirstMapped(pattern, (match) {
            return replace.call(visitor, [match]) as String;
          }, startIndex);
        case 'hashCode':
          return target.hashCode;
        default:
          throw RuntimeError(
              'String has no instance method mapping for "$name"');
      }
    } else if (target == String) {
      // Static methods called on String type
      switch (name) {
        case 'fromCharCode':
          return String.fromCharCode(arguments[0] as int);
        case 'fromCharCodes':
          return String.fromCharCodes(
              (arguments[0] as List).cast<int>(), // Ensure List<int>
              arguments.get<int>(1) ?? 0,
              arguments.get<int?>(2));
        case 'fromEnvironment':
          return String.fromEnvironment(arguments[0] as String,
              // defaultValue is a named argument
              defaultValue: namedArguments.get<String?>('defaultValue') ?? '');
        default:
          throw RuntimeError('String has no static method mapping for "$name"');
      }
    } else {
      throw RuntimeError(
          'Invalid target for String method call: ${target?.runtimeType}');
    }
  }
}
