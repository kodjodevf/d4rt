import 'dart:typed_data';
import 'package:d4rt/d4rt.dart';

class TypedDataBaseTypedData {
  static BridgedClass get definition => BridgedClass(
        nativeType: TypedData,
        name: 'TypedData',
        typeParameterCount: 0,
        isSubtypeOfFunc: (value) => value is TypedData,
        constructors: {},
        methods: {
          'toString': (visitor, target, positionalArgs, namedArgs) =>
              (target as TypedData).toString(),
          '==': (visitor, target, positionalArgs, namedArgs) =>
              (target as TypedData) == positionalArgs[0],
        },
        getters: {
          'buffer': (visitor, target) => (target as TypedData).buffer,
          'lengthInBytes': (visitor, target) =>
              (target as TypedData).lengthInBytes,
          'offsetInBytes': (visitor, target) =>
              (target as TypedData).offsetInBytes,
          'elementSizeInBytes': (visitor, target) =>
              (target as TypedData).elementSizeInBytes,
          'hashCode': (visitor, target) => (target as TypedData).hashCode,
          'runtimeType': (visitor, target) => (target as TypedData).runtimeType,
        },
      );
}
