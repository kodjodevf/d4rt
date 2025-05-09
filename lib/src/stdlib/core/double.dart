import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart';

class DoubleCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'double',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Similar to other types, return the Dart type for now.
          return double;
        }, arity: 0, name: 'double'));
    // Static members like constants and parse are handled in evalMethod
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is double) {
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
        case 'compareTo':
          return target.compareTo(arguments[0] as num);
        // 'parse' is static
        case 'sign':
          return target.sign;
        case 'toStringAsFixed':
          return target.toStringAsFixed(arguments[0] as int);
        case 'toStringAsExponential':
          // Optional parameter requires List extension or check
          return target.toStringAsExponential(arguments.get<int?>(0));
        case 'toStringAsPrecision':
          return target.toStringAsPrecision(arguments[0] as int);
        case 'hashCode':
          return target.hashCode;
        default:
          throw RuntimeError(
              'double has no instance method mapping for "$name"');
      }
    } else {
      // static methods and constants
      switch (name) {
        case 'parse':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError("double.parse expects one String argument.");
          }
          return double.parse(arguments[0] as String);
        case 'tryParse':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError("double.tryParse expects one String argument.");
          }
          return double.tryParse(arguments[0] as String);
        case 'maxFinite':
          return double.maxFinite;
        case 'infinity':
          return double.infinity;
        case 'minPositive':
          return double.minPositive;
        case 'nan':
          return double.nan;
        case 'negativeInfinity':
          return double.negativeInfinity;
        default:
          throw RuntimeError('double has no static member mapping for "$name"');
      }
    }
  }
}
