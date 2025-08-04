import 'dart:typed_data';
import 'package:d4rt/d4rt.dart';

class EndianTypedData {
  static BridgedClass get definition => BridgedClass(
        name: 'Endian',
        nativeType: Endian,
        typeParameterCount: 0,
        constructors: {},
        staticGetters: {
          'big': (InterpreterVisitor visitor) => Endian.big,
          'little': (InterpreterVisitor visitor) => Endian.little,
          'host': (InterpreterVisitor visitor) => Endian.host,
        },
        methods: {
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as Endian).toString();
          },
          '==': (visitor, target, positionalArgs, namedArgs) {
            return (target as Endian) == positionalArgs[0];
          },
        },
        getters: {
          'hashCode': (visitor, target) {
            return (target as Endian).hashCode;
          },
          'runtimeType': (visitor, target) {
            return (target as Endian).runtimeType;
          },
        },
      );
}
