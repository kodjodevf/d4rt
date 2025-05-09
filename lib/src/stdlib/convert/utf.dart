import 'dart:convert';
import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart';
import 'package:d4rt/src/utils/extensions/map.dart';

class Utf8CodecConvert implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Define the codec instance
    environment.define('utf8', utf8);

    // Define the types/constructors
    environment.define(
        'Utf8Codec',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Constructor: Utf8Codec({bool allowMalformed = false})
          final allowMalformed =
              namedArguments.get<bool?>('allowMalformed') ?? false;
          return Utf8Codec(allowMalformed: allowMalformed);
        }, arity: 0, name: 'Utf8Codec'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is Utf8Codec) {
      switch (name) {
        case 'encode':
          return target.encode(arguments[0] as String);
        case 'decode':
          // Ensure the argument is List<int>
          if (arguments.length != 1 || arguments[0] is! List) {
            throw RuntimeError('Utf8Codec.decode requires a List argument.');
          }
          final allowMalformed = namedArguments
              .get<bool>('allowMalformed'); // Optional param for decode
          return target.decode((arguments[0] as List).cast(),
              allowMalformed: allowMalformed);
        case 'encoder': // Getter
          return target.encoder;
        case 'decoder': // Getter
          return target.decoder;
        case 'name': // Getter for Codec
          return target.name;
        case 'fuse': // Added from Codec
          if (arguments.length != 1 ||
              arguments[0] is! Codec<List<int>, dynamic>) {
            throw RuntimeError(
                'Utf8Codec.fuse requires another Codec<List<int>, dynamic> as argument.');
          }
          return target.fuse(arguments[0] as Codec<List<int>, dynamic>);
        case 'inverted': // Added from Codec
          return target.inverted;
        default:
          throw RuntimeError(
              'Utf8Codec has no method/getter mapping for "$name"');
      }
    } else {
      // Could handle top-level functions like utf8.encode/decode here if not methods
      throw RuntimeError(
          'Unsupported target for UtfCodec: ${target?.runtimeType}');
    }
  }
}

class Utf8EncoderConvert implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'Utf8Encoder',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Constructor takes no arguments
          if (arguments.isNotEmpty || namedArguments.isNotEmpty) {
            throw RuntimeError('Utf8Encoder constructor takes no arguments.');
          }
          return Utf8Encoder();
        }, arity: 0, name: 'Utf8Encoder'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is Utf8Encoder) {
      // Utf8Encoder inherits from Converter<String, List<int>>
      switch (name) {
        case 'convert':
          return target.convert(arguments[0] as String);
        case 'startChunkedConversion': // Added
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
          if (arguments.length != 1 ||
              arguments[0] is! Converter<List<int>, dynamic>) {
            throw RuntimeError(
                'Utf8Encoder.fuse requires another Converter<List<int>, dynamic> as argument.');
          }
          return target.fuse(arguments[0] as Converter<List<int>, dynamic>);
        case 'cast': // Added
          return target.cast<String, List<int>>(); // Types are fixed
        default:
          throw RuntimeError(
              'Utf8Encoder has no method/getter mapping for "$name"');
      }
    } else {
      // Could handle top-level functions like utf8.encode/decode here if not methods
      throw RuntimeError(
          'Unsupported target for Utf8Encoder: ${target?.runtimeType}');
    }
  }
}

class Utf8DecoderConvert implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'Utf8Decoder',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Constructor: Utf8Decoder({bool allowMalformed = false})
          final allowMalformed =
              namedArguments.get<bool?>('allowMalformed') ?? false;
          return Utf8Decoder(allowMalformed: allowMalformed);
        }, arity: 0, name: 'Utf8Decoder'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is Utf8Decoder) {
      // Utf8Decoder inherits from Converter<List<int>, String>
      switch (name) {
        case 'convert':
          if (arguments.length != 1 || arguments[0] is! List) {
            throw RuntimeError('Utf8Decoder.convert requires a List argument.');
          }
          return target.convert((arguments[0] as List).cast(),
              arguments.get<int?>(1) ?? 0, arguments.get<int?>(2));
        case 'startChunkedConversion': // Added
          if (arguments.length != 1 || arguments[0] is! Sink<String>) {
            throw RuntimeError(
                'startChunkedConversion requires a Sink<String> argument.');
          }
          return target.startChunkedConversion(arguments[0] as Sink<String>);
        case 'bind': // Added
          if (arguments.length != 1 || arguments[0] is! Stream<List<int>>) {
            throw RuntimeError('bind requires a Stream<List<int>> argument.');
          }
          return target.bind(arguments[0] as Stream<List<int>>);
        case 'fuse': // Added
          if (arguments.length != 1 ||
              arguments[0] is! Converter<String, dynamic>) {
            throw RuntimeError(
                'Utf8Decoder.fuse requires another Converter<String, dynamic> as argument.');
          }
          return target.fuse(arguments[0] as Converter<String, dynamic>);
        case 'cast': // Added
          return target.cast<List<int>, String>(); // Types are fixed
        default:
          throw RuntimeError(
              'Utf8Decoder has no method/getter mapping for "$name"');
      }
    } else {
      // Could handle top-level functions like utf8.encode/decode here if not methods
      throw RuntimeError(
          'Unsupported target for Utf8Decoder: ${target?.runtimeType}');
    }
  }
}
