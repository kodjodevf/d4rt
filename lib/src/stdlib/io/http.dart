import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart';
import 'package:d4rt/src/utils/extensions/map.dart';

class HttpClientIo implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'HttpClient',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Constructor: HttpClient({SecurityContext? context})
          final context = namedArguments.get<SecurityContext?>('context');
          return HttpClient(context: context);
        }, arity: 0, name: 'HttpClient'));

    // Define HttpClientCredentials and related classes if needed
    environment.define(
        'HttpClientCredentials',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Abstract class, maybe define concrete implementations if constructible
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

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is HttpClient) {
      switch (name) {
        // HTTP verb methods
        case 'getUrl':
          if (arguments.length != 1 || arguments[0] is! Uri) {
            throw RuntimeError('getUrl requires a Uri argument.');
          }
          return target.getUrl(arguments[0] as Uri);
        case 'postUrl':
          if (arguments.length != 1 || arguments[0] is! Uri) {
            throw RuntimeError('postUrl requires a Uri argument.');
          }
          return target.postUrl(arguments[0] as Uri);
        case 'putUrl':
          if (arguments.length != 1 || arguments[0] is! Uri) {
            throw RuntimeError('putUrl requires a Uri argument.');
          }
          return target.putUrl(arguments[0] as Uri);
        case 'deleteUrl':
          if (arguments.length != 1 || arguments[0] is! Uri) {
            throw RuntimeError('deleteUrl requires a Uri argument.');
          }
          return target.deleteUrl(arguments[0] as Uri);
        case 'headUrl':
          if (arguments.length != 1 || arguments[0] is! Uri) {
            throw RuntimeError('headUrl requires a Uri argument.');
          }
          return target.headUrl(arguments[0] as Uri);
        case 'patchUrl':
          if (arguments.length != 1 || arguments[0] is! Uri) {
            throw RuntimeError('patchUrl requires a Uri argument.');
          }
          return target.patchUrl(arguments[0] as Uri);
        // General open methods
        case 'open':
          if (arguments.length != 3 ||
              arguments[0] is! String ||
              arguments[1] is! String ||
              arguments[2] is! String) {
            throw RuntimeError(
                'open requires method, host, and path arguments.');
          }
          final port = namedArguments.get<int?>('port') ??
              HttpClient
                  .defaultHttpPort; // Default might depend on scheme implicitly handled by open
          return target.open(arguments[0] as String, arguments[1] as String,
              port, arguments[2] as String);
        case 'openUrl':
          if (arguments.length != 2 ||
              arguments[0] is! String ||
              arguments[1] is! Uri) {
            throw RuntimeError('openUrl requires method and Uri arguments.');
          }
          return target.openUrl(arguments[0] as String, arguments[1] as Uri);
        // Configuration getters/setters
        case 'idleTimeout':
          return target.idleTimeout;
        case 'connectionTimeout':
          return target.connectionTimeout;
        case 'maxConnectionsPerHost':
          return target.maxConnectionsPerHost;
        case 'autoUncompress':
          return target.autoUncompress;
        case 'userAgent':
          return target.userAgent;
        case 'addCredentials':
          if (arguments.length != 3 ||
              arguments[0] is! Uri ||
              arguments[1] is! String ||
              arguments[2] is! HttpClientCredentials) {
            throw RuntimeError(
                'addCredentials requires Uri, realm String, and HttpClientCredentials arguments.');
          }
          target.addCredentials(arguments[0] as Uri, arguments[1] as String,
              arguments[2] as HttpClientCredentials);
          return null;
        case 'addProxyCredentials':
          if (arguments.length != 4 ||
              arguments[0] is! String ||
              arguments[1] is! int ||
              arguments[2] is! String ||
              arguments[3] is! HttpClientCredentials) {
            throw RuntimeError(
                'addProxyCredentials requires host, port, realm, and HttpClientCredentials arguments.');
          }
          target.addProxyCredentials(
              arguments[0] as String,
              arguments[1] as int,
              arguments[2] as String,
              arguments[3] as HttpClientCredentials);
          return null;
        // Other methods
        case 'close':
          target.close(force: namedArguments.get<bool?>('force') ?? false);
          return null;
        default:
          throw RuntimeError(
              'HttpClient has no method/getter mapping for "$name"');
      }
    } else {
      switch (name) {
        // HTTP verb methods
        case 'findProxyFromEnvironment':
          if (arguments.length != 1 || arguments[0] is! Uri) {
            throw RuntimeError(
                'HttpClient.findProxyFromEnvironment requires a Uri argument.');
          }
          final environmentMap =
              namedArguments.get<Map<String, String>?>('environment');
          return HttpClient.findProxyFromEnvironment(arguments[0] as Uri,
              environment: environmentMap);
        case 'defaultHttpPort':
          return HttpClient.defaultHttpPort;
        case 'defaultHttpsPort':
          return HttpClient.defaultHttpsPort;

        default:
          throw RuntimeError(
              'HttpClient has no static method/getter mapping for "$name"');
      }
    }
  }
}

