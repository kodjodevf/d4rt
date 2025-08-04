import 'dart:convert';
import 'package:d4rt/d4rt.dart';

class ConverterConvert {
  static BridgedClass get definition => BridgedClass(
        nativeType: Converter,
        name: 'Converter',
        typeParameterCount: 2, // Converter<S, T>
        methods: {
          'convert': (visitor, target, positionalArgs, namedArgs) {
            return (target as Converter).convert(positionalArgs[0]);
          },
          'startChunkedConversion':
              (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! Sink) {
              throw RuntimeError(
                  'startChunkedConversion requires one Sink argument.');
            }
            return (target as Converter)
                .startChunkedConversion(positionalArgs[0] as Sink);
          },
          'bind': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! Stream) {
              throw RuntimeError('bind requires one Stream argument.');
            }
            return (target as Converter).bind(positionalArgs[0] as Stream);
          },
          'fuse': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! Converter) {
              throw RuntimeError(
                  'fuse requires another Converter as argument.');
            }
            return (target as Converter).fuse(positionalArgs[0] as Converter);
          },
          'cast': (visitor, target, positionalArgs, namedArgs) {
            return (target as Converter).cast<dynamic, dynamic>();
          },
        },
        getters: {
          'hashCode': (visitor, target) => (target as Converter).hashCode,
          'runtimeType': (visitor, target) => (target as Converter).runtimeType,
        },
      );
}
