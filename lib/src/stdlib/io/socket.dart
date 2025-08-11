import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:d4rt/d4rt.dart';

T? _runAction<T>(InterpreterVisitor visitor, InterpretedFunction? function,
    List<Object?> args) {
  if (function == null) return null;
  try {
    return function.call(visitor, args) as T?;
  } catch (e) {
    rethrow;
  }
}

/// Bridged implementation of dart:io Socket
class SocketIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: Socket,
        name: 'Socket',
        typeParameterCount: 0,
        staticMethods: {
          'connect': (visitor, positionalArgs, namedArgs) =>
              _connect(positionalArgs, namedArgs),
          'startConnect': (visitor, positionalArgs, namedArgs) =>
              _startConnect(positionalArgs, namedArgs),
        },
        methods: {
          'destroy': (visitor, target, positionalArgs, namedArgs) {
            (target as Socket).destroy();
            return null;
          },
          'flush': (visitor, target, positionalArgs, namedArgs) {
            return (target as Socket).flush();
          },
          'close': (visitor, target, positionalArgs, namedArgs) {
            return (target as Socket).close();
          },
          'add': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw ArgumentError('Socket.add requires data');
            }
            (target as Socket).add(positionalArgs[0] as List<int>);
            return null;
          },
          'addError': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw ArgumentError('Socket.addError requires error');
            }
            final stackTrace = positionalArgs.length > 1
                ? positionalArgs[1] as StackTrace?
                : null;
            (target as Socket).addError(positionalArgs[0]!, stackTrace);
            return null;
          },
          'transform': (visitor, target, positionalArgs, namedArgs) {
            final separator = positionalArgs[0] as StreamTransformer;
            return (target as Socket).transform(separator.cast());
          },
          'addStream': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw ArgumentError('Socket.addStream requires stream');
            }
            return (target as Socket)
                .addStream(positionalArgs[0] as Stream<List<int>>);
          },
          'write': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw ArgumentError('Socket.write requires object');
            }
            (target as Socket).write(positionalArgs[0]);
            return null;
          },
          'writeln': (visitor, target, positionalArgs, namedArgs) {
            final obj = positionalArgs.isNotEmpty ? positionalArgs[0] : '';
            (target as Socket).writeln(obj);
            return null;
          },
          'writeAll': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw ArgumentError('Socket.writeAll requires objects');
            }
            final objects = positionalArgs[0] as Iterable;
            final separator =
                positionalArgs.length > 1 ? positionalArgs[1].toString() : '';
            (target as Socket).writeAll(objects, separator);
            return null;
          },
          'writeCharCode': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw ArgumentError('Socket.writeCharCode requires charCode');
            }
            (target as Socket).writeCharCode(positionalArgs[0] as int);
            return null;
          },
          'setOption': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length < 2) {
              throw ArgumentError(
                  'Socket.setOption requires option and enabled');
            }
            return (target as Socket).setOption(
              positionalArgs[0] as SocketOption,
              positionalArgs[1] as bool,
            );
          },
          'getRawOption': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw ArgumentError('Socket.getRawOption requires option');
            }
            return (target as Socket)
                .getRawOption(positionalArgs[0] as RawSocketOption);
          },
          'setRawOption': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length < 2) {
              throw ArgumentError(
                  'Socket.setRawOption requires option and value');
            }
            (target as Socket)
                .setRawOption(positionalArgs[0] as RawSocketOption);
            return null;
          },
          'any': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            return (target as Socket).any((element) =>
                _runAction<bool>(visitor, test, [element]) == true);
          },
          'contains': (visitor, target, positionalArgs, namedArgs) {
            return (target as Socket).contains(positionalArgs[0]);
          },
          'elementAt': (visitor, target, positionalArgs, namedArgs) {
            return (target as Socket).elementAt(positionalArgs[0] as int);
          },
          'every': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            return (target as Socket).every((element) =>
                _runAction<bool>(visitor, test, [element]) == true);
          },
          'expand': (visitor, target, positionalArgs, namedArgs) {
            final toElements = positionalArgs[0] as InterpretedFunction;
            return (target as Socket).expand((element) =>
                _runAction<Iterable>(visitor, toElements, [element]) ?? []);
          },
          'firstWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            final orElse = namedArgs['orElse'] as InterpretedFunction?;
            return (target as Socket).firstWhere(
              (element) => _runAction<bool>(visitor, test, [element]) == true,
              orElse: orElse != null
                  ? () => _runAction<Uint8List>(visitor, orElse, [])!
                  : null,
            );
          },
          'fold': (visitor, target, positionalArgs, namedArgs) {
            final initialValue = positionalArgs[0];
            final combine = positionalArgs[1] as InterpretedFunction;
            return (target as Socket).fold(
                initialValue,
                (prev, element) =>
                    _runAction(visitor, combine, [prev, element]));
          },
          'forEach': (visitor, target, positionalArgs, namedArgs) {
            final action = positionalArgs[0] as InterpretedFunction;
            return (target as Socket).forEach((element) {
              _runAction<void>(visitor, action, [element]);
            });
          },
          'join': (visitor, target, positionalArgs, namedArgs) {
            final separator =
                positionalArgs.isNotEmpty ? positionalArgs[0] as String : "";
            return (target as Socket).join(separator);
          },
          'lastWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            final orElse = namedArgs['orElse'] as InterpretedFunction?;
            return (target as Socket).lastWhere(
              (element) => _runAction<bool>(visitor, test, [element]) == true,
              orElse: orElse != null
                  ? () => _runAction<Uint8List>(visitor, orElse, [])!
                  : null,
            );
          },
          'map': (visitor, target, positionalArgs, namedArgs) {
            final toElement = positionalArgs[0] as InterpretedFunction;
            return (target as Socket)
                .map((element) => _runAction(visitor, toElement, [element]));
          },
          'noSuchMethod': (visitor, target, positionalArgs, namedArgs) {
            return (target as Socket)
                .noSuchMethod(positionalArgs[0] as Invocation);
          },
          'singleWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            final orElse = namedArgs['orElse'] as InterpretedFunction?;
            return (target as Socket).singleWhere(
              (element) => _runAction<bool>(visitor, test, [element]) == true,
              orElse: orElse != null
                  ? () => _runAction<Uint8List>(visitor, orElse, [])!
                  : null,
            );
          },
          'skip': (visitor, target, positionalArgs, namedArgs) {
            return (target as Socket).skip(positionalArgs[0] as int);
          },
          'skipWhile': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            return (target as Socket).skipWhile((element) =>
                _runAction<bool>(visitor, test, [element]) == true);
          },
          'take': (visitor, target, positionalArgs, namedArgs) {
            return (target as Socket).take(positionalArgs[0] as int);
          },
          'takeWhile': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            return (target as Socket).takeWhile((element) =>
                _runAction<bool>(visitor, test, [element]) == true);
          },
          'toList': (visitor, target, positionalArgs, namedArgs) {
            return (target as Socket).toList();
          },
          'toSet': (visitor, target, positionalArgs, namedArgs) {
            return (target as Socket).toSet();
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as Socket).toString();
          },
          'where': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            return (target as Socket).where((element) =>
                _runAction<bool>(visitor, test, [element]) == true);
          },
          'listen': (visitor, target, positionalArgs, namedArgs) {
            final onData = positionalArgs[0] as InterpretedFunction?;
            final onError = namedArgs['onError'] as InterpretedFunction?;
            final onDone = namedArgs['onDone'] as InterpretedFunction?;
            final cancelOnError = namedArgs['cancelOnError'] as bool?;

            void onDataWrapper(dynamic data) =>
                _runAction<void>(visitor, onData!, [data]);
            Function? onErrorWrapper = onError == null
                ? null
                : (Object error, [StackTrace? stackTrace]) =>
                    _runAction<void>(visitor, onError, [error, stackTrace]);
            void Function()? onDoneWrapper = onDone == null
                ? null
                : () => _runAction<void>(visitor, onDone, []);

            return (target as Socket).listen(
              onData != null ? onDataWrapper : null,
              onError: onErrorWrapper,
              onDone: onDoneWrapper,
              cancelOnError: cancelOnError,
            );
          },
          'asyncMap': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty ||
                positionalArgs[0] is! InterpretedFunction) {
              throw RuntimeError(
                  'Socket.asyncMap requires a convert function.');
            }
            final convert = positionalArgs[0] as InterpretedFunction;
            return (target as Socket).asyncMap(
              (event) => _runAction(visitor, convert, [event]),
            );
          },
          'asyncExpand': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty ||
                positionalArgs[0] is! InterpretedFunction) {
              throw RuntimeError(
                  'Socket.asyncExpand requires a convert function.');
            }
            final convert = positionalArgs[0] as InterpretedFunction;
            return (target as Socket).asyncExpand<dynamic>(
              (event) {
                final result = _runAction(visitor, convert, [event]);
                return result is Stream ? result : Stream.empty();
              },
            );
          },
          'handleError': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty ||
                positionalArgs[0] is! InterpretedFunction) {
              throw RuntimeError(
                  'Socket.handleError requires an onError function.');
            }
            final onError = positionalArgs[0] as InterpretedFunction;
            final test = namedArgs['test'] as InterpretedFunction?;
            return (target as Socket).handleError(
              (error, stackTrace) =>
                  _runAction<void>(visitor, onError, [error, stackTrace]),
              test: test == null
                  ? null
                  : (error) => _runAction<bool>(visitor, test, [error]) == true,
            );
          },
          'timeout': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty || positionalArgs[0] is! Duration) {
              throw RuntimeError('Socket.timeout requires a Duration.');
            }
            final timeLimit = positionalArgs[0] as Duration;
            final onTimeout = namedArgs['onTimeout'] as InterpretedFunction?;
            return (target as Socket).timeout(
              timeLimit,
              onTimeout: onTimeout == null
                  ? null
                  : (sink) => _runAction<void>(visitor, onTimeout, [sink]),
            );
          },
          'asBroadcastStream': (visitor, target, positionalArgs, namedArgs) {
            final onListen = namedArgs['onListen'] as InterpretedFunction?;
            final onCancel = namedArgs['onCancel'] as InterpretedFunction?;
            return (target as Socket).asBroadcastStream(
              onListen: onListen == null
                  ? null
                  : (subscription) =>
                      _runAction<void>(visitor, onListen, [subscription]),
              onCancel: onCancel == null
                  ? null
                  : (subscription) =>
                      _runAction<void>(visitor, onCancel, [subscription]),
            );
          },
          'distinct': (visitor, target, positionalArgs, namedArgs) {
            final equals = positionalArgs.isNotEmpty
                ? positionalArgs[0] as InterpretedFunction?
                : null;
            if (equals == null) {
              return (target as Socket).distinct();
            } else {
              return (target as Socket).distinct((p, n) {
                final result = _runAction<dynamic>(visitor, equals, [p, n]);
                return result is bool && result;
              });
            }
          },
          'reduce': (visitor, target, positionalArgs, namedArgs) {
            final combine = positionalArgs[0] as InterpretedFunction;
            return (target as Socket).reduce(
              (previous, element) =>
                  _runAction<dynamic>(visitor, combine, [previous, element]),
            );
          },
          'pipe': (visitor, target, positionalArgs, namedArgs) {
            final streamConsumer = positionalArgs[0];
            if (streamConsumer is! StreamConsumer) {
              throw RuntimeError(
                  'Socket.pipe requires a StreamConsumer argument.');
            }
            return (target as Socket)
                .pipe(streamConsumer as StreamConsumer<Uint8List>);
          },
          'cast': (visitor, target, positionalArgs, namedArgs) =>
              (target as Socket).cast(),
          'drain': (visitor, target, positionalArgs, namedArgs) {
            final futureValue =
                positionalArgs.isNotEmpty ? positionalArgs[0] : null;
            return (target as Socket).drain(futureValue);
          },
          '==': (visitor, target, positionalArgs, namedArgs) {
            return (target as Socket) == positionalArgs[0];
          },
        },
        getters: {
          'port': (visitor, target) => (target as Socket).port,
          'address': (visitor, target) => (target as Socket).address,
          'remotePort': (visitor, target) => (target as Socket).remotePort,
          'remoteAddress': (visitor, target) =>
              (target as Socket).remoteAddress,
          'done': (visitor, target) => (target as Socket).done,
          'isBroadcast': (visitor, target) => (target as Socket).isBroadcast,
          'first': (visitor, target) => (target as Socket).first,
          'last': (visitor, target) => (target as Socket).last,
          'single': (visitor, target) => (target as Socket).single,
          'length': (visitor, target) => (target as Socket).length,
          'isEmpty': (visitor, target) => (target as Socket).isEmpty,
          'hashCode': (visitor, target) => (target as Socket).hashCode,
          'runtimeType': (visitor, target) => (target as Socket).runtimeType,
          'encoding': (visitor, target) => (target as Socket).encoding,
        },
        setters: {
          'encoding': (visitor, target, value) {
            (target as Socket).encoding = value as Encoding;
            return;
          },
        },
      );

  static Future<Socket> _connect(
      List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) async {
    if (positionalArgs.length < 2) {
      throw ArgumentError('Socket.connect requires host and port');
    }

    final host = positionalArgs[0];
    final port = positionalArgs[1] as int;
    final sourceAddress = namedArgs['sourceAddress'];
    final sourcePort = namedArgs['sourcePort'] as int? ?? 0;
    final timeout = namedArgs['timeout'] as Duration?;

    final socket = await Socket.connect(
      host,
      port,
      sourceAddress: sourceAddress,
      sourcePort: sourcePort,
      timeout: timeout,
    );

    return socket;
  }

  static Future<ConnectionTask<Socket>> _startConnect(
      List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) {
    if (positionalArgs.length < 2) {
      throw ArgumentError('Socket.startConnect requires host and port');
    }

    final host = positionalArgs[0];
    final port = positionalArgs[1] as int;
    final sourceAddress = namedArgs['sourceAddress'];
    final sourcePort = namedArgs['sourcePort'] as int? ?? 0;

    return Socket.startConnect(
      host,
      port,
      sourceAddress: sourceAddress,
      sourcePort: sourcePort,
    );
  }
}

