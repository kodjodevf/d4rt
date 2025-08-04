import 'dart:convert';
import 'package:d4rt/d4rt.dart';

class JsonCodecConvert {
  static BridgedClass get definition => BridgedClass(
        nativeType: JsonCodec,
        name: 'JsonCodec',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final reviverArg = namedArgs['reviver'] as InterpretedFunction?;
            final toEncodableArg =
                namedArgs['toEncodable'] as InterpretedFunction?;

            return JsonCodec(
              reviver: reviverArg == null
                  ? null
                  : (key, value) => reviverArg.call(visitor, [key, value]),
              toEncodable: toEncodableArg == null
                  ? null
                  : (object) => toEncodableArg.call(visitor, [object]),
            );
          },
        },
        methods: {
          'encode': (visitor, target, positionalArgs, namedArgs) {
            return (target as JsonCodec).encode(positionalArgs[0]);
          },
          'decode': (visitor, target, positionalArgs, namedArgs) {
            final source = positionalArgs[0] as String;
            final reviverArg = namedArgs['reviver'] as InterpretedFunction? ??
                (positionalArgs.length > 1
                    ? positionalArgs[1] as InterpretedFunction?
                    : null);
            return (target as JsonCodec).decode(
              source,
              reviver: reviverArg == null
                  ? null
                  : (key, value) => reviverArg.call(visitor, [key, value]),
            );
          },
          'fuse': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Codec<String, dynamic>) {
              throw RuntimeError(
                  'JsonCodec.fuse requires another Codec<String, dynamic> as argument.');
            }
            return (target as JsonCodec)
                .fuse(positionalArgs[0] as Codec<String, dynamic>);
          },
        },
        getters: {
          'encoder': (visitor, target) => (target as JsonCodec).encoder,
          'decoder': (visitor, target) => (target as JsonCodec).decoder,
          'inverted': (visitor, target) => (target as JsonCodec).inverted,
        },
      );
}

class JsonEncoderConvert {
  static BridgedClass get definition => BridgedClass(
        nativeType: JsonEncoder,
        name: 'JsonEncoder',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final toEncodableArg = positionalArgs.isNotEmpty
                ? positionalArgs[0] as InterpretedFunction?
                : null;
            return JsonEncoder(
              toEncodableArg == null
                  ? null
                  : (object) => toEncodableArg.call(visitor, [object]),
            );
          },
        },
        methods: {
          'convert': (visitor, target, positionalArgs, namedArgs) {
            return (target as JsonEncoder).convert(positionalArgs[0]);
          },
          'fuse': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Converter<String, dynamic>) {
              throw RuntimeError(
                  'JsonEncoder.fuse requires another Converter<String, dynamic> as argument.');
            }
            return (target as JsonEncoder)
                .fuse(positionalArgs[0] as Converter<String, dynamic>);
          },
          'startChunkedConversion':
              (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Sink<String>) {
              throw RuntimeError(
                  'startChunkedConversion requires a Sink<String> argument.');
            }
            return (target as JsonEncoder)
                .startChunkedConversion(positionalArgs[0] as Sink<String>);
          },
          'bind': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Stream<dynamic>) {
              throw RuntimeError('bind requires a Stream<dynamic> argument.');
            }
            return (target as JsonEncoder)
                .bind(positionalArgs[0] as Stream<dynamic>);
          },
          'cast': (visitor, target, positionalArgs, namedArgs) {
            return (target as JsonEncoder).cast<dynamic, String>();
          },
        },
        getters: {},
      );
}

class JsonDecoderConvert {
  static BridgedClass get definition => BridgedClass(
        nativeType: JsonDecoder,
        name: 'JsonDecoder',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final reviverArg = positionalArgs.isNotEmpty
                ? positionalArgs[0] as InterpretedFunction?
                : null;
            return JsonDecoder(
              reviverArg == null
                  ? null
                  : (key, value) => reviverArg.call(visitor, [key, value]),
            );
          },
        },
        methods: {
          'convert': (visitor, target, positionalArgs, namedArgs) {
            final source = positionalArgs[0] as String;
            return (target as JsonDecoder).convert(source);
          },
          'fuse': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Converter<dynamic, dynamic>) {
              throw RuntimeError(
                  'JsonDecoder.fuse requires another Converter<dynamic, dynamic> as argument.');
            }
            return (target as JsonDecoder)
                .fuse(positionalArgs[0] as Converter<dynamic, dynamic>);
          },
          'startChunkedConversion':
              (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Sink<dynamic>) {
              throw RuntimeError(
                  'startChunkedConversion requires a Sink<dynamic> argument.');
            }
            return (target as JsonDecoder)
                .startChunkedConversion(positionalArgs[0] as Sink<dynamic>);
          },
          'bind': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Stream<String>) {
              throw RuntimeError('bind requires a Stream<String> argument.');
            }
            return (target as JsonDecoder)
                .bind(positionalArgs[0] as Stream<String>);
          },
          'cast': (visitor, target, positionalArgs, namedArgs) {
            return (target as JsonDecoder).cast<String, dynamic>();
          },
        },
        getters: {},
      );
}
