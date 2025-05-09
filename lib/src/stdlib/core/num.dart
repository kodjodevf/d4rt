import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart';

class NumCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'num',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return num;
        }, arity: 0, name: 'num'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is num) {
      switch (name) {
        case 'abs':
          return target.abs();
        case 'ceil':
          return target.ceil();
        case 'floor':
          return target.floor();
        case 'round':
          return target.round();
        case 'toInt':
          return target.toInt();
        case 'toDouble':
          return target.toDouble();
        case 'toString':
          return target.toString();
        case 'isFinite':
          return target.isFinite;
        case 'isInfinite':
          return target.isInfinite;
        case 'isNaN':
          return target.isNaN;
        case 'isNegative':
          return target.isNegative;
        case 'clamp':
          return target.clamp(arguments[0] as num, arguments[1] as num);
        case 'remainder':
          return target.remainder(arguments[0] as num);
        case 'compareTo':
          return target.compareTo(arguments[0] as num);
        case 'sign':
          return target.sign;
        case 'toStringAsFixed':
          return target.toStringAsFixed(arguments[0] as int);
        case 'toStringAsExponential':
          return target.toStringAsExponential(arguments.get<int?>(0));
        case 'toStringAsPrecision':
          return target.toStringAsPrecision(arguments[0] as int);
        case 'hashCode':
          return target.hashCode;
        case 'truncate':
          return target.truncate();
        case 'truncateToDouble':
          return target.truncateToDouble();
        case 'ceilToDouble':
          return target.ceilToDouble();
        case 'floorToDouble':
          return target.floorToDouble();
        case 'roundToDouble':
          return target.roundToDouble();
        default:
          throw RuntimeError('num has no instance method mapping for "$name"');
      }
    } else {
      // static methods
      switch (name) {
        case 'parse':
          // Handle onError named parameter
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError('num.parse expects one String argument.');
          }
          return num.parse(arguments[0] as String);
        case 'tryParse':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError('num.tryParse expects one String argument.');
          }
          return num.tryParse(arguments[0] as String);
        default:
          throw RuntimeError('num has no static method mapping for "$name"');
      }
    }
  }
}
