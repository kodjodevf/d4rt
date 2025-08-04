import 'dart:convert';

import 'package:d4rt/d4rt.dart';

class EncodingConvert {
  static BridgedClass get definition => BridgedClass(
        nativeType: Encoding,
        name: 'Encoding',
        typeParameterCount: 0,
        staticMethods: {
          'getByName': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'Encoding.getByName requires one String argument (name).');
            }
            return Encoding.getByName(positionalArgs[0] as String);
          },
        },
        methods: {
          'encode': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'Encoding.encode requires one String argument.');
            }
            return (target as Encoding).encode(positionalArgs[0] as String);
          },
          'decode': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! List) {
              throw RuntimeError(
                  'Encoding.decode requires one List<int> argument.');
            }
            return (target as Encoding)
                .decode((positionalArgs[0] as List).cast());
          },
          'inverted': (visitor, target, positionalArgs, namedArgs) {
            return (target as Encoding).inverted;
          },
          'fuse': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Codec<List<int>, dynamic>) {
              throw RuntimeError(
                  'Encoding.fuse requires another Codec<List<int>, dynamic> as argument.');
            }
            return (target as Encoding)
                .fuse(positionalArgs[0] as Codec<List<int>, dynamic>);
          },
        },
        getters: {
          'name': (visitor, target) {
            return (target as Encoding).name;
          },
          'decoder': (visitor, target) {
            return (target as Encoding).decoder;
          },
          'encoder': (visitor, target) {
            return (target as Encoding).encoder;
          },
          'hashCode': (visitor, target) {
            return (target as Encoding).hashCode;
          },
          'runtimeType': (visitor, target) {
            return (target as Encoding).runtimeType;
          },
        },
      );
}
