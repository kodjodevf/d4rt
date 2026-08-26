import 'dart:typed_data';
import 'package:d4rt/d4rt.dart';

class BytesBuilderTypedData {
  static BridgedClass get definition => BridgedClass(
        name: 'BytesBuilder',
        nativeType: BytesBuilder,
        typeParameterCount: 0,
        isSubtypeOfFunc: (value) => value is BytesBuilder,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final copy = namedArgs['copy'] as bool? ?? true;
            return BytesBuilder(copy: copy);
          },
        },
        methods: {
          'add': (visitor, target, positionalArgs, namedArgs) {
            if (target is BytesBuilder &&
                positionalArgs.length == 1 &&
                positionalArgs[0] is List) {
              final list = (positionalArgs[0] as List).toNativeList().cast<int>();
              target.add(list);
              return null;
            }
            throw RuntimeError("BytesBuilder.add expects a List<int> argument.");
          },
          'addByte': (visitor, target, positionalArgs, namedArgs) {
            if (target is BytesBuilder &&
                positionalArgs.length == 1 &&
                positionalArgs[0] is int) {
              target.addByte(positionalArgs[0] as int);
              return null;
            }
            throw RuntimeError("BytesBuilder.addByte expects an int argument.");
          },
          'takeBytes': (visitor, target, positionalArgs, namedArgs) {
            if (target is BytesBuilder) {
              return target.takeBytes();
            }
            throw RuntimeError("Target is not a BytesBuilder for takeBytes.");
          },
          'toBytes': (visitor, target, positionalArgs, namedArgs) {
            if (target is BytesBuilder) {
              return target.toBytes();
            }
            throw RuntimeError("Target is not a BytesBuilder for toBytes.");
          },
          'clear': (visitor, target, positionalArgs, namedArgs) {
            if (target is BytesBuilder) {
              target.clear();
              return null;
            }
            throw RuntimeError("Target is not a BytesBuilder for clear.");
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as BytesBuilder).toString();
          },
        },
        getters: {
          'length': (visitor, target) {
            if (target is BytesBuilder) {
              return target.length;
            }
            throw RuntimeError("Target is not a BytesBuilder for getter 'length'.");
          },
          'isEmpty': (visitor, target) {
            if (target is BytesBuilder) {
              return target.isEmpty;
            }
            throw RuntimeError("Target is not a BytesBuilder for getter 'isEmpty'.");
          },
          'isNotEmpty': (visitor, target) {
            if (target is BytesBuilder) {
              return target.isNotEmpty;
            }
            throw RuntimeError("Target is not a BytesBuilder for getter 'isNotEmpty'.");
          },
          'hashCode': (visitor, target) => (target as BytesBuilder).hashCode,
          'runtimeType': (visitor, target) =>
              (target as BytesBuilder).runtimeType,
        },
      );
}
