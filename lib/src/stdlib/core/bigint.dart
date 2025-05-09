import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/map.dart'; // Assuming extension is here

class BigIntCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'BigInt',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return BigInt;
        }, arity: 0, name: 'BigInt'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is BigInt) {
      switch (name) {
        case 'toInt':
          return target.toInt();
        case 'toDouble':
          return target.toDouble();
        case 'isEven':
          return target.isEven;
        case 'isOdd':
          return target.isOdd;
        case 'abs':
          return target.abs();
        case 'compareTo':
          return target.compareTo(arguments[0] as BigInt);
        case 'toString':
          return target.toString();
        // case 'parse': // 'parse' is static, not instance
        //   return BigInt.parse(arguments[0] as String);
        case 'bitLength':
          return target.bitLength;
        case 'sign':
          return target.sign;
        case 'gcd':
          return target.gcd(arguments[0] as BigInt);
        case 'modPow':
          return target.modPow(arguments[0] as BigInt, arguments[1] as BigInt);
        case 'modInverse':
          return target.modInverse(arguments[0] as BigInt);
        case 'remainder':
          return target.remainder(arguments[0] as BigInt);
        case 'toRadixString':
          return target.toRadixString(arguments[0] as int);
        case 'pow':
          return target.pow(arguments[0] as int);
        case 'toUnsigned':
          return target.toUnsigned(arguments[0] as int);
        case 'toSigned':
          return target.toSigned(arguments[0] as int);
        case 'isValidInt':
          return target.isValidInt;
        default:
          // Use RuntimeError as per ListCore
          throw RuntimeError(
              'BigInt has no instance method mapping for "$name"');
      }
    } else {
      // static methods
      switch (name) {
        case 'parse':
          return BigInt.parse(arguments[0] as String,
              radix: namedArguments.get<int?>('radix'));
        case 'tryParse':
          return BigInt.tryParse(arguments[0] as String,
              radix: namedArguments.get<int?>('radix'));
        case 'from':
          return BigInt.from(arguments[0] as int);
        default:
          // Use RuntimeError as per ListCore
          throw RuntimeError('BigInt has no static method mapping for "$name"');
      }
    }
  }
}
