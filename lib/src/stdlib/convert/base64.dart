import 'dart:convert';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/bridge/registration.dart';
import 'package:d4rt/src/utils/extensions/list.dart';

class Base64CodecConvert {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: Base64Codec,
        name: 'Base64Codec',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty || namedArgs.isNotEmpty) {
              throw RuntimeError('Base64Codec constructor takes no arguments.');
            }
            return Base64Codec();
          },
          'urlSafe': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty || namedArgs.isNotEmpty) {
              throw RuntimeError(
                  'Base64Codec.urlSafe constructor takes no arguments.');
            }
            return Base64Codec.urlSafe();
          },
        },
        methods: {
          'encode': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! List) {
              throw RuntimeError(
                  'Base64Codec.encode requires a List argument.');
            }
            return (target as Base64Codec)
                .encode((positionalArgs[0] as List).cast());
          },
          'decode': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'Base64Codec.decode requires a String argument.');
            }
            return (target as Base64Codec).decode(positionalArgs[0] as String);
          },
          'normalize': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'Base64Codec.normalize requires a String argument.');
            }
            final start = positionalArgs.get<int>(1) ?? 0;
            final end = positionalArgs.get<int?>(2);
            return (target as Base64Codec)
                .normalize(positionalArgs[0] as String, start, end);
          },
          'fuse': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Codec<String, dynamic>) {
              throw RuntimeError(
                  'Base64Codec.fuse requires another Codec<String, dynamic> as argument.');
            }
            return (target as Base64Codec)
                .fuse(positionalArgs[0] as Codec<String, dynamic>);
          },
        },
        getters: {
          'decoder': (visitor, target) => (target as Base64Codec).decoder,
          'encoder': (visitor, target) => (target as Base64Codec).encoder,
          'inverted': (visitor, target) => (target as Base64Codec).inverted,
          'hashCode': (visitor, target) => (target as Base64Codec).hashCode,
          'runtimeType': (visitor, target) =>
              (target as Base64Codec).runtimeType,
        },
      );
}

class Base64EncoderConvert {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: Base64Encoder,
        name: 'Base64Encoder',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty || namedArgs.isNotEmpty) {
              throw RuntimeError(
                  'Base64Encoder constructor takes no arguments.');
            }
            return Base64Encoder();
          },
          'urlSafe': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty || namedArgs.isNotEmpty) {
              throw RuntimeError(
                  'Base64Encoder.urlSafe factory constructor takes no arguments.');
            }
            return Base64Encoder.urlSafe();
          },
        },
        methods: {
          'convert': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! List) {
              throw RuntimeError(
                  'Base64Encoder.convert requires a List argument.');
            }
            return (target as Base64Encoder)
                .convert((positionalArgs[0] as List).cast());
          },
          'startChunkedConversion':
              (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Sink<dynamic>) {
              throw RuntimeError(
                  'startChunkedConversion requires a Sink<String> argument.');
            }
            return (target as Base64Encoder)
                .startChunkedConversion(positionalArgs[0] as Sink<String>);
          },
          'bind': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Stream<List<int>>) {
              throw RuntimeError('bind requires a Stream<List<int>> argument.');
            }
            return (target as Base64Encoder)
                .bind(positionalArgs[0] as Stream<List<int>>);
          },
          'fuse': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Converter<String, dynamic>) {
              throw RuntimeError(
                  'Base64Encoder.fuse requires another Converter<String, dynamic> as argument.');
            }
            return (target as Base64Encoder)
                .fuse(positionalArgs[0] as Converter<String, dynamic>);
          },
          'cast': (visitor, target, positionalArgs, namedArgs) {
            return (target as Base64Encoder).cast<List<int>, String>();
          },
        },
        getters: {
          'hashCode': (visitor, target) => (target as Base64Encoder).hashCode,
          'runtimeType': (visitor, target) =>
              (target as Base64Encoder).runtimeType,
        },
      );
}

class Base64DecoderConvert {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: Base64Decoder,
        name: 'Base64Decoder',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty || namedArgs.isNotEmpty) {
              throw RuntimeError(
                  'Base64Decoder constructor takes no arguments.');
            }
            return Base64Decoder();
          },
        },
        methods: {
          'convert': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'Base64Decoder.convert requires a String argument.');
            }
            return (target as Base64Decoder)
                .convert(positionalArgs[0] as String);
          },
          'startChunkedConversion':
              (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Sink<List<int>>) {
              throw RuntimeError(
                  'startChunkedConversion requires a Sink<List<int>> argument.');
            }
            return (target as Base64Decoder)
                .startChunkedConversion(positionalArgs[0] as Sink<List<int>>);
          },
          'bind': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Stream<String>) {
              throw RuntimeError('bind requires a Stream<String> argument.');
            }
            return (target as Base64Decoder)
                .bind(positionalArgs[0] as Stream<String>);
          },
          'fuse': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Converter<List<int>, dynamic>) {
              throw RuntimeError(
                  'Base64Decoder.fuse requires another Converter<List<int>, dynamic> as argument.');
            }
            return (target as Base64Decoder)
                .fuse(positionalArgs[0] as Converter<List<int>, dynamic>);
          },
          'cast': (visitor, target, positionalArgs, namedArgs) {
            return (target as Base64Decoder).cast<String, List<int>>();
          },
        },
        getters: {
          'hashCode': (visitor, target) => (target as Base64Decoder).hashCode,
          'runtimeType': (visitor, target) =>
              (target as Base64Decoder).runtimeType,
        },
      );
}
