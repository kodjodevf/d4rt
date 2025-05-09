import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart';
import 'package:d4rt/src/utils/extensions/map.dart';

class IntCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'int',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // 'int' itself is a type
          return int;
        }, arity: 0, name: 'int'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is int) {
      switch (name) {
        case 'abs':
          return target.abs();
        case 'ceil':
          return target.ceil();
        case 'floor':
          return target.floor();
        case 'round':
          return target.round();
        case 'toDouble':
          return target.toDouble();
        case 'toInt':
          return target.toInt();
        case 'toString':
          return target.toString();
        // 'parse' is static
        case 'isEven':
          return target.isEven;
        case 'isOdd':
          return target.isOdd;
        case 'bitLength':
          return target.bitLength;
        case 'sign':
          return target.sign;
        case 'gcd':
          return target.gcd(arguments[0] as int);
        case 'isNegative':
          return target.isNegative;
        case 'modPow':
          return target.modPow(arguments[0] as int, arguments[1] as int);
        case 'modInverse':
          return target.modInverse(arguments[0] as int);
        case 'toRadixString':
          return target.toRadixString(arguments[0] as int);
        case 'compareTo':
          return target.compareTo(arguments[0] as num);
        case 'remainder':
          return target.remainder(arguments[0] as num);
        case 'clamp':
          return target.clamp(arguments[0] as num, arguments[1] as num);
        case 'toUnsigned':
          return target.toUnsigned(arguments[0] as int);
        case 'toSigned':
          return target.toSigned(arguments[0] as int);
        case 'hashCode':
          return target.hashCode;
        case 'isFinite':
          return target.isFinite;
        case 'isInfinite':
          return target.isInfinite;
        case 'isNaN':
          return target.isNaN;
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
        case 'toStringAsFixed':
          return target.toStringAsFixed(arguments[0] as int);
        case 'toStringAsExponential':
          return target.toStringAsExponential(arguments.get<int?>(0));
        case 'toStringAsPrecision':
          return target.toStringAsPrecision(arguments[0] as int);
        default:
          throw RuntimeError('int has no instance method mapping for "$name"');
      }
    } else {
      // static methods
      switch (name) {
        case 'parse':
          // Handle radix named parameter
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError('int.parse expects one String argument.');
          }
          // int.parse does not have onError, use tryParse for that behavior
          return int.parse(arguments[0] as String,
              radix: namedArguments.get<int?>('radix'));
        case 'tryParse':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError('int.tryParse expects one String argument.');
          }
          return int.tryParse(arguments[0] as String,
              radix: namedArguments.get<int?>('radix'));
        case 'fromEnvironment':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'int.fromEnvironment expects one String argument for the name.');
          }
          return int.fromEnvironment(arguments[0] as String,
              defaultValue: namedArguments.get<int?>('defaultValue') ?? 0);
        default:
          throw RuntimeError('int has no static method mapping for "$name"');
      }
    }
  }
}
