import 'dart:convert';
import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';

class CodecConvert implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Define the abstract type name
    environment.define(
        'Codec',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Codec is abstract, cannot be instantiated directly.
          return Codec;
        }, arity: 0, name: 'Codec'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    // Target must be an instance of a class implementing Codec
    if (target is Codec) {
      switch (name) {
        case 'encode':
          // Input type S is dynamic
          if (arguments.length != 1) {
            throw RuntimeError('Codec.encode requires one argument.');
          }
          return target.encode(arguments[0]);
        case 'decode':
          // Input type T is dynamic
          if (arguments.length != 1) {
            throw RuntimeError('Codec.decode requires one argument.');
          }
          return target.decode(arguments[0]);
        case 'fuse':
          // Argument type Codec<T, dynamic> is dynamic
          if (arguments.length != 1 || arguments[0] is! Codec) {
            throw RuntimeError(
                'Codec.fuse requires another Codec as argument.');
          }
          return target.fuse(arguments[0] as Codec);
        case 'inverted': // Getter
          return target.inverted;
        case 'decoder': // Getter
          return target.decoder;
        case 'encoder': // Getter
          return target.encoder;
        default:
          throw RuntimeError('Codec has no method mapping for "$name"');
      }
    } else {
      throw RuntimeError(
          'Unsupported target for CodecConvert: ${target?.runtimeType}');
    }
  }
}
