import 'dart:convert';
import 'package:d4rt/d4rt.dart';

class CodecConvert {
  static BridgedClass get definition => BridgedClass(
        nativeType: Codec,
        name: 'Codec',
        typeParameterCount: 2, // Codec<S, T>
        nativeNames: ['_FusedCodec'],
        methods: {
          'encode': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1) {
              throw RuntimeError('Codec.encode requires one argument.');
            }
            return (target as Codec).encode(positionalArgs[0]);
          },
          'decode': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1) {
              throw RuntimeError('Codec.decode requires one argument.');
            }
            return (target as Codec).decode(positionalArgs[0]);
          },
          'fuse': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! Codec) {
              throw RuntimeError(
                  'Codec.fuse requires another Codec as argument.');
            }
            return (target as Codec).fuse(positionalArgs[0] as Codec);
          },
        },
        getters: {
          'inverted': (visitor, target) => (target as Codec).inverted,
          'decoder': (visitor, target) => (target as Codec).decoder,
          'encoder': (visitor, target) => (target as Codec).encoder,
          'hashCode': (visitor, target) => (target as Codec).hashCode,
          'runtimeType': (visitor, target) => (target as Codec).runtimeType,
        },
      );
}
