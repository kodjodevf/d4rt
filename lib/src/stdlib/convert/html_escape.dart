import 'dart:convert';
import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart';
import 'package:d4rt/src/utils/extensions/map.dart';

class HtmlEscapeConvert implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Define the default instance
    environment.define('htmlEscape', htmlEscape);

    // Define the type and constructor
    environment.define(
        'HtmlEscape',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Constructor: HtmlEscape([HtmlEscapeMode mode = HtmlEscapeMode.unknown])
          final mode =
              arguments.get<HtmlEscapeMode?>(0) ?? HtmlEscapeMode.unknown;
          return HtmlEscape(mode);
        }, arity: 1, name: 'HtmlEscape') // 0 or 1 positional arg
        );

    environment.define(
        'HtmlEscapeMode',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return HtmlEscapeMode(
              name: namedArguments.get<String?>('name') ?? 'custom',
              escapeQuot: namedArguments.get<bool?>('escapeQuot') ?? false,
              escapeApos: namedArguments.get<bool?>('escapeApos') ?? false,
              escapeLtGt: namedArguments.get<bool?>('escapeLtGt') ?? false,
              escapeSlash: namedArguments.get<bool?>('escapeSlash') ?? false);
        }, arity: 1, name: 'HtmlEscapeMode'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is HtmlEscape) {
      // HtmlEscape extends Converter<String, String>
      switch (name) {
        case 'convert':
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'HtmlEscape.convert requires a String argument.');
          }
          return target.convert(arguments[0] as String);
        case 'startChunkedConversion': // Added
          if (arguments.length != 1 || arguments[0] is! Sink<String>) {
            throw RuntimeError(
                'startChunkedConversion requires a Sink<String> argument.');
          }
          return target.startChunkedConversion(arguments[0] as Sink<String>);
        case 'bind': // Added
          if (arguments.length != 1 || arguments[0] is! Stream<String>) {
            throw RuntimeError('bind requires a Stream<String> argument.');
          }
          return target.bind(arguments[0] as Stream<String>);
        case 'fuse': // Added
          // Converter<String, String> fuses with Converter<String, T>
          if (arguments.length != 1 ||
              arguments[0] is! Converter<String, dynamic>) {
            throw RuntimeError(
                'HtmlEscape.fuse requires another Converter<String, dynamic> as argument.');
          }
          return target.fuse(arguments[0] as Converter<String, dynamic>);
        case 'cast': // Added
          return target.cast<String, String>();
        default:
          throw RuntimeError(
              'HtmlEscape has no method/getter mapping for "$name"');
      }
    } else if (target is HtmlEscapeMode) {
      // Simple class, only basic methods like toString, hashCode
      switch (name) {
        // case 'index': // Not an enum
        //  return target.index;
        case 'toString':
          return target.toString();
        case 'hashCode':
          return target.hashCode;
        default:
          throw RuntimeError(
              'HtmlEscapeMode has no method/getter mapping for "$name"');
      }
    } else {
      switch (name) {
        case 'attribute':
          return HtmlEscapeMode.attribute;
        case 'element':
          return HtmlEscapeMode.element;
        case 'unknown':
          return HtmlEscapeMode.unknown;
        default:
          throw RuntimeError(
              'HtmlEscapeMode has no static method mapping for "$name"');
      }
    }
  }
}
