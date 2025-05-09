import 'dart:convert';
import 'dart:async'; // For Stream, Sink
import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/map.dart';

class AsciiCodecConvert implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Define the codec instance
    environment.define('ascii', ascii);

    // Define the types/constructors
    environment.define(
        'AsciiCodec',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Constructor: AsciiCodec({bool allowInvalid = false})
          final allowInvalid =
              namedArguments.get<bool?>('allowInvalid') ?? false;
          return namedArguments.isEmpty
              ? AsciiCodec
              : AsciiCodec(allowInvalid: allowInvalid);
        }, arity: 0, name: 'AsciiCodec'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is AsciiCodec) {
      // Extends Encoding
      switch (name) {
        case 'encode':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError('AsciiCodec.encode requires a String argument.');
          }
          return target.encode(arguments[0] as String);
        case 'decode':
          if (arguments.length != 1 || arguments[0] is! List) {
            throw RuntimeError('AsciiCodec.decode requires a List argument.');
          }
          final allowInvalid =
              namedArguments.get<bool?>('allowInvalid'); // Optional
          return target.decode((arguments[0] as List).cast(),
              allowInvalid: allowInvalid);
        case 'name': // Getter
          return target.name;
        case 'encoder': // Getter
          return target.encoder;
        case 'decoder': // Getter
          return target.decoder;
        case 'fuse': // Added from Codec
          if (arguments.length != 1 ||
              arguments[0] is! Codec<List<int>, dynamic>) {
            throw RuntimeError(
                'AsciiCodec.fuse requires another Codec<List<int>, dynamic> as argument.');
          }
          return target.fuse(arguments[0] as Codec<List<int>, dynamic>);
        case 'inverted': // Added from Codec
          return target.inverted;
        default:
          throw RuntimeError(
              'AsciiCodec has no method/getter mapping for "$name"');
      }
    } else {
      throw RuntimeError(
          'Unsupported target for AsciiCodec: ${target?.runtimeType}');
    }
  }
}

class AsciiEncoderConvert implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'AsciiEncoder',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Constructor takes no arguments
          if (arguments.isNotEmpty || namedArguments.isNotEmpty) {
            throw RuntimeError('AsciiEncoder constructor takes no arguments.');
          }
          return AsciiEncoder();
        }, arity: 0, name: 'AsciiEncoder'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is AsciiEncoder) {
      // Extends Converter<String, List<int>>
      switch (name) {
        case 'convert':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'AsciiEncoder.convert requires a String argument.');
          }
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
                'AsciiEncoder.fuse requires another Converter<List<int>, dynamic> as argument.');
          }
          return target.fuse(arguments[0] as Converter<List<int>, dynamic>);
        case 'cast': // Added
          return target.cast<String, List<int>>();
        default:
          throw RuntimeError(
              'AsciiEncoder has no method/getter mapping for "$name"');
      }
    } else {
      throw RuntimeError(
          'Unsupported target for AsciiEncoder: ${target?.runtimeType}');
    }
  }
}

class AsciiDecoderConvert implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'AsciiDecoder',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Constructor: AsciiDecoder({bool allowInvalid = false})
          final allowInvalid =
              namedArguments.get<bool?>('allowInvalid') ?? false;
          return namedArguments.isEmpty
              ? AsciiDecoder
              : AsciiDecoder(allowInvalid: allowInvalid);
        }, arity: 0, name: 'AsciiDecoder'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is AsciiDecoder) {
      // Extends Converter<List<int>, String>
      switch (name) {
        case 'convert':
          if (arguments.length != 1 || arguments[0] is! List) {
            throw RuntimeError('AsciiDecoder.convert requires a Listargument.');
          }
          // allowInvalid is set by constructor, not passed to convert
          return target.convert((arguments[0] as List).cast());
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
                'AsciiDecoder.fuse requires another Converter<String, dynamic> as argument.');
          }
          return target.fuse(arguments[0] as Converter<String, dynamic>);
        case 'cast': // Added
          return target.cast<List<int>, String>();
        default:
          throw RuntimeError(
              'AsciiDecoder has no method/getter mapping for "$name"');
      }
    } else {
      throw RuntimeError(
          'Unsupported target for AsciiDecoder: ${target?.runtimeType}');
    }
  }
}
