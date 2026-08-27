import 'dart:convert';
import 'package:d4rt/d4rt.dart';

class HtmlEscapeConvert {
  static BridgedClass get definition => BridgedClass(
        nativeType: HtmlEscape,
        name: 'HtmlEscape',
        typeParameterCount: 0,
        isSubtypeOfFunc: (value) => value is HtmlEscape,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final mode = positionalArgs.isNotEmpty
                ? positionalArgs[0] as HtmlEscapeMode?
                : HtmlEscapeMode.unknown;
            return HtmlEscape(mode ?? HtmlEscapeMode.unknown);
          },
        },
        methods: {
          'convert': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'HtmlEscape.convert requires a String argument.');
            }
            return (target as HtmlEscape).convert(positionalArgs[0] as String);
          },
          'startChunkedConversion':
              (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Sink<String>) {
              throw RuntimeError(
                  'startChunkedConversion requires a Sink<String> argument.');
            }
            return (target as HtmlEscape)
                .startChunkedConversion(positionalArgs[0] as Sink<String>);
          },
          'bind': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Stream<String>) {
              throw RuntimeError('bind requires a Stream<String> argument.');
            }
            return (target as HtmlEscape)
                .bind(positionalArgs[0] as Stream<String>);
          },
          'fuse': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Converter<String, dynamic>) {
              throw RuntimeError(
                  'HtmlEscape.fuse requires another Converter<String, dynamic> as argument.');
            }
            return (target as HtmlEscape)
                .fuse(positionalArgs[0] as Converter<String, dynamic>);
          },
          'cast': (visitor, target, positionalArgs, namedArgs) {
            return (target as HtmlEscape).cast<String, String>();
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as HtmlEscape).toString();
          },
        },
        getters: {
          'mode': (visitor, target) => (target as HtmlEscape).mode,
          'hashCode': (visitor, target) => (target as HtmlEscape).hashCode,
          'runtimeType': (visitor, target) =>
              (target as HtmlEscape).runtimeType,
        },
      );

  static BridgedClass get modeDefinition => BridgedClass(
        nativeType: HtmlEscapeMode,
        name: 'HtmlEscapeMode',
        typeParameterCount: 0,
        isSubtypeOfFunc: (value) => value is HtmlEscapeMode,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            return HtmlEscapeMode(
                name: namedArgs['name'] as String? ?? 'custom',
                escapeQuot: namedArgs['escapeQuot'] as bool? ?? false,
                escapeApos: namedArgs['escapeApos'] as bool? ?? false,
                escapeLtGt: namedArgs['escapeLtGt'] as bool? ?? false,
                escapeSlash: namedArgs['escapeSlash'] as bool? ?? false);
          },
        },
        staticGetters: {
          'attribute': (visitor) => HtmlEscapeMode.attribute,
          'element': (visitor) => HtmlEscapeMode.element,
          'unknown': (visitor) => HtmlEscapeMode.unknown,
          'sqAttribute': (visitor) => HtmlEscapeMode.sqAttribute,
        },
        methods: {
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as HtmlEscapeMode).toString();
          },
        },
        getters: {
          'escapeQuot': (visitor, target) =>
              (target as HtmlEscapeMode).escapeQuot,
          'escapeApos': (visitor, target) =>
              (target as HtmlEscapeMode).escapeApos,
          'escapeLtGt': (visitor, target) =>
              (target as HtmlEscapeMode).escapeLtGt,
          'escapeSlash': (visitor, target) =>
              (target as HtmlEscapeMode).escapeSlash,
          'hashCode': (visitor, target) => (target as HtmlEscapeMode).hashCode,
          'runtimeType': (visitor, target) =>
              (target as HtmlEscapeMode).runtimeType,
        },
      );

  static void register(Environment environment) {
    environment.defineBridge(definition);
    environment.defineBridge(modeDefinition);

    // Define the default instance
    environment.define('htmlEscape', htmlEscape);
  }
}
