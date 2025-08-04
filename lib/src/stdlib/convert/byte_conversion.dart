import 'dart:convert';
import 'package:d4rt/d4rt.dart';

class ByteConversionConvert {
  static BridgedClass get definition => BridgedClass(
        nativeType: ByteConversionSink,
        name: 'ByteConversionSink',
        typeParameterCount: 0,
        staticMethods: {
          'from': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Sink<List<int>>) {
              throw RuntimeError(
                  'ByteConversionSink.from requires one Sink<List<int>> argument.');
            }
            return ByteConversionSink.from(
                positionalArgs[0] as Sink<List<int>>);
          },
          'withCallback': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! InterpretedFunction) {
              throw RuntimeError(
                  'ByteConversionSink.withCallback requires one Function argument.');
            }
            final callback = positionalArgs[0] as InterpretedFunction;
            return ByteConversionSink.withCallback((accumulated) {
              callback.call(visitor, [accumulated]);
            });
          },
        },
        methods: {
          'add': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! List) {
              throw RuntimeError(
                  'ByteConversionSink.add requires one List<int> argument.');
            }
            (target as ByteConversionSink)
                .add((positionalArgs[0] as List).cast());
            return null;
          },
          'addSlice': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 4 ||
                positionalArgs[0] is! List ||
                positionalArgs[1] is! int ||
                positionalArgs[2] is! int ||
                positionalArgs[3] is! bool) {
              throw RuntimeError(
                  'ByteConversionSink.addSlice requires arguments (List, int, int, bool).');
            }
            (target as ByteConversionSink).addSlice(
                (positionalArgs[0] as List).cast(),
                positionalArgs[1] as int,
                positionalArgs[2] as int,
                positionalArgs[3] as bool);
            return null;
          },
          'close': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty || namedArgs.isNotEmpty) {
              throw RuntimeError(
                  'ByteConversionSink.close takes no arguments.');
            }
            (target as ByteConversionSink).close();
            return null;
          },
        },
        getters: {
          'hashCode': (visitor, target) =>
              (target as ByteConversionSink).hashCode,
          'runtimeType': (visitor, target) =>
              (target as ByteConversionSink).runtimeType,
        },
      );
}
