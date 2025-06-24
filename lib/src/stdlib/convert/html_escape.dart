import 'dart:convert';
import 'package:d4rt/d4rt.dart';

class HtmlEscapeConvert {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: HtmlEscape,
        name: 'HtmlEscape',
        typeParameterCount: 0,
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
        },
        getters: {
          'hashCode': (visitor, target) => (target as HtmlEscape).hashCode,
          'runtimeType': (visitor, target) =>
              (target as HtmlEscape).runtimeType,
        },
      );

  static BridgedClassDefinition get modeDefinition => BridgedClassDefinition(
        nativeType: HtmlEscapeMode,
        name: 'HtmlEscapeMode',
        typeParameterCount: 0,
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
        methods: {},
        getters: {
          'attribute': (visitor, target) => HtmlEscapeMode.attribute,
          'element': (visitor, target) => HtmlEscapeMode.element,
          'unknown': (visitor, target) => HtmlEscapeMode.unknown,
        },
      );

  static void register(Environment environment) {
    environment.defineBridge(definition);
    environment.defineBridge(modeDefinition);

    // Define the default instance
    environment.define('htmlEscape', htmlEscape);
  }
}
