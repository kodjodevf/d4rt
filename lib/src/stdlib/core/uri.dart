import 'dart:convert';
import 'package:d4rt/d4rt.dart';

class UriCore {
  static BridgedClass get definition => BridgedClass(
        nativeType: Uri,
        name: 'Uri',
        typeParameterCount: 0,
        nativeNames: ['_SimpleUri'],
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            return Uri(
              scheme: namedArgs['scheme'] as String?,
              userInfo: namedArgs['userInfo'] as String?,
              host: namedArgs['host'] as String?,
              port: namedArgs['port'] as int?,
              path: namedArgs['path'] as String?,
              pathSegments: namedArgs['pathSegments'] as Iterable<String>?,
              query: namedArgs['query'] as String?,
              queryParameters:
                  namedArgs['queryParameters'] as Map<String, dynamic>?,
              fragment: namedArgs['fragment'] as String?,
            );
          },
          'http': (visitor, positionalArgs, namedArgs) {
            final host = positionalArgs[0] as String;
            final path =
                positionalArgs.length > 1 ? positionalArgs[1] as String : '';
            return Uri.http(host, path, positionalArgs.get<Map?>(2)?.cast());
          },
          'https': (visitor, positionalArgs, namedArgs) {
            final host = positionalArgs[0] as String;
            final path =
                positionalArgs.length > 1 ? positionalArgs[1] as String : '';

            return Uri.https(host, path, positionalArgs.get<Map?>(2)?.cast());
          },
          'file': (visitor, positionalArgs, namedArgs) {
            final path = positionalArgs[0] as String;
            final windows = namedArgs['windows'] as bool?;
            return Uri.file(path, windows: windows);
          },
          'directory': (visitor, positionalArgs, namedArgs) {
            final path = positionalArgs[0] as String;
            final windows = namedArgs['windows'] as bool?;
            return Uri.directory(path, windows: windows);
          },
          'dataFromBytes': (visitor, positionalArgs, namedArgs) {
            return Uri.dataFromBytes((positionalArgs[0] as List).cast(),
                mimeType: positionalArgs.get<String?>(1) ??
                    'application/octet-stream',
                parameters: positionalArgs.get<Map?>(2)?.cast(),
                percentEncoded: positionalArgs.get<bool?>(3) ?? false);
          },
          'dataFromString': (visitor, positionalArgs, namedArgs) {
            return Uri.dataFromString(positionalArgs[0] as String,
                mimeType: namedArgs.get<String?>('mimeType'),
                parameters:
                    (namedArgs.get<Map?>('parameters'))?.cast<String, String>(),
                encoding: namedArgs.get<Encoding?>('encoding') ?? utf8,
                base64: namedArgs.get<bool?>('base64') ?? false);
          },
        },
        staticMethods: {
          'parse': (visitor, positionalArgs, namedArgs) {
            final start = namedArgs['start'] as int? ?? 0;
            final end = namedArgs['end'] as int?;
            return Uri.parse(positionalArgs[0] as String, start, end);
          },
          'tryParse': (visitor, positionalArgs, namedArgs) {
            final start = namedArgs['start'] as int? ?? 0;
            final end = namedArgs['end'] as int?;
            return Uri.tryParse(positionalArgs[0] as String, start, end);
          },
          'parseIPv4Address': (visitor, positionalArgs, namedArgs) {
            return Uri.parseIPv4Address(positionalArgs[0] as String);
          },
          'parseIPv6Address': (visitor, positionalArgs, namedArgs) {
            final start = namedArgs['start'] as int? ?? 0;
            final end = namedArgs['end'] as int?;
            return Uri.parseIPv6Address(
                positionalArgs[0] as String, start, end);
          },
          'encodeComponent': (visitor, positionalArgs, namedArgs) {
            return Uri.encodeComponent(positionalArgs[0] as String);
          },
          'encodeQueryComponent': (visitor, positionalArgs, namedArgs) {
            final encoding = namedArgs['encoding'] as Encoding? ?? utf8;
            return Uri.encodeQueryComponent(positionalArgs[0] as String,
                encoding: encoding);
          },
          'decodeComponent': (visitor, positionalArgs, namedArgs) {
            return Uri.decodeComponent(positionalArgs[0] as String);
          },
          'decodeQueryComponent': (visitor, positionalArgs, namedArgs) {
            final encoding = namedArgs['encoding'] as Encoding? ?? utf8;
            return Uri.decodeQueryComponent(positionalArgs[0] as String,
                encoding: encoding);
          },
          'encodeFull': (visitor, positionalArgs, namedArgs) {
            return Uri.encodeFull(positionalArgs[0] as String);
          },
          'decodeFull': (visitor, positionalArgs, namedArgs) {
            return Uri.decodeFull(positionalArgs[0] as String);
          },
          'splitQueryString': (visitor, positionalArgs, namedArgs) {
            final encoding = namedArgs['encoding'] as Encoding? ?? utf8;
            return Uri.splitQueryString(positionalArgs[0] as String,
                encoding: encoding);
          },
        },
        methods: {
          'replace': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uri).replace(
              scheme: namedArgs['scheme'] as String?,
              userInfo: namedArgs['userInfo'] as String?,
              host: namedArgs['host'] as String?,
              port: namedArgs['port'] as int?,
              path: namedArgs['path'] as String?,
              pathSegments: namedArgs['pathSegments'] as Iterable<String>?,
              query: namedArgs['query'] as String?,
              queryParameters:
                  namedArgs['queryParameters'] as Map<String, dynamic>?,
              fragment: namedArgs['fragment'] as String?,
            );
          },
          'removeFragment': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uri).removeFragment();
          },
          'resolve': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uri).resolve(positionalArgs[0] as String);
          },
          'resolveUri': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uri).resolveUri(positionalArgs[0] as Uri);
          },
          'toFilePath': (visitor, target, positionalArgs, namedArgs) {
            final windows = namedArgs['windows'] as bool?;
            return (target as Uri).toFilePath(windows: windows);
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uri).toString();
          },
          'normalizePath': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uri).normalizePath();
          },
        },
        getters: {
          'scheme': (visitor, target) => (target as Uri).scheme,
          'authority': (visitor, target) => (target as Uri).authority,
          'userInfo': (visitor, target) => (target as Uri).userInfo,
          'host': (visitor, target) => (target as Uri).host,
          'port': (visitor, target) => (target as Uri).port,
          'path': (visitor, target) => (target as Uri).path,
          'query': (visitor, target) => (target as Uri).query,
          'fragment': (visitor, target) => (target as Uri).fragment,
          'pathSegments': (visitor, target) => (target as Uri).pathSegments,
          'queryParameters': (visitor, target) =>
              (target as Uri).queryParameters,
          'queryParametersAll': (visitor, target) =>
              (target as Uri).queryParametersAll,
          'isAbsolute': (visitor, target) => (target as Uri).isAbsolute,
          'hasScheme': (visitor, target) => (target as Uri).hasScheme,
          'hasAuthority': (visitor, target) => (target as Uri).hasAuthority,
          'hasPort': (visitor, target) => (target as Uri).hasPort,
          'hasQuery': (visitor, target) => (target as Uri).hasQuery,
          'hasFragment': (visitor, target) => (target as Uri).hasFragment,
          'hasEmptyPath': (visitor, target) => (target as Uri).hasEmptyPath,
          'hasAbsolutePath': (visitor, target) =>
              (target as Uri).hasAbsolutePath,
          'origin': (visitor, target) => (target as Uri).origin,
          'isScheme': (visitor, target) => (target as Uri).isScheme,
          'hashCode': (visitor, target) => (target as Uri).hashCode,
          'runtimeType': (visitor, target) => (target as Uri).runtimeType,
        },
      );
}
