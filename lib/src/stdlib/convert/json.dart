import 'dart:convert';
import 'package:d4rt/d4rt.dart';

Object? Function(Object? nonEncodable)? wrapJsonToEncodable(
    InterpreterVisitor visitor, Object? toEncodableArg) {
  if (toEncodableArg is InterpretedFunction) {
    return (object) {
      final actual = object is BridgedInstance ? object.nativeObject : object;
      return toEncodableArg.call(visitor, [actual]);
    };
  } else if (toEncodableArg is Callable) {
    return (object) {
      final actual = object is BridgedInstance ? object.nativeObject : object;
      return toEncodableArg.call(visitor, [actual], {});
    };
  } else if (toEncodableArg is Function) {
    return (object) {
      final actual = object is BridgedInstance ? object.nativeObject : object;
      return (toEncodableArg as dynamic)(actual);
    };
  }
  // Automatic fallback for InterpretedInstance defining toJson()
  return (object) {
    final actual = object is BridgedInstance ? object.nativeObject : object;
    if (actual is InterpretedInstance) {
      final toJsonMethod = actual.klass.methods['toJson'];
      if (toJsonMethod != null) {
        try {
          return toJsonMethod.bind(actual).call(visitor, [], {});
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
        isSubtypeOfFunc: (value) => value is JsonCodec,
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
            final unwrapped = positionalArgs[0] is BridgedInstance
                ? (positionalArgs[0] as BridgedInstance).nativeObject
                : positionalArgs[0];
            if (toEncodableArg != null) {
              return (target as JsonCodec).encode(
                unwrapped,
                toEncodable: wrapJsonToEncodable(visitor, toEncodableArg),
              );
            }
            return (target as JsonCodec).encode(unwrapped);
          },
          'decode': (visitor, target, positionalArgs, namedArgs) {
            final source = positionalArgs[0] as String;
            final reviverArg = namedArgs['reviver'] ??
                (positionalArgs.length > 1 ? positionalArgs[1] : null);
            if (reviverArg != null) {
              return (target as JsonCodec).decode(
                source,
                reviver: wrapJsonReviver(visitor, reviverArg),
              );
            }
            return (target as JsonCodec).decode(source);
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
          'decoder': (visitor, target) => (target as JsonCodec).decoder,
          'encoder': (visitor, target) => (target as JsonCodec).encoder,
          'inverted': (visitor, target) => (target as JsonCodec).inverted,
          'hashCode': (visitor, target) => (target as JsonCodec).hashCode,
          'runtimeType': (visitor, target) => (target as JsonCodec).runtimeType,
        },
      );
}

class JsonEncoderConvert {
  static BridgedClass get definition => BridgedClass(
        nativeType: JsonEncoder,
        name: 'JsonEncoder',
        typeParameterCount: 0,
        isSubtypeOfFunc: (value) => value is JsonEncoder,
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
            final unwrapped = positionalArgs[0] is BridgedInstance
                ? (positionalArgs[0] as BridgedInstance).nativeObject
                : positionalArgs[0];
            return (target as JsonEncoder).convert(unwrapped);
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
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as JsonEncoder).toString();
          },
        },
        getters: {
          'indent': (visitor, target) => (target as JsonEncoder).indent,
          'hashCode': (visitor, target) => (target as JsonEncoder).hashCode,
          'runtimeType': (visitor, target) =>
              (target as JsonEncoder).runtimeType,
        },
      );
}

class JsonDecoderConvert {
  static BridgedClass get definition => BridgedClass(
        nativeType: JsonDecoder,
        name: 'JsonDecoder',
        typeParameterCount: 0,
        isSubtypeOfFunc: (value) => value is JsonDecoder,
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
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as JsonDecoder).toString();
          },
        },
        getters: {
          'hashCode': (visitor, target) => (target as JsonDecoder).hashCode,
          'runtimeType': (visitor, target) =>
              (target as JsonDecoder).runtimeType,
        },
      );
}

class JsonUnsupportedObjectErrorConvert {
  static BridgedClass get definition => BridgedClass(
        nativeType: JsonUnsupportedObjectError,
        name: 'JsonUnsupportedObjectError',
        typeParameterCount: 0,
        isSubtypeOfFunc: (value) => value is JsonUnsupportedObjectError,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final unsupportedObject =
                positionalArgs.isNotEmpty ? positionalArgs[0] : null;
            final cause = namedArgs['cause'];
            final partialResult = namedArgs['partialResult'] as String?;
            return JsonUnsupportedObjectError(
              unsupportedObject,
              cause: cause,
              partialResult: partialResult,
            );
          },
        },
        methods: {
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as JsonUnsupportedObjectError).toString();
          },
        },
        getters: {
          'unsupportedObject': (visitor, target) =>
              (target as JsonUnsupportedObjectError).unsupportedObject,
          'cause': (visitor, target) =>
              (target as JsonUnsupportedObjectError).cause,
          'partialResult': (visitor, target) =>
              (target as JsonUnsupportedObjectError).partialResult,
          'hashCode': (visitor, target) =>
              (target as JsonUnsupportedObjectError).hashCode,
          'runtimeType': (visitor, target) =>
              (target as JsonUnsupportedObjectError).runtimeType,
        },
      );
}
