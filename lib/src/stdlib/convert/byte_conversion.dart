import 'dart:convert';

import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';

class ByteConversionConvert implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'ByteConversionSink',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return ByteConversionSink;
        }, arity: 0, name: 'ByteConversionSink'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    // Target must be an instance of a class implementing ByteConversionSink
    if (target is ByteConversionSink) {
      switch (name) {
        case 'add':
          if (arguments.length != 1 || arguments[0] is! List) {
            throw RuntimeError(
                'ByteConversionSink.add requires one List<int> argument.');
          }
          target.add((arguments[0] as List).cast());
          return null;
        case 'addSlice':
          if (arguments.length != 4 ||
              arguments[0] is! List ||
              arguments[1] is! int ||
              arguments[2] is! int ||
              arguments[3] is! bool) {
            throw RuntimeError(
                'ByteConversionSink.addSlice requires arguments (List, int, int, bool).');
          }
          target.addSlice((arguments[0] as List).cast(), arguments[1] as int,
              arguments[2] as int, arguments[3] as bool);
          return null;
        case 'close':
          if (arguments.isNotEmpty || namedArguments.isNotEmpty) {
            throw RuntimeError('ByteConversionSink.close takes no arguments.');
          }
          target.close();
          return null;
        // Methods inherited from Sink<List<int>>
        case 'toString': // From Object
          return target.toString();
        case 'hashCode': // From Object
          return target.hashCode;
        default:
          throw RuntimeError(
              'ByteConversionSink has no method mapping for "$name"');
      }
    } else {
      switch (name) {
        case 'from':
          if (arguments.length != 1 || arguments[0] is! Sink<List<int>>) {
            throw RuntimeError(
                'ByteConversionSink.from requires one Sink<List<int>> argument.');
          }
          return ByteConversionSink.from(arguments[0] as Sink<List<int>>);
        case 'withCallback':
          if (arguments.length != 1 || arguments[0] is! InterpretedFunction) {
            throw RuntimeError(
                'ByteConversionSink.withCallback requires one Function argument.');
          }
          final callback = arguments[0] as InterpretedFunction;
          return ByteConversionSink.withCallback((accumulated) {
            callback.call(visitor, [accumulated]);
          });

        default:
          throw RuntimeError(
              'ByteConversionSink has no static method mapping for "$name"');
      }
    }
  }
}
