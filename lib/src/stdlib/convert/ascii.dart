import 'dart:convert';
import 'package:d4rt/d4rt.dart';

class AsciiCodecConvert {
  static BridgedClass get definition => BridgedClass(
        nativeType: AsciiCodec,
        name: 'AsciiCodec',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final allowInvalid = namedArgs['allowInvalid'] as bool? ?? false;
            return AsciiCodec(allowInvalid: allowInvalid);
          },
        },
        methods: {
          'encode': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'AsciiCodec.encode requires a String argument.');
            }
            return (target as AsciiCodec).encode(positionalArgs[0] as String);
          },
          'decode': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! List) {
              throw RuntimeError('AsciiCodec.decode requires a List argument.');
            }
            final allowInvalid = namedArgs['allowInvalid'] as bool?;
            return (target as AsciiCodec).decode(
                (positionalArgs[0] as List).cast(),
                allowInvalid: allowInvalid);
          },
          'fuse': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Codec<List<int>, dynamic>) {
              throw RuntimeError(
                  'AsciiCodec.fuse requires another Codec<List<int>, dynamic> as argument.');
            }
            return (target as AsciiCodec)
                .fuse(positionalArgs[0] as Codec<List<int>, dynamic>);
          },
        },
        getters: {
          'name': (visitor, target) => (target as AsciiCodec).name,
          'encoder': (visitor, target) => (target as AsciiCodec).encoder,
          'decoder': (visitor, target) => (target as AsciiCodec).decoder,
          'inverted': (visitor, target) => (target as AsciiCodec).inverted,
          'hashCode': (visitor, target) => (target as AsciiCodec).hashCode,
          'runtimeType': (visitor, target) =>
              (target as AsciiCodec).runtimeType,
        },
      );
}

class AsciiEncoderConvert {
  static BridgedClass get definition => BridgedClass(
        nativeType: AsciiEncoder,
        name: 'AsciiEncoder',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty || namedArgs.isNotEmpty) {
              throw RuntimeError(
                  'AsciiEncoder constructor takes no arguments.');
            }
            return AsciiEncoder();
          },
        },
        methods: {
          'convert': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'AsciiEncoder.convert requires a String argument.');
            }
            return (target as AsciiEncoder)
                .convert(positionalArgs[0] as String);
          },
          'startChunkedConversion':
              (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Sink<List<int>>) {
              throw RuntimeError(
                  'startChunkedConversion requires a Sink<List<int>> argument.');
            }
            return (target as AsciiEncoder)
                .startChunkedConversion(positionalArgs[0] as Sink<List<int>>);
          },
          'bind': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Stream<String>) {
              throw RuntimeError('bind requires a Stream<String> argument.');
            }
            return (target as AsciiEncoder)
                .bind(positionalArgs[0] as Stream<String>);
          },
          'fuse': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Converter<List<int>, dynamic>) {
              throw RuntimeError(
                  'AsciiEncoder.fuse requires another Converter<List<int>, dynamic> as argument.');
            }
            return (target as AsciiEncoder)
                .fuse(positionalArgs[0] as Converter<List<int>, dynamic>);
          },
          'cast': (visitor, target, positionalArgs, namedArgs) {
            return (target as AsciiEncoder).cast<String, List<int>>();
          },
        },
        getters: {
          'hashCode': (visitor, target) => (target as AsciiEncoder).hashCode,
          'runtimeType': (visitor, target) =>
              (target as AsciiEncoder).runtimeType,
        },
      );
}

class AsciiDecoderConvert {
  static BridgedClass get definition => BridgedClass(
        nativeType: AsciiDecoder,
        name: 'AsciiDecoder',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final allowInvalid = namedArgs['allowInvalid'] as bool? ?? false;
            return namedArgs.isEmpty
                ? AsciiDecoder()
                : AsciiDecoder(allowInvalid: allowInvalid);
          },
        },
        methods: {
          'convert': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! List) {
              throw RuntimeError(
                  'AsciiDecoder.convert requires a List argument.');
            }
            return (target as AsciiDecoder)
                .convert((positionalArgs[0] as List).cast());
          },
          'startChunkedConversion':
              (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Sink<String>) {
              throw RuntimeError(
                  'startChunkedConversion requires a Sink<String> argument.');
            }
            return (target as AsciiDecoder)
                .startChunkedConversion(positionalArgs[0] as Sink<String>);
          },
          'bind': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Stream<List<int>>) {
              throw RuntimeError('bind requires a Stream<List<int>> argument.');
            }
            return (target as AsciiDecoder)
                .bind(positionalArgs[0] as Stream<List<int>>);
          },
          'fuse': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Converter<String, dynamic>) {
              throw RuntimeError(
                  'AsciiDecoder.fuse requires another Converter<String, dynamic> as argument.');
            }
            return (target as AsciiDecoder)
                .fuse(positionalArgs[0] as Converter<String, dynamic>);
          },
          'cast': (visitor, target, positionalArgs, namedArgs) {
            return (target as AsciiDecoder).cast<List<int>, String>();
          },
        },
        getters: {
          'hashCode': (visitor, target) => (target as AsciiDecoder).hashCode,
          'runtimeType': (visitor, target) =>
              (target as AsciiDecoder).runtimeType,
        },
      );
}
