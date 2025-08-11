import 'dart:io';
import 'dart:convert';
import 'package:d4rt/d4rt.dart';

/// Bridged implementation of dart:io IOSink
class IOSinkIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: IOSink,
        name: 'IOSink',
        typeParameterCount: 0,
        nativeNames: ['_StdSink'],
        methods: {
          'add': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw ArgumentError('IOSink.add requires data');
            }
            (target as IOSink).add(positionalArgs[0] as List<int>);
            return null;
          },
          'addError': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw ArgumentError('IOSink.addError requires error');
            }
            final stackTrace = positionalArgs.length > 1
                ? positionalArgs[1] as StackTrace?
                : null;
            (target as IOSink).addError(positionalArgs[0]!, stackTrace);
            return null;
          },
          'addStream': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw ArgumentError('IOSink.addStream requires stream');
            }
            return (target as IOSink)
                .addStream(positionalArgs[0] as Stream<List<int>>);
          },
          'write': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw ArgumentError('IOSink.write requires object');
            }
            (target as IOSink).write(positionalArgs[0]);
            return null;
          },
          'writeln': (visitor, target, positionalArgs, namedArgs) {
            final obj = positionalArgs.isNotEmpty ? positionalArgs[0] : '';
            (target as IOSink).writeln(obj);
            return null;
          },
          'writeAll': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw ArgumentError('IOSink.writeAll requires objects');
            }
            final objects = positionalArgs[0] as Iterable;
            final separator =
                positionalArgs.length > 1 ? positionalArgs[1].toString() : '';
            (target as IOSink).writeAll(objects, separator);
            return null;
          },
          'writeCharCode': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw ArgumentError('IOSink.writeCharCode requires charCode');
            }
            (target as IOSink).writeCharCode(positionalArgs[0] as int);
            return null;
          },
          'flush': (visitor, target, positionalArgs, namedArgs) {
            return (target as IOSink).flush();
          },
          'close': (visitor, target, positionalArgs, namedArgs) {
            return (target as IOSink).close();
          },
        },
        getters: {
          'encoding': (visitor, target) => (target as IOSink).encoding,
          'done': (visitor, target) => (target as IOSink).done,
          'hashCode': (visitor, target) => (target as IOSink).hashCode,
          'toString': (visitor, target) => (target as IOSink).toString(),
          'runtimeType': (visitor, target) => (target as IOSink).runtimeType,
        },
        setters: {
          'encoding': (visitor, target, value) {
            (target as IOSink).encoding = value as Encoding;
          },
        },
      );
}
