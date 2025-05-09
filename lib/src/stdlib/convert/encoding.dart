import 'dart:convert';

import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';

class EncodingConvert implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Define the abstract type name
    environment.define(
        'Encoding',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return Encoding;
        }, arity: 0, name: 'Encoding'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    // Target must be an instance of a class implementing Encoding (like Utf8Codec)
    if (target is Encoding) {
      switch (name) {
        case 'encode':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError('Encoding.encode requires one String argument.');
          }
          return target.encode(arguments[0] as String);
        case 'decode':
          if (arguments.length != 1 || arguments[0] is! List) {
            throw RuntimeError(
                'Encoding.decode requires one List<int> argument.');
          }
          return target.decode((arguments[0] as List).cast());
        case 'name': // Getter
          return target.name;
        case 'decoder': // Getter
          return target.decoder;
        case 'encoder': // Getter
          return target.encoder;
        // Methods from Codec
        case 'inverted':
          return target.inverted;
        case 'fuse':
          // Encoding fuses with Codec<List<int>, TT>
          if (arguments.length != 1 ||
              arguments[0] is! Codec<List<int>, dynamic>) {
            throw RuntimeError(
                'Encoding.fuse requires another Codec<List<int>, dynamic> as argument.');
          }
          return target.fuse(arguments[0] as Codec<List<int>, dynamic>);
        default:
          throw RuntimeError('Encoding has no method mapping for "$name"');
      }
    } else {
      switch (name) {
        case 'getByName':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'Encoding.getByName requires one String argument (name).');
          }
          return Encoding.getByName(arguments[0] as String);

        default:
          throw RuntimeError('Encoding has no method mapping for "$name"');
      }
    }
  }
}
