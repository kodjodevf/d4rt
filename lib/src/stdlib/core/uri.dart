import 'dart:convert';
import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart';
import 'package:d4rt/src/utils/extensions/map.dart';

class UriCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Define Uri type and constructors/factories as native functions
    environment.define(
        'Uri',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Default constructor using named arguments
          return namedArguments.isEmpty
              ? Uri
              : Uri(
                  scheme: namedArguments.get<String?>('scheme'),
                  userInfo: namedArguments.get<String?>('userInfo'),
                  host: namedArguments.get<String?>('host'),
                  port: namedArguments.get<int?>('port'),
                  path: namedArguments.get<String?>('path'),
                  pathSegments: (namedArguments.get<List?>('pathSegments'))
                      ?.cast<String>(),
                  query: namedArguments.get<String?>('query'),
                  queryParameters: (namedArguments.get<Map?>('queryParameters'))
                      ?.cast<String, dynamic>(),
                  fragment: namedArguments.get<String?>('fragment'),
                );
        },
            arity: 0, // Positional arity 0, uses named args
            name: 'Uri'));

    // Define static factories like Uri.http, Uri.https, Uri.file etc. if needed
    // These are currently handled in evalMethod static part
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is Uri) {
      switch (name) {
        case 'toString':
          return target.toString();
        case 'host':
          return target.host;
        case 'port':
          return target.port;
        case 'scheme':
          return target.scheme;
        case 'path':
          return target.path;
        case 'query':
          return target.query;
        case 'fragment':
          return target.fragment;
        case 'authority':
          return target.authority;
        case 'userInfo':
          return target.userInfo;
        case 'hasScheme':
          return target.hasScheme;
        case 'hasAuthority':
          return target.hasAuthority;
        case 'hasPort':
          return target.hasPort;
        case 'hasQuery':
          return target.hasQuery;
        case 'hasFragment':
          return target.hasFragment;
        case 'isAbsolute': // Added from dart:core
          return target.isAbsolute;
        case 'origin':
          return target.origin;
        case 'pathSegments':
          return target.pathSegments;
        case 'queryParameters':
          return target.queryParameters;
        case 'queryParametersAll':
          return target.queryParametersAll;
        case 'replace':
          return target.replace(
            scheme: namedArguments.get<String?>('scheme'),
            userInfo: namedArguments.get<String?>('userInfo'),
            host: namedArguments.get<String?>('host'),
            port: namedArguments.get<int?>('port'),
            path: namedArguments.get<String?>('path'),
            pathSegments:
                (namedArguments.get<List?>('pathSegments'))?.cast<String>(),
            query: namedArguments.get<String?>('query'),
            queryParameters: (namedArguments.get<Map?>('queryParameters'))
                ?.cast<String, String>(),
            fragment: namedArguments.get<String?>('fragment'),
          );
        case 'removeFragment': // Added from dart:core
          return target.removeFragment();
        case 'resolve':
          return target.resolve(arguments[0] as String);
        case 'resolveUri':
          return target.resolveUri(arguments[0] as Uri);
        case 'normalizePath': // Added from dart:core
          return target.normalizePath();
        case 'toFilePath':
          return target.toFilePath(
              windows: namedArguments.get<bool?>('windows') ?? false);
        case 'data': // Accessor for UriData
          if (!target.isScheme("data")) return null;
          return target
              .data; // Returns UriData? object - might need specific handling
        case 'hashCode':
          return target.hashCode;
        default:
          throw RuntimeError(
              'Uri has no instance method/getter mapping for "$name"');
      }
    } else if (target == Uri) {
      // Check if calling on the Uri type itself (static)
      // static methods
      switch (name) {
        case 'dataFromBytes':
          return Uri.dataFromBytes(
              (arguments[0] as List).cast<int>(), // Ensure List<int>
              mimeType: namedArguments.get<String?>('mimeType') ??
                  "application/octet-stream",
              parameters: (namedArguments.get<Map?>('parameters'))
                  ?.cast<String, String>(),
              percentEncoded:
                  namedArguments.get<bool?>('percentEncoded') ?? false);
        case 'dataFromString':
          return Uri.dataFromString(arguments[0] as String,
              mimeType: namedArguments.get<String?>('mimeType') ??
                  "text/plain", // Default changed
              parameters: (namedArguments.get<Map?>('parameters'))
                  ?.cast<String, String>(),
              encoding: namedArguments.get<Encoding?>('encoding') ?? utf8,
              base64: namedArguments.get<bool?>('base64') ?? false);
        case 'parse':
          // Uri.parse has start and end optional positional args
          return Uri.parse(arguments[0] as String, arguments.get<int>(1) ?? 0,
              arguments.get<int?>(2));
        case 'tryParse':
          // Uri.tryParse has start and end optional positional args
          return Uri.tryParse(arguments[0] as String,
              arguments.get<int>(1) ?? 0, arguments.get<int?>(2));
        case 'encodeComponent':
          return Uri.encodeComponent(arguments[0] as String);
        case 'decodeComponent':
          return Uri.decodeComponent(arguments[0] as String);
        case 'encodeQueryComponent':
          return Uri.encodeQueryComponent(arguments[0] as String,
              encoding: namedArguments.get<Encoding?>('encoding') ?? utf8);
        case 'decodeQueryComponent':
          return Uri.decodeQueryComponent(arguments[0] as String,
              encoding: namedArguments.get<Encoding?>('encoding') ?? utf8);
        case 'encodeFull':
          return Uri.encodeFull(arguments[0] as String);
        case 'decodeFull':
          return Uri.decodeFull(arguments[0] as String);
        case 'splitQueryString':
          return Uri.splitQueryString(arguments[0] as String,
              encoding: namedArguments.get<Encoding?>('encoding') ?? utf8);
        case 'parseIPv4Address': // Added from dart:core
          return Uri.parseIPv4Address(arguments[0] as String);
        case 'parseIPv6Address': // Added from dart:core
          return Uri.parseIPv6Address(arguments[0] as String,
              arguments.get<int>(1) ?? 0, arguments.get<int?>(2));
        // queryParametersAll removed as static, it's instance method
        case 'https':
          return Uri.https(arguments[0] as String, arguments[1] as String,
              (arguments.get<Map?>(2))?.cast<String, dynamic>());
        case 'http':
          return Uri.http(arguments[0] as String, arguments[1] as String,
              (arguments.get<Map?>(2))?.cast<String, dynamic>());
        case 'file':
          return Uri.file(arguments[0] as String,
              windows: namedArguments.get<bool?>('windows') ?? false);
        case 'directory':
          return Uri.directory(arguments[0] as String,
              windows: namedArguments.get<bool?>('windows') ?? false);
        case 'base': // Added from dart:core
          return Uri.base;
        default:
          throw RuntimeError(
              'Uri has no static method/factory mapping for "$name"');
      }
    } else {
      throw RuntimeError(
          'Invalid target for Uri method call: ${target?.runtimeType}');
    }
  }
}
