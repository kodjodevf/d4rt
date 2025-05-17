import 'dart:typed_data';

import 'package:d4rt/src/bridge/registration.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/interpreter_visitor.dart';

void registerEndian(Environment environment) {
  final endianDefinition = BridgedClassDefinition(
    name: 'Endian',
    nativeType: Endian,
    constructors: {},
    staticGetters: {
      'big': (InterpreterVisitor visitor) => Endian.big,
      'little': (InterpreterVisitor visitor) => Endian.little,
      'host': (InterpreterVisitor visitor) => Endian.host,
    },
    staticMethods: {},
    methods: {},
    getters: {},
    setters: {},
  );

  environment.defineBridge(endianDefinition);
}
