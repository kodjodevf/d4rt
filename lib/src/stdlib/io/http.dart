import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:d4rt/d4rt.dart';

class HttpClientIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: HttpClient,
        name: 'HttpClient',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final context = namedArgs['context'] as SecurityContext?;
            return HttpClient(context: context);
          },
        },
        staticMethods: {
          'findProxyFromEnvironment': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! Uri) {
              throw RuntimeError(
                  'HttpClient.findProxyFromEnvironment requires a Uri argument.');
            }
            final environmentMap =
                namedArgs['environment'] as Map<String, String>?;
            return HttpClient.findProxyFromEnvironment(
              positionalArgs[0] as Uri,
              environment: environmentMap,
            );
          },
        },
        methods: {
          'getUrl': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! Uri) {
              throw RuntimeError('getUrl requires a Uri argument.');
            }
            return (target as HttpClient).getUrl(positionalArgs[0] as Uri);
          },
          'postUrl': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! Uri) {
              throw RuntimeError('postUrl requires a Uri argument.');
            }
            return (target as HttpClient).postUrl(positionalArgs[0] as Uri);
          },
          'putUrl': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! Uri) {
              throw RuntimeError('putUrl requires a Uri argument.');
            }
            return (target as HttpClient).putUrl(positionalArgs[0] as Uri);
          },
          'deleteUrl': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! Uri) {
              throw RuntimeError('deleteUrl requires a Uri argument.');
            }
            return (target as HttpClient).deleteUrl(positionalArgs[0] as Uri);
          },
          'headUrl': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! Uri) {
              throw RuntimeError('headUrl requires a Uri argument.');
            }
            return (target as HttpClient).headUrl(positionalArgs[0] as Uri);
          },
          'patchUrl': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! Uri) {
              throw RuntimeError('patchUrl requires a Uri argument.');
            }
            return (target as HttpClient).patchUrl(positionalArgs[0] as Uri);
          },
          'open': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 4 ||
                positionalArgs[0] is! String ||
                positionalArgs[1] is! String ||
                positionalArgs[2] is! int ||
                positionalArgs[3] is! String) {
              throw RuntimeError(
                  'open requires method, host, port, and path arguments.');
            }
            return (target as HttpClient).open(
              positionalArgs[0] as String,
              positionalArgs[1] as String,
              positionalArgs[2] as int,
              positionalArgs[3] as String,
            );
          },
          'openUrl': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 2 ||
                positionalArgs[0] is! String ||
                positionalArgs[1] is! Uri) {
              throw RuntimeError('openUrl requires method and Uri arguments.');
            }
            return (target as HttpClient).openUrl(
              positionalArgs[0] as String,
              positionalArgs[1] as Uri,
            );
          },
          'get': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 3 ||
                positionalArgs[0] is! String ||
                positionalArgs[1] is! int ||
                positionalArgs[2] is! String) {
              throw RuntimeError(
                  'get requires host, port, and path arguments.');
            }
            return (target as HttpClient).get(
              positionalArgs[0] as String,
              positionalArgs[1] as int,
              positionalArgs[2] as String,
            );
          },
          'post': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 3 ||
                positionalArgs[0] is! String ||
                positionalArgs[1] is! int ||
                positionalArgs[2] is! String) {
              throw RuntimeError(
                  'post requires host, port, and path arguments.');
            }
            return (target as HttpClient).post(
              positionalArgs[0] as String,
              positionalArgs[1] as int,
              positionalArgs[2] as String,
            );
          },
          'put': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 3 ||
                positionalArgs[0] is! String ||
                positionalArgs[1] is! int ||
                positionalArgs[2] is! String) {
              throw RuntimeError(
                  'put requires host, port, and path arguments.');
            }
            return (target as HttpClient).put(
              positionalArgs[0] as String,
              positionalArgs[1] as int,
              positionalArgs[2] as String,
            );
          },
          'delete': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 3 ||
                positionalArgs[0] is! String ||
                positionalArgs[1] is! int ||
                positionalArgs[2] is! String) {
              throw RuntimeError(
                  'delete requires host, port, and path arguments.');
            }
            return (target as HttpClient).delete(
              positionalArgs[0] as String,
              positionalArgs[1] as int,
              positionalArgs[2] as String,
            );
          },
          'patch': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 3 ||
                positionalArgs[0] is! String ||
                positionalArgs[1] is! int ||
                positionalArgs[2] is! String) {
              throw RuntimeError(
                  'patch requires host, port, and path arguments.');
            }
            return (target as HttpClient).patch(
              positionalArgs[0] as String,
              positionalArgs[1] as int,
              positionalArgs[2] as String,
            );
          },
          'head': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 3 ||
                positionalArgs[0] is! String ||
                positionalArgs[1] is! int ||
                positionalArgs[2] is! String) {
              throw RuntimeError(
                  'head requires host, port, and path arguments.');
            }
            return (target as HttpClient).head(
              positionalArgs[0] as String,
              positionalArgs[1] as int,
              positionalArgs[2] as String,
            );
          },
          'addCredentials': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 3 ||
                positionalArgs[0] is! Uri ||
                positionalArgs[1] is! String ||
                positionalArgs[2] is! HttpClientCredentials) {
              throw RuntimeError(
                  'addCredentials requires Uri, realm String, and HttpClientCredentials arguments.');
            }
            (target as HttpClient).addCredentials(
              positionalArgs[0] as Uri,
              positionalArgs[1] as String,
              positionalArgs[2] as HttpClientCredentials,
            );
            return null;
          },
          'addProxyCredentials': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 4 ||
                positionalArgs[0] is! String ||
                positionalArgs[1] is! int ||
                positionalArgs[2] is! String ||
                positionalArgs[3] is! HttpClientCredentials) {
              throw RuntimeError(
                  'addProxyCredentials requires host, port, realm, and HttpClientCredentials arguments.');
            }
            (target as HttpClient).addProxyCredentials(
              positionalArgs[0] as String,
              positionalArgs[1] as int,
              positionalArgs[2] as String,
              positionalArgs[3] as HttpClientCredentials,
            );
            return null;
          },
          'close': (visitor, target, positionalArgs, namedArgs) {
            (target as HttpClient).close(
              force: namedArgs['force'] as bool? ?? false,
            );
            return null;
          },
        },
        getters: {
          'idleTimeout': (visitor, target) =>
              (target as HttpClient).idleTimeout,
          'connectionTimeout': (visitor, target) =>
              (target as HttpClient).connectionTimeout,
          'maxConnectionsPerHost': (visitor, target) =>
              (target as HttpClient).maxConnectionsPerHost,
          'autoUncompress': (visitor, target) =>
              (target as HttpClient).autoUncompress,
          'userAgent': (visitor, target) => (target as HttpClient).userAgent,
        },
        staticGetters: {
          'defaultHttpPort': (visitor) => HttpClient.defaultHttpPort,
          'defaultHttpsPort': (visitor) => HttpClient.defaultHttpsPort,
          'enableTimelineLogging': (visitor) =>
              HttpClient.enableTimelineLogging,
        },
        staticSetters: {
          'enableTimelineLogging': (visitor, value) {
            HttpClient.enableTimelineLogging = value as bool;
            return;
          },
        },
        setters: {
          'idleTimeout': (visitor, target, value) {
            (target as HttpClient).idleTimeout = value as Duration;
            return;
          },
          'connectionTimeout': (visitor, target, value) {
            (target as HttpClient).connectionTimeout = value as Duration?;
            return;
          },
          'maxConnectionsPerHost': (visitor, target, value) {
            (target as HttpClient).maxConnectionsPerHost = value as int?;
            return;
          },
          'autoUncompress': (visitor, target, value) {
            (target as HttpClient).autoUncompress = value as bool;
            return;
          },
          'userAgent': (visitor, target, value) {
            (target as HttpClient).userAgent = value as String?;
            return;
          },
          'authenticate': (visitor, target, value) {
            if (value != null) {
              final callback = value as InterpretedFunction;
              (target as HttpClient).authenticate =
                  (Uri url, String scheme, String? realm) async {
                if (visitor == null) {
                  throw RuntimeError(
                      'Visitor cannot be null for authenticate callback');
                }
                final result = callback.call(visitor, [url, scheme, realm]);
                return result is Future ? await result : result as bool;
              };
            } else {
              (target as HttpClient).authenticate = null;
            }
            return;
          },
          'findProxy': (visitor, target, value) {
            if (value != null) {
              final callback = value as InterpretedFunction;
              (target as HttpClient).findProxy = (Uri url) {
                if (visitor == null) {
                  throw RuntimeError(
                      'Visitor cannot be null for findProxy callback');
                }
                final result = callback.call(visitor, [url]);
                return result as String;
              };
            } else {
              (target as HttpClient).findProxy = null;
            }
            return;
          },
          'badCertificateCallback': (visitor, target, value) {
            if (value != null) {
              final callback = value as InterpretedFunction;
              (target as HttpClient).badCertificateCallback =
                  (cert, host, port) {
                if (visitor == null) {
                  throw RuntimeError(
                      'Visitor cannot be null for badCertificateCallback');
                }
                final result = callback.call(visitor, [cert, host, port]);
                return result as bool;
              };
            } else {
              (target as HttpClient).badCertificateCallback = null;
            }
            return;
          },
          'keyLog': (visitor, target, value) {
            if (value != null) {
              final callback = value as InterpretedFunction;
              (target as HttpClient).keyLog = (String line) {
                if (visitor == null) {
                  throw RuntimeError(
                      'Visitor cannot be null for keyLog callback');
                }
                callback.call(visitor, [line]);
              };
            } else {
              (target as HttpClient).keyLog = null;
            }
            return;
          },
        },
      );
}

class HttpServerIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: HttpServer,
        name: 'HttpServer',
        typeParameterCount: 0,
        constructors: {},
        staticMethods: {
          'bind': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 2 || positionalArgs[1] is! int) {
              throw RuntimeError(
                  'HttpServer.bind requires address and port arguments.');
            }
            return HttpServer.bind(
              positionalArgs[0],
              positionalArgs[1] as int,
              backlog: namedArgs['backlog'] as int? ?? 0,
              v6Only: namedArgs['v6Only'] as bool? ?? false,
              shared: namedArgs['shared'] as bool? ?? false,
            );
          },
          'bindSecure': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 3 ||
                positionalArgs[1] is! int ||
                positionalArgs[2] is! SecurityContext) {
              throw RuntimeError(
                  'HttpServer.bindSecure requires address, port, and context arguments.');
            }
            return HttpServer.bindSecure(
              positionalArgs[0],
              positionalArgs[1] as int,
              positionalArgs[2] as SecurityContext,
              backlog: namedArgs['backlog'] as int? ?? 0,
              v6Only: namedArgs['v6Only'] as bool? ?? false,
              requestClientCertificate:
                  namedArgs['requestClientCertificate'] as bool? ?? false,
              shared: namedArgs['shared'] as bool? ?? false,
            );
          },
          'listenOn': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! ServerSocket) {
              throw RuntimeError(
                  'HttpServer.listenOn requires a ServerSocket argument.');
            }
            return HttpServer.listenOn(positionalArgs[0] as ServerSocket);
          },
        },
        methods: {
          'listen': (visitor, target, positionalArgs, namedArgs) {
            final onData = positionalArgs[0] as InterpretedFunction?;
            final onError = namedArgs['onError'] as InterpretedFunction?;
            final onDone = namedArgs['onDone'] as InterpretedFunction?;
            final cancelOnError = namedArgs['cancelOnError'] as bool?;

            if (onData == null) {
              throw RuntimeError('listen requires an onData callback.');
            }

            return (target as HttpServer).listen(
              (request) => onData.call(visitor, [request]),
              onError: onError == null
                  ? null
                  : (error, stackTrace) =>
                      onError.call(visitor, [error, stackTrace]),
              onDone: onDone == null ? null : () => onDone.call(visitor, []),
              cancelOnError: cancelOnError,
            );
          },
          'close': (visitor, target, positionalArgs, namedArgs) =>
              (target as HttpServer).close(
                force: namedArgs['force'] as bool? ?? false,
              ),
          'connectionsInfo': (visitor, target, positionalArgs, namedArgs) =>
              (target as HttpServer).connectionsInfo(),
        },
        getters: {
          'port': (visitor, target) => (target as HttpServer).port,
          'address': (visitor, target) => (target as HttpServer).address,
          'autoCompress': (visitor, target) =>
              (target as HttpServer).autoCompress,
          'idleTimeout': (visitor, target) =>
              (target as HttpServer).idleTimeout,
          'serverHeader': (visitor, target) =>
              (target as HttpServer).serverHeader,
          'defaultResponseHeaders': (visitor, target) =>
              (target as HttpServer).defaultResponseHeaders,
        },
        setters: {
          'autoCompress': (visitor, target, value) {
            (target as HttpServer).autoCompress = value as bool;
            return;
          },
          'idleTimeout': (visitor, target, value) {
            (target as HttpServer).idleTimeout = value as Duration?;
            return;
          },
          'serverHeader': (visitor, target, value) {
            (target as HttpServer).serverHeader = value as String?;
            return;
          },
          'sessionTimeout': (visitor, target, value) {
            (target as HttpServer).sessionTimeout = value as int;
            return;
          },
        },
      );
}

class HttpClientRequestIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: HttpClientRequest,
        name: 'HttpClientRequest',
        typeParameterCount: 0,
        constructors: {},
        methods: {
          'write': (visitor, target, positionalArgs, namedArgs) {
            (target as HttpClientRequest).write(positionalArgs[0]);
            return null;
          },
          'writeln': (visitor, target, positionalArgs, namedArgs) {
            (target as HttpClientRequest).writeln(
              positionalArgs.isNotEmpty ? positionalArgs[0] : '',
            );
            return null;
          },
          'writeAll': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty || positionalArgs[0] is! Iterable) {
              throw RuntimeError('writeAll requires an Iterable argument.');
            }
            (target as HttpClientRequest).writeAll(
              positionalArgs[0] as Iterable<dynamic>,
              positionalArgs.length > 1 ? positionalArgs[1] as String : '',
            );
            return null;
          },
          'add': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! List) {
              throw RuntimeError('add requires a List<int> argument.');
            }
            (target as HttpClientRequest).add(positionalArgs[0] as List<int>);
            return null;
          },
          'addStream': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 ||
                positionalArgs[0] is! Stream<List<int>>) {
              throw RuntimeError(
                  'addStream requires a Stream<List<int>> argument.');
            }
            return (target as HttpClientRequest).addStream(
              positionalArgs[0] as Stream<List<int>>,
            );
          },
          'flush': (visitor, target, positionalArgs, namedArgs) =>
              (target as HttpClientRequest).flush(),
          'close': (visitor, target, positionalArgs, namedArgs) =>
              (target as HttpClientRequest).close(),
          'addError': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw RuntimeError(
                  'addError requires at least one argument (error).');
            }
            (target as HttpClientRequest).addError(
              positionalArgs[0]!,
              positionalArgs.length > 1
                  ? positionalArgs[1] as StackTrace?
                  : null,
            );
            return null;
          },
          'abort': (visitor, target, positionalArgs, namedArgs) {
            (target as HttpClientRequest).abort(
              positionalArgs.isNotEmpty ? positionalArgs[0] : null,
              positionalArgs.length > 1
                  ? positionalArgs[1] as StackTrace?
                  : null,
            );
            return null;
          },
        },
        getters: {
          'persistentConnection': (visitor, target) =>
              (target as HttpClientRequest).persistentConnection,
          'followRedirects': (visitor, target) =>
              (target as HttpClientRequest).followRedirects,
          'maxRedirects': (visitor, target) =>
              (target as HttpClientRequest).maxRedirects,
          'contentLength': (visitor, target) =>
              (target as HttpClientRequest).contentLength,
          'encoding': (visitor, target) =>
              (target as HttpClientRequest).encoding,
          'bufferOutput': (visitor, target) =>
              (target as HttpClientRequest).bufferOutput,
          'method': (visitor, target) => (target as HttpClientRequest).method,
          'uri': (visitor, target) => (target as HttpClientRequest).uri,
          'headers': (visitor, target) => (target as HttpClientRequest).headers,
          'cookies': (visitor, target) => (target as HttpClientRequest).cookies,
          'done': (visitor, target) => (target as HttpClientRequest).done,
          'connectionInfo': (visitor, target) =>
              (target as HttpClientRequest).connectionInfo,
        },
        setters: {
          'persistentConnection': (visitor, target, value) {
            (target as HttpClientRequest).persistentConnection = value as bool;
            return;
          },
          'followRedirects': (visitor, target, value) {
            (target as HttpClientRequest).followRedirects = value as bool;
            return;
          },
          'maxRedirects': (visitor, target, value) {
            (target as HttpClientRequest).maxRedirects = value as int;
            return;
          },
          'contentLength': (visitor, target, value) {
            (target as HttpClientRequest).contentLength = value as int;
            return;
          },
          'encoding': (visitor, target, value) {
            (target as HttpClientRequest).encoding = value as Encoding;
            return;
          },
          'bufferOutput': (visitor, target, value) {
            (target as HttpClientRequest).bufferOutput = value as bool;
            return;
          },
        },
      );
}

class HttpClientResponseIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: HttpClientResponse,
        name: 'HttpClientResponse',
        typeParameterCount: 0,
        constructors: {},
        methods: {
          'listen': (visitor, target, positionalArgs, namedArgs) {
            final onData = positionalArgs[0] as InterpretedFunction?;
            final onError = namedArgs['onError'] as InterpretedFunction?;
            final onDone = namedArgs['onDone'] as InterpretedFunction?;
            final cancelOnError = namedArgs['cancelOnError'] as bool?;

            if (onData == null) {
              throw RuntimeError('listen requires an onData callback.');
            }

            return (target as HttpClientResponse).listen(
              (data) => onData.call(visitor, [data]),
              onError: onError == null
                  ? null
                  : (error, stackTrace) =>
                      onError.call(visitor, [error, stackTrace]),
              onDone: onDone == null ? null : () => onDone.call(visitor, []),
              cancelOnError: cancelOnError,
            );
          },
          'transform': (visitor, target, positionalArgs, namedArgs) {
            // Implementation for transform would be complex, placeholder
            throw RuntimeError(
                'transform not yet implemented in interpreted environment');
          },
          'redirect': (visitor, target, positionalArgs, namedArgs) {
            final method =
                positionalArgs.isNotEmpty ? positionalArgs[0] as String? : null;
            final url =
                positionalArgs.length > 1 ? positionalArgs[1] as Uri? : null;
            final followLoops = namedArgs['followLoops'] as bool?;
            return (target as HttpClientResponse)
                .redirect(method, url, followLoops);
          },
          'detachSocket': (visitor, target, positionalArgs, namedArgs) =>
              (target as HttpClientResponse).detachSocket(),
        },
        getters: {
          'statusCode': (visitor, target) =>
              (target as HttpClientResponse).statusCode,
          'reasonPhrase': (visitor, target) =>
              (target as HttpClientResponse).reasonPhrase,
          'contentLength': (visitor, target) =>
              (target as HttpClientResponse).contentLength,
          'compressionState': (visitor, target) =>
              (target as HttpClientResponse).compressionState,
          'persistentConnection': (visitor, target) =>
              (target as HttpClientResponse).persistentConnection,
          'isRedirect': (visitor, target) =>
              (target as HttpClientResponse).isRedirect,
          'redirects': (visitor, target) =>
              (target as HttpClientResponse).redirects,
          'headers': (visitor, target) =>
              (target as HttpClientResponse).headers,
          'cookies': (visitor, target) =>
              (target as HttpClientResponse).cookies,
          'certificate': (visitor, target) =>
              (target as HttpClientResponse).certificate,
          'connectionInfo': (visitor, target) =>
              (target as HttpClientResponse).connectionInfo,
        },
      );
}

class HttpHeadersIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: HttpHeaders,
        name: 'HttpHeaders',
        typeParameterCount: 0,
        constructors: {},
        staticGetters: {
          // HTTP Header constants
          'acceptHeader': (visitor) => HttpHeaders.acceptHeader,
          'acceptCharsetHeader': (visitor) => HttpHeaders.acceptCharsetHeader,
          'acceptEncodingHeader': (visitor) => HttpHeaders.acceptEncodingHeader,
          'acceptLanguageHeader': (visitor) => HttpHeaders.acceptLanguageHeader,
          'authorizationHeader': (visitor) => HttpHeaders.authorizationHeader,
          'cacheControlHeader': (visitor) => HttpHeaders.cacheControlHeader,
          'connectionHeader': (visitor) => HttpHeaders.connectionHeader,
          'contentEncodingHeader': (visitor) =>
              HttpHeaders.contentEncodingHeader,
          'contentLengthHeader': (visitor) => HttpHeaders.contentLengthHeader,
          'contentTypeHeader': (visitor) => HttpHeaders.contentTypeHeader,
          'cookieHeader': (visitor) => HttpHeaders.cookieHeader,
          'dateHeader': (visitor) => HttpHeaders.dateHeader,
          'hostHeader': (visitor) => HttpHeaders.hostHeader,
          'ifModifiedSinceHeader': (visitor) =>
              HttpHeaders.ifModifiedSinceHeader,
          'locationHeader': (visitor) => HttpHeaders.locationHeader,
          'setCookieHeader': (visitor) => HttpHeaders.setCookieHeader,
          'userAgentHeader': (visitor) => HttpHeaders.userAgentHeader,
        },
        methods: {
          'add': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length < 2) {
              throw RuntimeError('add requires name and value arguments.');
            }
            (target as HttpHeaders).add(
              positionalArgs[0] as String,
              positionalArgs[1]!,
              preserveHeaderCase:
                  namedArgs['preserveHeaderCase'] as bool? ?? false,
            );
            return null;
          },
          'set': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length < 2) {
              throw RuntimeError('set requires name and value arguments.');
            }
            (target as HttpHeaders).set(
              positionalArgs[0] as String,
              positionalArgs[1]!,
              preserveHeaderCase:
                  namedArgs['preserveHeaderCase'] as bool? ?? false,
            );
            return null;
          },
          'remove': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length < 2) {
              throw RuntimeError('remove requires name and value arguments.');
            }
            (target as HttpHeaders).remove(
              positionalArgs[0] as String,
              positionalArgs[1]!,
            );
            return null;
          },
          'removeAll': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw RuntimeError('removeAll requires name argument.');
            }
            (target as HttpHeaders).removeAll(positionalArgs[0] as String);
            return null;
          },
          'value': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw RuntimeError('value requires name argument.');
            }
            return (target as HttpHeaders).value(positionalArgs[0] as String);
          },
          'forEach': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty ||
                positionalArgs[0] is! InterpretedFunction) {
              throw RuntimeError('forEach requires a function argument.');
            }
            final callback = positionalArgs[0] as InterpretedFunction;
            (target as HttpHeaders).forEach((name, values) {
              callback.call(visitor, [name, values]);
            });
            return null;
          },
          'noFolding': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw RuntimeError('noFolding requires name argument.');
            }
            (target as HttpHeaders).noFolding(positionalArgs[0] as String);
            return null;
          },
          'clear': (visitor, target, positionalArgs, namedArgs) {
            (target as HttpHeaders).clear();
            return null;
          },
        },
        getters: {
          'date': (visitor, target) => (target as HttpHeaders).date,
          'expires': (visitor, target) => (target as HttpHeaders).expires,
          'ifModifiedSince': (visitor, target) =>
              (target as HttpHeaders).ifModifiedSince,
          'host': (visitor, target) => (target as HttpHeaders).host,
          'port': (visitor, target) => (target as HttpHeaders).port,
          'contentType': (visitor, target) =>
              (target as HttpHeaders).contentType,
          'contentLength': (visitor, target) =>
              (target as HttpHeaders).contentLength,
          'persistentConnection': (visitor, target) =>
              (target as HttpHeaders).persistentConnection,
          'chunkedTransferEncoding': (visitor, target) =>
              (target as HttpHeaders).chunkedTransferEncoding,
        },
        setters: {
          'date': (visitor, target, value) {
            (target as HttpHeaders).date = value as DateTime?;
            return;
          },
          'expires': (visitor, target, value) {
            (target as HttpHeaders).expires = value as DateTime?;
            return;
          },
          'ifModifiedSince': (visitor, target, value) {
            (target as HttpHeaders).ifModifiedSince = value as DateTime?;
            return;
          },
          'host': (visitor, target, value) {
            (target as HttpHeaders).host = value as String?;
            return;
          },
          'port': (visitor, target, value) {
            (target as HttpHeaders).port = value as int?;
            return;
          },
          'contentType': (visitor, target, value) {
            (target as HttpHeaders).contentType = value as ContentType?;
            return;
          },
          'contentLength': (visitor, target, value) {
            (target as HttpHeaders).contentLength = value as int;
            return;
          },
          'persistentConnection': (visitor, target, value) {
            (target as HttpHeaders).persistentConnection = value as bool;
            return;
          },
          'chunkedTransferEncoding': (visitor, target, value) {
            (target as HttpHeaders).chunkedTransferEncoding = value as bool;
            return;
          },
        },
      );
}

class ContentTypeIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: ContentType,
        name: 'ContentType',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length < 2 ||
                positionalArgs[0] is! String ||
                positionalArgs[1] is! String) {
              throw RuntimeError(
                  'ContentType constructor requires primaryType and subType arguments.');
            }
            return ContentType(
              positionalArgs[0] as String,
              positionalArgs[1] as String,
              charset: namedArgs['charset'] as String?,
              parameters:
                  namedArgs['parameters'] as Map<String, String?>? ?? const {},
            );
          },
        },
        staticMethods: {
          'parse': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'ContentType.parse requires a String argument.');
            }
            return ContentType.parse(positionalArgs[0] as String);
          },
        },
        staticGetters: {
          'text': (visitor) => ContentType.text,
          'html': (visitor) => ContentType.html,
          'json': (visitor) => ContentType.json,
          'binary': (visitor) => ContentType.binary,
        },
        getters: {
          'mimeType': (visitor, target) => (target as ContentType).mimeType,
          'primaryType': (visitor, target) =>
              (target as ContentType).primaryType,
          'subType': (visitor, target) => (target as ContentType).subType,
          'charset': (visitor, target) => (target as ContentType).charset,
          'value': (visitor, target) => (target as ContentType).value,
          'parameters': (visitor, target) => (target as ContentType).parameters,
        },
        methods: {
          'toString': (visitor, target, positionalArgs, namedArgs) =>
              (target as ContentType).toString(),
        },
      );
}

class CookieIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: Cookie,
        name: 'Cookie',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length < 2 ||
                positionalArgs[0] is! String ||
                positionalArgs[1] is! String) {
              throw RuntimeError(
                  'Cookie constructor requires name and value arguments.');
            }
            return Cookie(
                positionalArgs[0] as String, positionalArgs[1] as String);
          },
        },
        staticMethods: {
          'fromSetCookieValue': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'Cookie.fromSetCookieValue requires a String argument.');
            }
            return Cookie.fromSetCookieValue(positionalArgs[0] as String);
          },
        },
        getters: {
          'name': (visitor, target) => (target as Cookie).name,
          'value': (visitor, target) => (target as Cookie).value,
          'expires': (visitor, target) => (target as Cookie).expires,
          'maxAge': (visitor, target) => (target as Cookie).maxAge,
          'domain': (visitor, target) => (target as Cookie).domain,
          'path': (visitor, target) => (target as Cookie).path,
          'secure': (visitor, target) => (target as Cookie).secure,
          'httpOnly': (visitor, target) => (target as Cookie).httpOnly,
          'sameSite': (visitor, target) => (target as Cookie).sameSite,
        },
        setters: {
          'name': (visitor, target, value) {
            (target as Cookie).name = value as String;
            return;
          },
          'value': (visitor, target, value) {
            (target as Cookie).value = value as String;
            return;
          },
          'expires': (visitor, target, value) {
            (target as Cookie).expires = value as DateTime?;
            return;
          },
          'maxAge': (visitor, target, value) {
            (target as Cookie).maxAge = value as int?;
            return;
          },
          'domain': (visitor, target, value) {
            (target as Cookie).domain = value as String?;
            return;
          },
          'path': (visitor, target, value) {
            (target as Cookie).path = value as String?;
            return;
          },
          'secure': (visitor, target, value) {
            (target as Cookie).secure = value as bool;
            return;
          },
          'httpOnly': (visitor, target, value) {
            (target as Cookie).httpOnly = value as bool;
            return;
          },
          'sameSite': (visitor, target, value) {
            (target as Cookie).sameSite = value as SameSite?;
            return;
          },
        },
        methods: {
          'toString': (visitor, target, positionalArgs, namedArgs) =>
              (target as Cookie).toString(),
        },
      );
}

class HeaderValueIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: HeaderValue,
        name: 'HeaderValue',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final value =
                positionalArgs.isNotEmpty ? positionalArgs[0] as String : '';
            final parameters = positionalArgs.length > 1
                ? positionalArgs[1] as Map<String, String?>
                : const <String, String?>{};
            return HeaderValue(value, parameters);
          },
        },
        staticMethods: {
          'parse': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'HeaderValue.parse requires a String argument.');
            }
            return HeaderValue.parse(
              positionalArgs[0] as String,
              parameterSeparator:
                  namedArgs['parameterSeparator'] as String? ?? ';',
              valueSeparator: namedArgs['valueSeparator'] as String?,
              preserveBackslash:
                  namedArgs['preserveBackslash'] as bool? ?? false,
            );
          },
        },
        getters: {
          'value': (visitor, target) => (target as HeaderValue).value,
          'parameters': (visitor, target) => (target as HeaderValue).parameters,
        },
        methods: {
          'toString': (visitor, target, positionalArgs, namedArgs) =>
              (target as HeaderValue).toString(),
        },
      );
}

class IoHttpStdlib {
  static void register(Environment environment) {
    environment.defineBridge(HttpClientIo.definition);
    environment.defineBridge(HttpServerIo.definition);
    environment.defineBridge(HttpClientRequestIo.definition);
    environment.defineBridge(HttpClientResponseIo.definition);
    environment.defineBridge(HttpHeadersIo.definition);
    environment.defineBridge(ContentTypeIo.definition);
    environment.defineBridge(CookieIo.definition);
    environment.defineBridge(HeaderValueIo.definition);

    // Define constructor functions for credentials
    environment.define(
        'HttpClientCredentials',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return HttpClientCredentials;
        }, arity: 0, name: 'HttpClientCredentials'));

    environment.define(
        'HttpClientBasicCredentials',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          if (arguments.length != 2 ||
              arguments[0] is! String ||
              arguments[1] is! String) {
            throw RuntimeError(
                'HttpClientBasicCredentials requires username and password arguments.');
          }
          return HttpClientBasicCredentials(
              arguments[0] as String, arguments[1] as String);
        }, arity: 2, name: 'HttpClientBasicCredentials'));

    environment.define(
        'HttpClientDigestCredentials',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          if (arguments.length != 2 ||
              arguments[0] is! String ||
              arguments[1] is! String) {
            throw RuntimeError(
                'HttpClientDigestCredentials requires username and password arguments.');
          }
          return HttpClientDigestCredentials(
              arguments[0] as String, arguments[1] as String);
        }, arity: 2, name: 'HttpClientDigestCredentials'));

    environment.define(
        'HttpClientBearerCredentials',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          if (arguments.length != 1 || arguments[0] is! String) {
            throw RuntimeError(
                'HttpClientBearerCredentials requires a token argument.');
          }
          return HttpClientBearerCredentials(arguments[0] as String);
        }, arity: 1, name: 'HttpClientBearerCredentials'));
  }
}
