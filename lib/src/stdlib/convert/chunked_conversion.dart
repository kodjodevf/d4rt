import 'dart:convert';
import 'package:d4rt/d4rt.dart';

class ChunkedConversionConvert {
  static BridgedClass get definition => BridgedClass(
        nativeType: ChunkedConversionSink,
        name: 'ChunkedConversionSink',
        typeParameterCount: 1,
        staticMethods: {
          'withCallback': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! InterpretedFunction) {
              throw RuntimeError(
                  'ChunkedConversionSink.withCallback requires an InterpretedFunction callback.');
            }
            final callback = positionalArgs[0] as InterpretedFunction;
            return ChunkedConversionSink<dynamic>.withCallback(
                (List<dynamic> chunks) {
              callback.call(visitor, [chunks]);
            });
          },
        },
        methods: {
          'add': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1) {
              throw RuntimeError(
                  'ChunkedConversionSink.add requires one argument.');
            }
            (target as ChunkedConversionSink).add(positionalArgs[0]);
            return null;
          },
          'close': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty || namedArgs.isNotEmpty) {
              throw RuntimeError(
                  'ChunkedConversionSink.close takes no arguments.');
            }
            (target as ChunkedConversionSink).close();
            return null;
          },
        },
        getters: {},
      );
}
