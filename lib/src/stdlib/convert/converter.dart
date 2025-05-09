import 'dart:convert';
import 'dart:async'; // For Stream
import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';

class ConverterConvert implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Define the abstract type Converter
    environment.define(
        'Converter',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Converter is abstract, cannot be instantiated directly.
          return Converter;
        }, arity: 0, name: 'Converter'));
    // Define factory constructors if applicable (e.g., Converter.castFrom? No, that's Codec)
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    // Target should be an instance of a class that implements Converter
    if (target is Converter) {
      switch (name) {
        case 'convert':
          // Input type S is dynamic here
          return target.convert(arguments[0]);
        case 'startChunkedConversion':
          // Argument type Sink<T> is dynamic here
          if (arguments.length != 1 || arguments[0] is! Sink) {
            throw RuntimeError(
                'startChunkedConversion requires one Sink argument.');
          }
          return target.startChunkedConversion(arguments[0] as Sink);
        case 'bind': // Added
          // Argument type Stream<S> is dynamic here
          if (arguments.length != 1 || arguments[0] is! Stream) {
            throw RuntimeError('bind requires one Stream argument.');
          }
          return target.bind(arguments[0] as Stream);
        case 'fuse': // Added
          // Argument type Converter<T, dynamic> is dynamic here
          if (arguments.length != 1 || arguments[0] is! Converter) {
            throw RuntimeError('fuse requires another Converter as argument.');
          }
          return target.fuse(arguments[0] as Converter);
        case 'cast': // Added
          // Type args RS, RT cannot be determined here easily
          return target.cast<dynamic, dynamic>();
        default:
          throw RuntimeError(
              'Converter has no instance method mapping for "$name"');
      }
    } else {
      // Handle static methods if any (like Codec.castFrom)
      throw RuntimeError(
          'Unsupported target for Converter method call: ${target?.runtimeType}');
    }
  }
}