class HttpServerIo implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Define HttpServer type (used for static methods like bind)
    environment.define(
        'HttpServer',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return HttpServer;
        }, arity: 0, name: 'HttpServer'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is HttpServer) {
      // HttpServer is a Stream<HttpRequest>
      switch (name) {
        // Stream method
        case 'listen':
          final onData = arguments.get<InterpretedFunction?>(0);
          final onError = namedArguments.get<InterpretedFunction?>('onError');
          final onDone = namedArguments.get<InterpretedFunction?>('onDone');
          final cancelOnError = namedArguments.get<bool?>('cancelOnError');
          if (onData == null) {
            throw RuntimeError(
                'HttpServer.listen requires an onData callback.');
          }
          // Return the StreamSubscription
          return target.listen(
              (request) => onData
                  .call(visitor, [request]), // Pass HttpRequest to callback
              onError: onError == null
                  ? null
                  : (error, stackTrace) =>
                      onError.call(visitor, [error, stackTrace]),
              onDone: onDone == null ? null : () => onDone.call(visitor, []),
              cancelOnError: cancelOnError);
        // HttpServer specific methods/getters/setters
        case 'close':
          return target.close(
              force: namedArguments.get<bool?>('force') ?? false);
        case 'port':
          return target.port; // Getter
        case 'address':
          return target.address; // Getter
        case 'serverHeader':
          return target.serverHeader; // Getter
        case 'set:serverHeader':
          if (arguments.length != 1) {
            throw RuntimeError('serverHeader setter requires one argument.');
          }
          target.serverHeader = arguments[0] as String?;
          return null;
        case 'autoCompress':
          return target.autoCompress; // Getter
        case 'set:autoCompress':
          if (arguments.length != 1 || arguments[0] is! bool) {
            throw RuntimeError(
                'autoCompress setter requires a boolean argument.');
          }
          target.autoCompress = arguments[0] as bool;
          return null;
        case 'defaultResponseHeaders':
          return target.defaultResponseHeaders; // Getter (HttpHeaders)
        case 'connectionsInfo': // Method added later
          return target.connectionsInfo();
        // Handle other Stream methods if necessary (map, where, etc.)
        default:
          throw RuntimeError(
              'HttpServer has no method/getter mapping for "$name"');
      }
    } else {
      switch (name) {
        case 'bind':
          if (arguments.length != 2) {
            throw RuntimeError(
                'HttpServer.bind requires address and port arguments.');
          }
          final address = arguments[0]; // dynamic: String or InternetAddress
          final port = arguments[1] as int;
          final backlog = namedArguments.get<int?>('backlog') ?? 0;
          final v6Only = namedArguments.get<bool?>('v6Only') ?? false;
          final shared = namedArguments.get<bool?>('shared') ?? false;
          return HttpServer.bind(address, port,
              backlog: backlog, v6Only: v6Only, shared: shared);

        case 'bindSecure':
          if (arguments.length != 3) {
            throw RuntimeError(
                'HttpServer.bindSecure requires address, port, and SecurityContext arguments.');
          }
          final address = arguments[0]; // dynamic: String or InternetAddress
          final port = arguments[1] as int;
          final context = arguments[2] as SecurityContext;
          final backlog = namedArguments.get<int?>('backlog') ?? 0;
          final v6Only = namedArguments.get<bool?>('v6Only') ?? false;
          final shared = namedArguments.get<bool?>('shared') ?? false;
          final requestClientCertificate =
              namedArguments.get<bool?>('requestClientCertificate') ?? false;
          return HttpServer.bindSecure(address, port, context,
              backlog: backlog,
              v6Only: v6Only,
              requestClientCertificate: requestClientCertificate,
              shared: shared);

        default:
          throw RuntimeError(
              'HttpServer has no static method/getter mapping for "$name"');
      }
    }
  }
}

