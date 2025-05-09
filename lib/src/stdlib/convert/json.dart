import 'dart:convert';
import 'dart:async';

import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart';
import 'package:d4rt/src/utils/extensions/map.dart';

class JsonCodecConvert implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Define the global instance
    environment.define('json', json);
    // Define the types/constructors
    environment.define(
        'JsonCodec',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          final reviverArg =
              namedArguments.get<InterpretedFunction?>('reviver');
          final toEncodableArg =
              namedArguments.get<InterpretedFunction?>('toEncodable');

          return JsonCodec(
            reviver: reviverArg == null
                ? null
                : (key, value) => reviverArg.call(visitor, [key, value]),
            toEncodable: toEncodableArg == null
                ? null
                : (object) => toEncodableArg.call(visitor, [object]),
          );
        }, arity: 0, name: 'JsonCodec'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is JsonCodec) {
      switch (name) {
        case 'encode':
          return target.encode(arguments[0]);
        case 'decode':
          // Decode in Dart takes named arguments, but we might map from positional
          final source = arguments[0] as String;
          final reviverArg =
              namedArguments.get<InterpretedFunction?>('reviver') ??
                  (arguments.length > 1
                      ? arguments.get<InterpretedFunction?>(1)
                      : null);
          return target.decode(
            source,
            reviver: reviverArg == null
                ? null
                : (key, value) => reviverArg.call(visitor, [key, value]),
          );
        case 'encoder': // Getter
          return target.encoder;
        case 'decoder': // Getter
          return target.decoder;
        case 'inverted':
          return target.inverted;
        case 'fuse':
          if (arguments.length != 1 ||
              arguments[0] is! Codec<String, dynamic>) {
            throw RuntimeError(
                'JsonCodec.fuse requires another Codec<String, dynamic> as argument.');
          }
          return target.fuse(arguments[0] as Codec<String, dynamic>);
        default:
          throw RuntimeError('JsonCodec has no method mapping for "$name"');
      }
    } else {
      throw RuntimeError(
          'Unsupported target for JsonConvert: ${target?.runtimeType}');
    }
  }
}

class JsonEncoderConvert implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'JsonEncoder',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Constructor: JsonEncoder([Object? Function(dynamic object)? toEncodable])
          final toEncodableArg = arguments.isNotEmpty
              ? arguments.get<InterpretedFunction?>(0)
              : null;
          if (namedArguments.isNotEmpty) {
            throw RuntimeError(
                'Standard JsonEncoder constructor does not take named arguments.');
          }
          return JsonEncoder(
            toEncodableArg == null
                ? null
                : (object) => toEncodableArg.call(visitor, [object]),
          );
        },
            arity: 1,
            name: 'JsonEncoder') // Arity 1 for the optional positional argument
        );
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is JsonEncoder) {
      switch (name) {
        case 'convert':
          final object = arguments[0];
          return target.convert(object);
        case 'fuse':
          if (arguments.length != 1 ||
              arguments[0] is! Converter<String, dynamic>) {
            throw RuntimeError(
                'JsonEncoder.fuse requires another Converter<String, dynamic> as argument.');
          }
          return target.fuse(arguments[0] as Converter<String, dynamic>);
        case 'startChunkedConversion':
          if (arguments.length != 1 || arguments[0] is! Sink<String>) {
            throw RuntimeError(
                'startChunkedConversion requires a Sink<String> argument.');
          }
          return target.startChunkedConversion(arguments[0] as Sink<String>);
        case 'bind':
          if (arguments.length != 1 || arguments[0] is! Stream<dynamic>) {
            // Input is dynamic for convert
            throw RuntimeError('bind requires a Stream<dynamic> argument.');
          }
          return target.bind(arguments[0] as Stream<dynamic>);
        case 'cast':
          return target.cast<dynamic, String>();
        default:
          throw RuntimeError('JsonEncoder has no method mapping for "$name"');
      }
    } else {
      throw RuntimeError(
          'Unsupported target for JsonEncoder: ${target?.runtimeType}');
    }
  }
}

class JsonDecoderConvert implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'JsonDecoder',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Constructor: JsonDecoder([Object? Function(Object? key, Object? value)? reviver])
          final reviverArg = arguments.isNotEmpty
              ? arguments.get<InterpretedFunction?>(0)
              : null;
          if (namedArguments.isNotEmpty) {
            throw RuntimeError(
                'JsonDecoder constructor does not take named arguments.');
          }
          return JsonDecoder(
            reviverArg == null
                ? null
                : (key, value) => reviverArg.call(visitor, [key, value]),
          );
        },
            arity: 1,
            name: 'JsonDecoder') // Arity 1 for the optional positional argument
        );

    // Define top-level functions
    environment.define(
        'jsonEncode',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          if (arguments.length != 1) {
            throw RuntimeError(
                'jsonEncode requires one positional argument (object).');
          }
          final toEncodableArg =
              namedArguments.get<InterpretedFunction?>('toEncodable');
          return jsonEncode(
            arguments.get<Object?>(0),
            toEncodable: toEncodableArg == null
                ? null
                : (object) => toEncodableArg.call(visitor, [object]),
          );
        }, arity: 1, name: 'jsonEncode'));

    environment.define(
        'jsonDecode',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // jsonDecode(String source, {Object? Function(Object? key, Object? value)? reviver})
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'jsonDecode requires one positional argument (String source).');
          }
          final reviverArg =
              namedArguments.get<InterpretedFunction?>('reviver');
          return jsonDecode(
            arguments[0] as String,
            reviver: reviverArg == null
                ? null
                : (key, value) => reviverArg.call(visitor, [key, value]),
          );
        }, arity: 1, name: 'jsonDecode'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is JsonDecoder) {
      switch (name) {
        case 'convert':
          final source = arguments[0] as String;
          return target.convert(source);
        case 'fuse':
          if (arguments.length != 1 ||
              arguments[0] is! Converter<dynamic, dynamic>) {
            // Output is dynamic
            throw RuntimeError(
                'JsonDecoder.fuse requires another Converter<dynamic, dynamic> as argument.');
          }
          return target.fuse(arguments[0] as Converter<dynamic, dynamic>);
        case 'startChunkedConversion':
          if (arguments.length != 1 || arguments[0] is! Sink<dynamic>) {
            // Output is dynamic
            throw RuntimeError(
                'startChunkedConversion requires a Sink<dynamic> argument.');
          }
          return target.startChunkedConversion(arguments[0] as Sink<dynamic>);
        case 'bind':
          if (arguments.length != 1 || arguments[0] is! Stream<String>) {
            throw RuntimeError('bind requires a Stream<String> argument.');
          }
          return target.bind(arguments[0] as Stream<String>);
        case 'cast':
          return target.cast<String, dynamic>();
        default:
          throw RuntimeError('JsonDecoder has no method mapping for "$name"');
      }
    } else {
      throw RuntimeError(
          'Unsupported target for JsonDecoder: ${target?.runtimeType}');
    }
  }
}