/// Bridged SocketOption
class SocketOptionIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: SocketOption,
        name: 'SocketOption',
        typeParameterCount: 0,
        staticGetters: {
          'tcpNoDelay': (visitor) => SocketOption.tcpNoDelay,
        },
      );
}

/// Bridged InternetAddress class
class InternetAddressIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: InternetAddress,
        name: 'InternetAddress',
        typeParameterCount: 0,
        staticMethods: {
          'lookup': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw ArgumentError('InternetAddress.lookup requires host');
            }

            final host = positionalArgs[0].toString();
            final type = namedArgs['type'] as InternetAddressType? ??
                InternetAddressType.any;

            return InternetAddress.lookup(host, type: type);
          },
          'fromRawAddress': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw ArgumentError(
                  'InternetAddress.fromRawAddress requires host');
            }

            final rawAddress = positionalArgs[0] as Uint8List;
            final type = namedArgs['type'] as InternetAddressType?;
            return InternetAddress.fromRawAddress(rawAddress, type: type);
          },
          'tryParse': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              throw ArgumentError('InternetAddress.tryParse requires adresse');
            }
            final adresse = positionalArgs[0] as String;
            return InternetAddress.tryParse(adresse);
          }
        },
        staticGetters: {
          'loopbackIPv4': (visitor) => InternetAddress.loopbackIPv4,
          'loopbackIPv6': (visitor) => InternetAddress.loopbackIPv6,
          'anyIPv4': (visitor) => InternetAddress.anyIPv4,
          'anyIPv6': (visitor) => InternetAddress.anyIPv6,
        },
        getters: {
          'host': (visitor, target) => (target as InternetAddress).host,
          'address': (visitor, target) => (target as InternetAddress).address,
          'type': (visitor, target) => (target as InternetAddress).type,
          'rawAddress': (visitor, target) =>
              (target as InternetAddress).rawAddress,
          'isLoopback': (visitor, target) =>
              (target as InternetAddress).isLoopback,
          'isLinkLocal': (visitor, target) =>
              (target as InternetAddress).isLinkLocal,
          'isMulticast': (visitor, target) =>
              (target as InternetAddress).isMulticast,
        },
      );
}

