import 'dart:convert';
import 'package:d4rt/d4rt.dart';

class Latin1CodecConvert {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: Latin1Codec,
        name: 'Latin1Codec',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final allowInvalid = namedArgs.get<bool?>('allowInvalid') ?? false;
            return Latin1Codec(allowInvalid: allowInvalid);
          },
        },
        methods: {
          'encode': (visitor, target, positionalArgs, namedArgs) {
            return (target as Latin1Codec).encode(positionalArgs[0] as String);
          },
          'decode': (visitor, target, positionalArgs, namedArgs) {
            final allowInvalid = namedArgs.get<bool?>('allowInvalid');
            return (target as Latin1Codec).decode(
                positionalArgs[0] as List<int>,
                allowInvalid: allowInvalid);
          },
          'fuse': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Codec<List<int>, dynamic>) {
              throw RuntimeError(
                  'Latin1Codec.fuse requires another Codec<List<int>, dynamic> as argument.');
            }
            return (target as Latin1Codec)
                .fuse(positionalArgs[0] as Codec<List<int>, dynamic>);
          },
        },
        getters: {
          'encoder': (visitor, target) => (target as Latin1Codec).encoder,
          'decoder': (visitor, target) => (target as Latin1Codec).decoder,
          'name': (visitor, target) => (target as Latin1Codec).name,
          'inverted': (visitor, target) => (target as Latin1Codec).inverted,
        },
      );
}

class Latin1EncoderConvert {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: Latin1Encoder,
        name: 'Latin1Encoder',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty || namedArgs.isNotEmpty) {
              throw RuntimeError(
                  'Latin1Encoder constructor takes no arguments.');
            }
            return Latin1Encoder();
          },
        },
        methods: {
          'convert': (visitor, target, positionalArgs, namedArgs) {
            return (target as Latin1Encoder)
                .convert(positionalArgs[0] as String);
          },
          'startChunkedConversion':
              (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Sink<List<int>>) {
              throw RuntimeError(
                  'startChunkedConversion requires a Sink<List<int>> argument.');
            }
            return (target as Latin1Encoder)
                .startChunkedConversion(positionalArgs[0] as Sink<List<int>>);
          },
          'bind': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Stream<String>) {
              throw RuntimeError('bind requires a Stream<String> argument.');
            }
            return (target as Latin1Encoder)
                .bind(positionalArgs[0] as Stream<String>);
          },
          'fuse': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Converter<List<int>, dynamic>) {
              throw RuntimeError(
                  'Latin1Encoder.fuse requires another Converter<List<int>, dynamic> as argument.');
            }
            return (target as Latin1Encoder)
                .fuse(positionalArgs[0] as Converter<List<int>, dynamic>);
          },
          'cast': (visitor, target, positionalArgs, namedArgs) {
            return (target as Latin1Encoder).cast<String, List<int>>();
          },
        },
        getters: {},
      );
}

class Latin1DecoderConvert {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: Latin1Decoder,
        name: 'Latin1Decoder',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final allowInvalid = namedArgs.get<bool?>('allowInvalid') ?? false;
            return Latin1Decoder(allowInvalid: allowInvalid);
          },
        },
        methods: {
          'convert': (visitor, target, positionalArgs, namedArgs) {
            return (target as Latin1Decoder)
                .convert(positionalArgs[0] as List<int>);
          },
          'startChunkedConversion':
              (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Sink<String>) {
              throw RuntimeError(
                  'startChunkedConversion requires a Sink<String> argument.');
            }
            return (target as Latin1Decoder)
                .startChunkedConversion(positionalArgs[0] as Sink<String>);
          },
          'bind': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Stream<List<int>>) {
              throw RuntimeError('bind requires a Stream<List<int>> argument.');
            }
            return (target as Latin1Decoder)
                .bind(positionalArgs[0] as Stream<List<int>>);
          },
          'fuse': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Converter<String, dynamic>) {
              throw RuntimeError(
                  'Latin1Decoder.fuse requires another Converter<String, dynamic> as argument.');
            }
            return (target as Latin1Decoder)
                .fuse(positionalArgs[0] as Converter<String, dynamic>);
          },
          'cast': (visitor, target, positionalArgs, namedArgs) {
            return (target as Latin1Decoder).cast<List<int>, String>();
          },
        },
        getters: {},
      );
}
