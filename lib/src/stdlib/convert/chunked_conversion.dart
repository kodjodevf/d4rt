import 'dart:convert';
import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';

class ChunkedConversionConvert implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Define the abstract type
    environment.define(
        'ChunkedConversionSink',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return ChunkedConversionSink;
        }, arity: 0, name: 'ChunkedConversionSink'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    // Target is expected to be an instance of a class implementing ChunkedConversionSink
    if (target is ChunkedConversionSink) {
      switch (name) {
        case 'add':
          // Input type T is dynamic here
          if (arguments.length != 1) {
            throw RuntimeError(
                'ChunkedConversionSink.add requires one argument.');
          }
          target.add(arguments[0]);
          return null;
        case 'close':
          if (arguments.isNotEmpty || namedArguments.isNotEmpty) {
            throw RuntimeError(
                'ChunkedConversionSink.close takes no arguments.');
          }
          target.close();
          return null;
        default:
          throw RuntimeError(
              'ChunkedConversionSink has no instance method mapping for "$name"');
      }
    } else {
      switch (name) {
        case 'withCallback':
          if (arguments.length != 1 || arguments[0] is! InterpretedFunction) {
            throw RuntimeError(
                'ChunkedConversionSink.withCallback requires an InterpretedFunction callback.');
          }
          final callback = arguments[0] as InterpretedFunction;
          // The native callback receives List<T>, need to forward to interpreted function
          return ChunkedConversionSink<dynamic>.withCallback(
              (List<dynamic> chunks) {
            callback.call(visitor, [chunks]); // Pass the list of chunks
          });

        default:
          throw RuntimeError(
              'ChunkedConversionSink has no instance static method mapping for "$name"');
      }
    }
  }
}