class HttpClientRequestIo implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Define type (usually obtained from HttpClient methods)
    environment.define(
        'HttpClientRequest',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return HttpClientRequest;
        }, arity: 0, name: 'HttpClientRequest'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is HttpClientRequest) {
      // HttpClientRequest extends IOSink
      switch (name) {
        // Getters
        case 'headers':
          return target.headers;
        case 'method':
          return target.method;
        case 'uri':
          return target.uri;
        case 'connectionInfo':
          return target.connectionInfo;
        case 'cookies':
          return target.cookies; // List<Cookie>
        case 'contentLength':
          return target.contentLength;
        case 'encoding':
          return target.encoding;
        case 'followRedirects':
          return target.followRedirects;
        case 'maxRedirects':
          return target.maxRedirects;
        case 'persistentConnection':
          return target.persistentConnection;
        case 'done':
          return target.done; // Future<HttpClientResponse>

        // Setters
        case 'set:contentLength':
          if (arguments.length != 1 || arguments[0] is! int) {
            throw RuntimeError(
                'contentLength setter requires an int argument.');
          }
          target.contentLength = arguments[0] as int;
          return null;
        case 'set:encoding':
          if (arguments.length != 1 || arguments[0] is! Encoding) {
            throw RuntimeError(
                'encoding setter requires an Encoding argument.');
          }
          target.encoding = arguments[0] as Encoding;
          return null;
        case 'set:followRedirects':
          if (arguments.length != 1 || arguments[0] is! bool) {
            throw RuntimeError(
                'followRedirects setter requires a bool argument.');
          }
          target.followRedirects = arguments[0] as bool;
          return null;
        case 'set:maxRedirects':
          if (arguments.length != 1 || arguments[0] is! int) {
            throw RuntimeError('maxRedirects setter requires an int argument.');
          }
          target.maxRedirects = arguments[0] as int;
          return null;
        case 'set:persistentConnection':
          if (arguments.length != 1 || arguments[0] is! bool) {
            throw RuntimeError(
                'persistentConnection setter requires a bool argument.');
          }
          target.persistentConnection = arguments[0] as bool;
          return null;

        // IOSink methods
        case 'add':
          if (arguments.length != 1 || arguments[0] is! List) {
            throw RuntimeError('add requires a List argument.');
          }
          target.add((arguments[0] as List).cast());
          return null;
        case 'write':
          target.write(arguments.get<Object?>(0));
          return null;
        case 'writeln':
          target.writeln(arguments.get<Object?>(0) ?? '');
          return null;
        case 'writeAll':
          if (arguments.isEmpty || arguments[0] is! Iterable) {
            throw RuntimeError('writeAll requires an Iterable argument.');
          }
          target.writeAll(arguments[0] as Iterable<dynamic>,
              arguments.get<String?>(1) ?? '');
          return null;
        case 'writeCharCode':
          if (arguments.length != 1 || arguments[0] is! int) {
            throw RuntimeError('writeCharCode requires an int argument.');
          }
          target.writeCharCode(arguments[0] as int);
          return null;
        case 'addStream':
          if (arguments.length != 1 || arguments[0] is! Stream) {
            throw RuntimeError('addStream requires a Stream argument.');
          }
          return target.addStream((arguments[0] as Stream).cast());
        case 'addError':
          if (arguments.isEmpty) {
            throw RuntimeError(
                'addError requires at least one argument (error).');
          }
          target.addError(arguments[0]!, arguments.get<StackTrace?>(1));
          return null;
        case 'flush':
          return target.flush(); // Future<void>
        case 'close':
          return target.close(); // Future<HttpClientResponse>

        default:
          throw RuntimeError(
              'HttpClientRequest has no method/getter/setter mapping for "$name"');
      }
    } else {
      throw RuntimeError(
          'Unsupported target for HttpClientRequestIo: ${target?.runtimeType}');
    }
  }
}

class HttpClientResponseIo implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Define type (usually obtained from HttpClientRequest.close())
    environment.define(
        'HttpClientResponse',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return HttpClientResponse;
        }, arity: 0, name: 'HttpClientResponse'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is HttpClientResponse) {
      // HttpClientResponse is a Stream<List<int>>
      switch (name) {
        // Getters
        case 'statusCode':
          return target.statusCode;
        case 'reasonPhrase':
          return target.reasonPhrase;
        case 'contentLength':
          return target.contentLength;
        case 'headers':
          return target.headers;
        case 'isRedirect':
          return target.isRedirect;
        case 'persistentConnection':
          return target.persistentConnection;
        case 'redirects':
          return target.redirects; // List<RedirectInfo>
        case 'compressionState':
          return target.compressionState;
        case 'connectionInfo':
          return target.connectionInfo;
        case 'cookies':
          return target.cookies; // List<Cookie>

        // Methods
        case 'redirect':
          if (arguments.length != 2 ||
              arguments[0] is! String ||
              arguments[1] is! Uri) {
            throw RuntimeError(
                'redirect requires method String and location Uri arguments.');
          }
          return target.redirect(arguments[0] as String,
              arguments[1] as Uri); // Future<HttpClientResponse>
        case 'detachSocket':
          return target.detachSocket(); // Future<Socket>

        // Inherited Stream methods (partial list)
        case 'listen':
          final onData = arguments.get<InterpretedFunction?>(0);
          final onError = namedArguments.get<InterpretedFunction?>('onError');
          final onDone = namedArguments.get<InterpretedFunction?>('onDone');
          final cancelOnError = namedArguments.get<bool?>('cancelOnError');
          if (onData == null) {
            throw RuntimeError('listen requires an onData callback.');
          }
          return target.listen((data) => onData.call(visitor, [data]),
              onError: onError == null
                  ? null
                  : (error, stackTrace) =>
                      onError.call(visitor, [error, stackTrace]),
              onDone: onDone == null ? null : () => onDone.call(visitor, []),
              cancelOnError: cancelOnError);
        // Add other Stream methods if needed (e.g., pipe, transform)

        default:
          throw RuntimeError(
              'HttpClientResponse has no method/getter mapping for "$name"');
      }
    } else {
      throw RuntimeError(
          'Unsupported target for HttpClientResponseIo: ${target?.runtimeType}');
    }
  }
}
