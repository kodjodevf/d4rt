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
            if (positionalArgs.length != 3 ||
                positionalArgs[0] is! String ||
                positionalArgs[1] is! String ||
                positionalArgs[2] is! String) {
              throw RuntimeError(
                  'open requires method, host, and path arguments.');
            }
            final port =
                namedArgs['port'] as int? ?? HttpClient.defaultHttpPort;
            return (target as HttpClient).open(
              positionalArgs[0] as String,
              positionalArgs[1] as String,
              port,
              positionalArgs[2] as String,
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
          'defaultHttpPort': (visitor, target) => HttpClient.defaultHttpPort,
          'defaultHttpsPort': (visitor, target) => HttpClient.defaultHttpsPort,
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

class IoHttpStdlib {
  static void register(Environment environment) {
    environment.defineBridge(HttpClientIo.definition);
    environment.defineBridge(HttpServerIo.definition);
    environment.defineBridge(HttpClientRequestIo.definition);
    environment.defineBridge(HttpClientResponseIo.definition);

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
  }
}