/// Bridged InternetAddress class
class InternetAddressTypeIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: InternetAddressType,
        name: 'InternetAddressType',
        typeParameterCount: 0,
        methods: {
          'lookup': (visitor, target, positionalArgs, namedArgs) {
            return (target as InternetAddressType).toString();
          },
        },
        staticGetters: {
          'IPv4': (visitor) => InternetAddressType.IPv4,
          'IPv6': (visitor) => InternetAddressType.IPv6,
          'any': (visitor) => InternetAddressType.any,
          'unix': (visitor) => InternetAddressType.unix,
        },
        getters: {
          'host': (visitor, target) => (target as InternetAddressType).name,
          'address': (visitor, target) =>
              (target as InternetAddressType).hashCode,
          'type': (visitor, target) =>
              (target as InternetAddressType).runtimeType,
        },
      );
}

/// Bridged InternetAddress class
class ServerSocketIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: ServerSocket,
        name: 'ServerSocket',
        typeParameterCount: 0,
        methods: {
          'close': (visitor, target, positionalArgs, namedArgs) {
            return (target as ServerSocket).close();
          },
          'listen': (visitor, target, positionalArgs, namedArgs) {
            final onData = positionalArgs[0] as InterpretedFunction;
            final onError = namedArgs['onError'] as InterpretedFunction?;
            final onDone = namedArgs['onDone'] as InterpretedFunction?;
            final cancelOnError = namedArgs['cancelOnError'] as bool? ?? false;

            void onDataWrapper(Socket socket) =>
                _runAction<void>(visitor, onData, [socket]);
            Function? onErrorWrapper = onError == null
                ? null
                : (Object error, [StackTrace? stackTrace]) =>
                    _runAction<void>(visitor, onError, [error, stackTrace]);
            void Function()? onDoneWrapper = onDone == null
                ? null
                : () => _runAction<void>(visitor, onDone, []);

            return (target as ServerSocket).listen(
              onDataWrapper,
              onError: onErrorWrapper,
              onDone: onDoneWrapper,
              cancelOnError: cancelOnError,
            );
          },
          'any': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            return (target as ServerSocket).any((element) =>
                _runAction<bool>(visitor, test, [element]) == true);
          },
          'contains': (visitor, target, positionalArgs, namedArgs) {
            return (target as ServerSocket).contains(positionalArgs[0]);
          },
          'elementAt': (visitor, target, positionalArgs, namedArgs) {
            return (target as ServerSocket).elementAt(positionalArgs[0] as int);
          },
          'every': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            return (target as ServerSocket).every((element) =>
                _runAction<bool>(visitor, test, [element]) == true);
          },
          'expand': (visitor, target, positionalArgs, namedArgs) {
            final toElements = positionalArgs[0] as InterpretedFunction;
            return (target as ServerSocket).expand((element) =>
                _runAction<Iterable>(visitor, toElements, [element]) ?? []);
          },
          'firstWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            final orElse = namedArgs['orElse'] as InterpretedFunction?;
            return (target as ServerSocket).firstWhere(
              (element) => _runAction<bool>(visitor, test, [element]) == true,
              orElse: orElse != null
                  ? () => _runAction<Socket>(visitor, orElse, [])!
                  : null,
            );
          },
          'fold': (visitor, target, positionalArgs, namedArgs) {
            final initialValue = positionalArgs[0];
            final combine = positionalArgs[1] as InterpretedFunction;
            return (target as ServerSocket).fold(
                initialValue,
                (prev, element) =>
                    _runAction(visitor, combine, [prev, element]));
          },
          'forEach': (visitor, target, positionalArgs, namedArgs) {
            final action = positionalArgs[0] as InterpretedFunction;
            return (target as ServerSocket).forEach((element) {
              _runAction<void>(visitor, action, [element]);
            });
          },
          'join': (visitor, target, positionalArgs, namedArgs) {
            final separator =
                positionalArgs.isNotEmpty ? positionalArgs[0] as String : "";
            return (target as ServerSocket).join(separator);
          },
          'transform': (visitor, target, positionalArgs, namedArgs) {
            final separator = positionalArgs[0] as StreamTransformer;
            return (target as ServerSocket).transform(separator.cast());
          },
          'lastWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            final orElse = namedArgs['orElse'] as InterpretedFunction?;
            return (target as ServerSocket).lastWhere(
              (element) => _runAction<bool>(visitor, test, [element]) == true,
              orElse: orElse != null
                  ? () => _runAction<Socket>(visitor, orElse, [])!
                  : null,
            );
          },
          'map': (visitor, target, positionalArgs, namedArgs) {
            final toElement = positionalArgs[0] as InterpretedFunction;
            return (target as ServerSocket)
                .map((element) => _runAction(visitor, toElement, [element]));
          },
          'noSuchMethod': (visitor, target, positionalArgs, namedArgs) {
            return (target as ServerSocket)
                .noSuchMethod(positionalArgs[0] as Invocation);
          },
          'singleWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            final orElse = namedArgs['orElse'] as InterpretedFunction?;
            return (target as ServerSocket).singleWhere(
              (element) => _runAction<bool>(visitor, test, [element]) == true,
              orElse: orElse != null
                  ? () => _runAction<Socket>(visitor, orElse, [])!
                  : null,
            );
          },
          'skip': (visitor, target, positionalArgs, namedArgs) {
            return (target as ServerSocket).skip(positionalArgs[0] as int);
          },
          'skipWhile': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            return (target as ServerSocket).skipWhile((element) =>
                _runAction<bool>(visitor, test, [element]) == true);
          },
          'take': (visitor, target, positionalArgs, namedArgs) {
            return (target as ServerSocket).take(positionalArgs[0] as int);
          },
          'takeWhile': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            return (target as ServerSocket).takeWhile((element) =>
                _runAction<bool>(visitor, test, [element]) == true);
          },
          'toList': (visitor, target, positionalArgs, namedArgs) {
            return (target as ServerSocket).toList();
          },
          'toSet': (visitor, target, positionalArgs, namedArgs) {
            return (target as ServerSocket).toSet();
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as ServerSocket).toString();
          },
          'where': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            return (target as ServerSocket).where((element) =>
                _runAction<bool>(visitor, test, [element]) == true);
          },
          '==': (visitor, target, positionalArgs, namedArgs) {
            return (target as ServerSocket) == positionalArgs[0];
          },
        },
        staticMethods: {
          'bind': (visitor, positionalArgs, namedArgs) {
            final host = positionalArgs[0].toString();
            final port = positionalArgs[1] as int;
            final backlog = namedArgs['backlog'] as int? ?? 0;
            final v6Only = namedArgs['v6Only'] as bool? ?? false;

            return ServerSocket.bind(host, port,
                backlog: backlog, v6Only: v6Only);
          },
        },
        getters: {
          'address': (visitor, target) => (target as ServerSocket).address,
          'port': (visitor, target) => (target as ServerSocket).port,
          'hashCode': (visitor, target) => (target as ServerSocket).hashCode,
          'first': (visitor, target) => (target as ServerSocket).first,
          'isBroadcast': (visitor, target) =>
              (target as ServerSocket).isBroadcast,
          'isEmpty': (visitor, target) => (target as ServerSocket).isEmpty,
          'last': (visitor, target) => (target as ServerSocket).last,
          'length': (visitor, target) => (target as ServerSocket).length,
          'single': (visitor, target) => (target as ServerSocket).single,
        },
      );
}
