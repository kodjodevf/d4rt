import 'dart:convert';
import 'package:d4rt/d4rt.dart';

Object? Function(Object? nonEncodable)? wrapJsonToEncodable(
    InterpreterVisitor visitor, Object? toEncodableArg) {
  if (toEncodableArg is InterpretedFunction) {
    return (object) => toEncodableArg.call(visitor, [object]);
  } else if (toEncodableArg is Callable) {
    return (object) => toEncodableArg.call(visitor, [object], {});
  } else if (toEncodableArg is Function) {
    return (object) => (toEncodableArg as dynamic)(object);
  }
  // Automatic fallback for InterpretedInstance defining toJson()
  return (object) {
    if (object is InterpretedInstance) {
      final toJsonMethod = object.klass.methods['toJson'];
      if (toJsonMethod != null) {
        try {
          return toJsonMethod.bind(object).call(visitor, [], {});
        } on ReturnException catch (e) {
          return e.value;
        }
      }
    }
    throw JsonUnsupportedObjectError(object);
  };
}

Object? Function(Object? key, Object? value)? wrapJsonReviver(
    InterpreterVisitor visitor, Object? reviverArg) {
  if (reviverArg is InterpretedFunction) {
    return (key, value) => reviverArg.call(visitor, [key, value]);
  } else if (reviverArg is Callable) {
    return (key, value) => reviverArg.call(visitor, [key, value], {});
  } else if (reviverArg is Function) {
    return (key, value) => (reviverArg as dynamic)(key, value);
  }
  return null;
}

class JsonCodecConvert {
  static BridgedClass get definition => BridgedClass(
        nativeType: JsonCodec,
        name: 'JsonCodec',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final reviverArg = namedArgs['reviver'] ??
                (positionalArgs.isNotEmpty ? positionalArgs[0] : null);
            final toEncodableArg = namedArgs['toEncodable'] ??
                (positionalArgs.length > 1 ? positionalArgs[1] : null);

            return JsonCodec(
              reviver: wrapJsonReviver(visitor, reviverArg),
              toEncodable: wrapJsonToEncodable(visitor, toEncodableArg),
            );
          },
        },
        methods: {
          'encode': (visitor, target, positionalArgs, namedArgs) {
            final toEncodableArg = namedArgs['toEncodable'] ??
                (positionalArgs.length > 1 ? positionalArgs[1] : null);
            if (toEncodableArg != null) {
              return (target as JsonCodec).encode(
                positionalArgs[0],
                toEncodable: wrapJsonToEncodable(visitor, toEncodableArg),
              );
            }
            return (target as JsonCodec).encode(positionalArgs[0]);
          },
          'decode': (visitor, target, positionalArgs, namedArgs) {
            final source = positionalArgs[0] as String;
            final reviverArg = namedArgs['reviver'] ??
                (positionalArgs.length > 1 ? positionalArgs[1] : null);
            return (target as JsonCodec).decode(
              source,
              reviver: wrapJsonReviver(visitor, reviverArg),
            );
          },
          'fuse': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Codec<String, dynamic>) {
              throw RuntimeError(
                  'JsonCodec.fuse requires another Codec<String, dynamic> as argument.');
            }
            return (target as JsonCodec)
                .fuse(positionalArgs[0] as Codec<String, dynamic>);
          },
        },
        getters: {
          'encoder': (visitor, target) => (target as JsonCodec).encoder,
          'decoder': (visitor, target) => (target as JsonCodec).decoder,
          'inverted': (visitor, target) => (target as JsonCodec).inverted,
        },
      );
}

class JsonEncoderConvert {
  static BridgedClass get definition => BridgedClass(
        nativeType: JsonEncoder,
        name: 'JsonEncoder',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final toEncodableArg = positionalArgs.isNotEmpty
                ? positionalArgs[0]
                : namedArgs['toEncodable'];
            return JsonEncoder(
              wrapJsonToEncodable(visitor, toEncodableArg),
            );
          },
          'withIndent': (visitor, positionalArgs, namedArgs) {
            final indent = positionalArgs.isNotEmpty
                ? positionalArgs[0] as String?
                : namedArgs['indent'] as String?;
            final toEncodableArg = namedArgs['toEncodable'] ??
                (positionalArgs.length > 1 ? positionalArgs[1] : null);
            return JsonEncoder.withIndent(
              indent,
              wrapJsonToEncodable(visitor, toEncodableArg),
            );
          },
        },
        methods: {
          'convert': (visitor, target, positionalArgs, namedArgs) {
            return (target as JsonEncoder).convert(positionalArgs[0]);
          },
          'fuse': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Converter<String, dynamic>) {
              throw RuntimeError(
                  'JsonEncoder.fuse requires another Converter<String, dynamic> as argument.');
            }
            return (target as JsonEncoder)
                .fuse(positionalArgs[0] as Converter<String, dynamic>);
          },
          'startChunkedConversion':
              (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Sink<String>) {
              throw RuntimeError(
                  'startChunkedConversion requires a Sink<String> argument.');
            }
            return (target as JsonEncoder)
                .startChunkedConversion(positionalArgs[0] as Sink<String>);
          },
          'bind': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Stream<dynamic>) {
              throw RuntimeError('bind requires a Stream<dynamic> argument.');
            }
            return (target as JsonEncoder)
                .bind(positionalArgs[0] as Stream<dynamic>);
          },
          'cast': (visitor, target, positionalArgs, namedArgs) {
            return (target as JsonEncoder).cast<dynamic, String>();
          },
        },
        getters: {},
      );
}

class JsonDecoderConvert {
  static BridgedClass get definition => BridgedClass(
        nativeType: JsonDecoder,
        name: 'JsonDecoder',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final reviverArg = positionalArgs.isNotEmpty
                ? positionalArgs[0]
                : namedArgs['reviver'];
            return JsonDecoder(
              wrapJsonReviver(visitor, reviverArg),
            );
          },
        },
        methods: {
          'convert': (visitor, target, positionalArgs, namedArgs) {
            final source = positionalArgs[0] as String;
            return (target as JsonDecoder).convert(source);
          },
          'fuse': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Converter<dynamic, dynamic>) {
              throw RuntimeError(
                  'JsonDecoder.fuse requires another Converter<dynamic, dynamic> as argument.');
            }
            return (target as JsonDecoder)
                .fuse(positionalArgs[0] as Converter<dynamic, dynamic>);
          },
          'startChunkedConversion':
              (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Sink<dynamic>) {
              throw RuntimeError(
                  'startChunkedConversion requires a Sink<dynamic> argument.');
            }
            return (target as JsonDecoder)
                .startChunkedConversion(positionalArgs[0] as Sink<dynamic>);
          },
          'bind': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Stream<String>) {
              throw RuntimeError('bind requires a Stream<String> argument.');
            }
            return (target as JsonDecoder)
                .bind(positionalArgs[0] as Stream<String>);
          },
          'cast': (visitor, target, positionalArgs, namedArgs) {
            return (target as JsonDecoder).cast<String, dynamic>();
          },
        },
        getters: {},
      );
}
