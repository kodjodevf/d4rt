import 'dart:convert';
import 'dart:async'; // For Stream, Sink

import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';

class LineSplitterConvert implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'LineSplitter',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return LineSplitter();
        }, arity: 0, name: 'LineSplitter'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is LineSplitter) {
      // Extends Converter<String, List<String>>
      switch (name) {
        case 'convert':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'LineSplitter.convert requires one String argument.');
          }
          return target.convert(arguments[0] as String);
        case 'startChunkedConversion':
          if (arguments.length != 1 || arguments[0] is! Sink<String>) {
            throw RuntimeError(
                'startChunkedConversion requires a Sink<String> argument.');
          }
          return target.startChunkedConversion(arguments[0] as Sink<String>);
        case 'bind':
          if (arguments.length != 1 || arguments[0] is! Stream<String>) {
            throw RuntimeError('bind requires a Stream<String> argument.');
          }
          return target.bind(arguments[0] as Stream<String>);
        case 'cast':
          return target.cast<String, List<String>>();
        default:
          throw RuntimeError('LineSplitter has no method mapping for "$name"');
      }
    } else {
      throw RuntimeError(
          'Unsupported target for LineSplitterCore: ${target?.runtimeType}');
    }
  }
}
