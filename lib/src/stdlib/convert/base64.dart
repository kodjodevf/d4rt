import 'dart:convert';
import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart';

class Base64CodecConvert implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Define codec instances
    environment.define('base64', base64);
    environment.define('base64Url', base64Url);

    // Define types/constructors
    environment.define(
        'Base64Codec',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Default constructor takes no arguments
          if (arguments.isNotEmpty || namedArguments.isNotEmpty) {
            throw RuntimeError('Base64Codec constructor takes no arguments.');
          }
          return Base64Codec();
        }, arity: 0, name: 'Base64Codec'));
    environment.define(
        'Base64Codec.urlSafe',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // urlSafe factory constructor takes no arguments
          if (arguments.isNotEmpty || namedArguments.isNotEmpty) {
            throw RuntimeError(
                'Base64Codec.urlSafe constructor takes no arguments.');
          }
          return Base64Codec.urlSafe();
        }, arity: 0, name: 'Base64Codec.urlSafe'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is Base64Codec) {
      switch (name) {
        case 'encode':
          if (arguments.length != 1 || arguments[0] is! List) {
            throw RuntimeError('Base64Codec.encode requires a List argument.');
          }
          return target.encode((arguments[0] as List).cast());
        case 'decode':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'Base64Codec.decode requires a String argument.');
          }
          return target.decode(arguments[0] as String);
        case 'decoder': // Getter
          return target.decoder;
        case 'encoder': // Getter
          return target.encoder;
        case 'normalize':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'Base64Codec.normalize requires a String argument.');
          }
          final start = arguments.get<int>(1) ?? 0;
          final end = arguments.get<int?>(2);
          return target.normalize(arguments[0] as String, start, end);
        case 'inverted': // Added from Codec
          return target.inverted;
        case 'fuse': // Added from Codec
          // Base64Codec fuses with Codec<String, T>
          if (arguments.length != 1 ||
              arguments[0] is! Codec<String, dynamic>) {
            throw RuntimeError(
                'Base64Codec.fuse requires another Codec<String, dynamic> as argument.');
          }
          return target.fuse(arguments[0] as Codec<String, dynamic>);
        default:
          throw RuntimeError(
              'Base64Codec has no method/getter mapping for "$name"');
      }
    } else {
      throw RuntimeError(
          'Unsupported target for Base64CodecConvert: ${target?.runtimeType}');
    }
  }
}

class Base64EncoderConvert implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'Base64Encoder',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Default constructor takes no arguments
          if (arguments.isNotEmpty || namedArguments.isNotEmpty) {
            throw RuntimeError('Base64Encoder constructor takes no arguments.');
          }
          return Base64Encoder();
        }, arity: 0, name: 'Base64Encoder'));
    environment.define(
        'Base64Encoder.urlSafe',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Factory Constructor: takes no arguments
          if (arguments.isNotEmpty || namedArguments.isNotEmpty) {
            throw RuntimeError(
                'Base64Encoder.urlSafe factory constructor takes no arguments.');
          }
          return Base64Encoder.urlSafe();
        }, arity: 0, name: 'Base64Encoder.urlSafe'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is Base64Encoder) {
      // Base64Encoder extends Converter<List<int>, String>
      switch (name) {
        case 'convert':
          if (arguments.length != 1 || arguments[0] is! List) {
            throw RuntimeError(
                'Base64Encoder.convert requires a List argument.');
          }
          return target.convert((arguments[0] as List).cast());
        case 'startChunkedConversion':
          if (arguments.length != 1 || arguments[0] is! Sink<dynamic>) {
            throw RuntimeError(
                'startChunkedConversion requires a Sink<String> argument.');
          }
          return target.startChunkedConversion(arguments[0] as Sink<String>);
        case 'bind': // Added
          if (arguments.length != 1 || arguments[0] is! Stream<List<int>>) {
            throw RuntimeError('bind requires a Stream<List<int>> argument.');
          }
          return target.bind(arguments[0] as Stream<List<int>>);
        case 'fuse':
          if (arguments.length != 1 ||
              arguments[0] is! Converter<String, dynamic>) {
            throw RuntimeError(
                'Base64Encoder.fuse requires another Converter<String, dynamic> as argument.');
          }
          return target.fuse(arguments[0] as Converter<String, dynamic>);
        case 'cast': // Added
          return target.cast<List<int>, String>();
        default:
          throw RuntimeError(
              'Base64Encoder has no method/getter mapping for "$name"');
      }
    } else {
      throw RuntimeError(
          'Unsupported target for Base64Encoder: ${target?.runtimeType}');
    }
  }
}

class Base64DecoderConvert implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'Base64Decoder',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Constructor takes no arguments
          if (arguments.isNotEmpty || namedArguments.isNotEmpty) {
            throw RuntimeError('Base64Decoder constructor takes no arguments.');
          }
          return Base64Decoder();
        }, arity: 0, name: 'Base64Decoder'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is Base64Decoder) {
      // Base64Decoder extends Converter<String, List<int>>
      switch (name) {
        case 'convert':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'Base64Decoder.convert requires a String argument.');
          }
          return target.convert(arguments[0] as String);
        case 'startChunkedConversion':
          if (arguments.length != 1 || arguments[0] is! Sink<List<int>>) {
            throw RuntimeError(
                'startChunkedConversion requires a Sink<List<int>> argument.');
          }
          return target.startChunkedConversion(arguments[0] as Sink<List<int>>);
        case 'bind': // Added
          if (arguments.length != 1 || arguments[0] is! Stream<String>) {
            throw RuntimeError('bind requires a Stream<String> argument.');
          }
          return target.bind(arguments[0] as Stream<String>);
        case 'fuse': // Added
          // Decoder<String, List<int>> fuses with Converter<List<int>, T>
          if (arguments.length != 1 ||
              arguments[0] is! Converter<List<int>, dynamic>) {
            throw RuntimeError(
                'Base64Decoder.fuse requires another Converter<List<int>, dynamic> as argument.');
          }
          return target.fuse(arguments[0] as Converter<List<int>, dynamic>);
        case 'cast': // Added
          return target.cast<String, List<int>>();
        default:
          throw RuntimeError(
              'Base64Decoder has no method/getter mapping for "$name"');
      }
    } else {
      throw RuntimeError(
          'Unsupported target for Base64Decoder: ${target?.runtimeType}');
    }
  }
}
