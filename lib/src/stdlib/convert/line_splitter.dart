import 'dart:convert';
import 'package:d4rt/d4rt.dart';

class LineSplitterConvert {
  static BridgedClass get definition => BridgedClass(
        nativeType: LineSplitter,
        name: 'LineSplitter',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            return LineSplitter();
          },
        },
        methods: {
          'convert': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'LineSplitter.convert requires one String argument.');
            }
            return (target as LineSplitter)
                .convert(positionalArgs[0] as String);
          },
          'startChunkedConversion':
              (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Sink<String>) {
              throw RuntimeError(
                  'startChunkedConversion requires a Sink<String> argument.');
            }
            return (target as LineSplitter)
                .startChunkedConversion(positionalArgs[0] as Sink<String>);
          },
          'bind': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Stream<String>) {
              throw RuntimeError('bind requires a Stream<String> argument.');
            }
            return (target as LineSplitter)
                .bind(positionalArgs[0] as Stream<String>);
          },
          'cast': (visitor, target, positionalArgs, namedArgs) {
            return (target as LineSplitter).cast<String, List<String>>();
          },
        },
        getters: {
          'hashCode': (visitor, target) => (target as LineSplitter).hashCode,
          'runtimeType': (visitor, target) =>
              (target as LineSplitter).runtimeType,
        },
      );
}
