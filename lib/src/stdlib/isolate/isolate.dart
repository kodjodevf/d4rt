import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:d4rt/d4rt.dart';

/// Thrown when an isolate cannot be created.
class IsolateSpawnExceptionIsolate {
  static BridgedClass get definition => BridgedClass(
        nativeType: IsolateSpawnException,
        name: 'IsolateSpawnException',
        typeParameterCount: 0,
        isSubtypeOfFunc: (value) => value is IsolateSpawnException,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final message = positionalArgs[0] as String;
            return IsolateSpawnException(message);
          },
        },
        getters: {
          'message': (visitor, target) =>
              (target as IsolateSpawnException).message,
          'toString': (visitor, target) =>
              (target as IsolateSpawnException).toString(),
          'hashCode': (visitor, target) =>
              (target as IsolateSpawnException).hashCode,
          'runtimeType': (visitor, target) =>
              (target as IsolateSpawnException).runtimeType,
        },
        methods: {
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as IsolateSpawnException).toString();
          },
        },
      );
}

/// An isolated Dart execution context.
class IsolateIsolate {
  static BridgedClass get definition => BridgedClass(
        nativeType: Isolate,
        name: 'Isolate',
        typeParameterCount: 0,
        isSubtypeOfFunc: (value) => value is Isolate,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final controlPort = positionalArgs[0] as SendPort;
            final pauseCapability =
                namedArgs.get<Capability?>('pauseCapability');
            final terminateCapability =
                namedArgs.get<Capability?>('terminateCapability');
            return Isolate(controlPort,
                pauseCapability: pauseCapability,
                terminateCapability: terminateCapability);
          },
        },
        staticMethods: {
          'run': (visitor, positionalArgs, namedArgs) {
            final computation = positionalArgs[0];
            final debugName = namedArgs.get<String?>('debugName');
            return Isolate.run(() {
              if (computation is InterpretedFunction) {
                return computation.call(visitor, []);
              } else if (computation is Callable) {
                return computation.call(visitor, [], {});
              } else if (computation is Function) {
                return (computation as dynamic)();
              }
              throw RuntimeError(
                  'Isolate.run requires a Function for computation.');
            }, debugName: debugName);
          },
          'spawn': (visitor, positionalArgs, namedArgs) {
            final entryPoint = positionalArgs[0];
            positionalArgs[1]; // message (ignored in this stub implementation)
            if (entryPoint is! InterpretedFunction && entryPoint is! Callable && entryPoint is! Function) {
              throw RuntimeError(
                  'Isolate.spawn requires a Function for entryPoint.');
            }
            throw RuntimeError('Isolate.spawn not fully implemented in D4rt');
          },
          'spawnUri': (visitor, positionalArgs, namedArgs) {
            final uri = positionalArgs[0] as Uri;
            final args = positionalArgs[1] as List<String>;
            final message = positionalArgs[2];
            final paused = namedArgs.get<bool?>('paused') ?? false;
            final onExit = namedArgs.get<SendPort?>('onExit');
            final onError = namedArgs.get<SendPort?>('onError');
            final errorsAreFatal =
                namedArgs.get<bool?>('errorsAreFatal') ?? true;
            final checked = namedArgs.get<bool?>('checked');
            final environment =
                namedArgs.get<Map<String, String>?>('environment');
            final packageConfig = namedArgs.get<Uri?>('packageConfig');
            final automaticPackageResolution =
                namedArgs.get<bool?>('automaticPackageResolution') ?? false;
            final debugName = namedArgs.get<String?>('debugName');

            return Isolate.spawnUri(
              uri,
              args,
              message,
              paused: paused,
              onExit: onExit,
              onError: onError,
              errorsAreFatal: errorsAreFatal,
              checked: checked,
              environment: environment,
              packageConfig: packageConfig,
              automaticPackageResolution: automaticPackageResolution,
              debugName: debugName,
            );
          },
          'exit': (visitor, positionalArgs, namedArgs) {
            final finalMessagePort = positionalArgs.get<SendPort?>(0);
            final message = positionalArgs.get<Object?>(1);
            Isolate.exit(finalMessagePort, message);
          },
          'resolvePackageUri': (visitor, positionalArgs, namedArgs) {
            final packageUri = positionalArgs[0] as Uri;
            return Isolate.resolvePackageUri(packageUri);
          },
          'resolvePackageUriSync': (visitor, positionalArgs, namedArgs) {
            final packageUri = positionalArgs[0] as Uri;
            return Isolate.resolvePackageUriSync(packageUri);
          },
        },
        staticGetters: {
          'current': (visitor) => Isolate.current,
          'packageConfig': (visitor) => Isolate.packageConfig,
          'packageConfigSync': (visitor) => Isolate.packageConfigSync,
          'immediate': (visitor) => Isolate.immediate,
          'beforeNextEvent': (visitor) => Isolate.beforeNextEvent,
        },
        getters: {
          'controlPort': (visitor, target) => (target as Isolate).controlPort,
          'pauseCapability': (visitor, target) =>
              (target as Isolate).pauseCapability,
          'terminateCapability': (visitor, target) =>
              (target as Isolate).terminateCapability,
          'debugName': (visitor, target) => (target as Isolate).debugName,
          'errors': (visitor, target) => (target as Isolate).errors,
          'hashCode': (visitor, target) => (target as Isolate).hashCode,
          'runtimeType': (visitor, target) => (target as Isolate).runtimeType,
        },
        methods: {
          'pause': (visitor, target, positionalArgs, namedArgs) {
            final resumeCapability = positionalArgs.get<Capability?>(0);
            return (target as Isolate).pause(resumeCapability);
          },
          'resume': (visitor, target, positionalArgs, namedArgs) {
            final resumeCapability = positionalArgs[0] as Capability;
            (target as Isolate).resume(resumeCapability);
            return null;
          },
          'addOnExitListener': (visitor, target, positionalArgs, namedArgs) {
            final responsePort = positionalArgs[0] as SendPort;
            final response = namedArgs.get<Object?>('response');
            (target as Isolate)
                .addOnExitListener(responsePort, response: response);
            return null;
          },
          'removeOnExitListener': (visitor, target, positionalArgs, namedArgs) {
            final responsePort = positionalArgs[0] as SendPort;
            (target as Isolate).removeOnExitListener(responsePort);
            return null;
          },
          'setErrorsFatal': (visitor, target, positionalArgs, namedArgs) {
            final errorsAreFatal = positionalArgs[0] as bool;
            (target as Isolate).setErrorsFatal(errorsAreFatal);
            return null;
          },
          'kill': (visitor, target, positionalArgs, namedArgs) {
            final priority =
                namedArgs.get<int?>('priority') ?? Isolate.beforeNextEvent;
            (target as Isolate).kill(priority: priority);
            return null;
          },
          'ping': (visitor, target, positionalArgs, namedArgs) {
            final responsePort = positionalArgs[0] as SendPort;
            final response = namedArgs.get<Object?>('response');
            final priority =
                namedArgs.get<int?>('priority') ?? Isolate.immediate;
            (target as Isolate)
                .ping(responsePort, response: response, priority: priority);
            return null;
          },
          'addErrorListener': (visitor, target, positionalArgs, namedArgs) {
            final port = positionalArgs[0] as SendPort;
            (target as Isolate).addErrorListener(port);
            return null;
          },
          'removeErrorListener': (visitor, target, positionalArgs, namedArgs) {
            final port = positionalArgs[0] as SendPort;
            (target as Isolate).removeErrorListener(port);
            return null;
          },
        },
      );
}

/// Sends messages to its ReceivePorts.
class SendPortIsolate {
  static BridgedClass get definition => BridgedClass(
        nativeType: SendPort,
        name: 'SendPort',
        typeParameterCount: 0,
        isSubtypeOfFunc: (value) => value is SendPort,
        methods: {
          'send': (visitor, target, positionalArgs, namedArgs) {
            final message = positionalArgs[0];
            (target as SendPort).send(message);
            return null;
          },
        },
        getters: {
          'hashCode': (visitor, target) => (target as SendPort).hashCode,
          'runtimeType': (visitor, target) => (target as SendPort).runtimeType,
        },
      );
}

/// Together with SendPort, the only means of communication between isolates.
class ReceivePortIsolate {
  static BridgedClass get definition => BridgedClass(
        nativeType: ReceivePort,
        name: 'ReceivePort',
        typeParameterCount: 0,
        isSubtypeOfFunc: (value) => value is ReceivePort || value is Stream,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final debugName = positionalArgs.get<String>(0) ?? '';
            return ReceivePort(debugName);
          },
          'fromRawReceivePort': (visitor, positionalArgs, namedArgs) {
            final rawPort = positionalArgs[0] as RawReceivePort;
            return ReceivePort.fromRawReceivePort(rawPort);
          },
        },
        getters: {
          'sendPort': (visitor, target) => (target as ReceivePort).sendPort,
          'isBroadcast': (visitor, target) => (target as Stream).isBroadcast,
          'isEmpty': (visitor, target) => (target as Stream).isEmpty,
          'length': (visitor, target) => (target as Stream).length,
          'first': (visitor, target) => (target as Stream).first,
          'last': (visitor, target) => (target as Stream).last,
          'single': (visitor, target) => (target as Stream).single,
          'hashCode': (visitor, target) => (target as ReceivePort).hashCode,
          'runtimeType': (visitor, target) =>
              (target as ReceivePort).runtimeType,
        },
        methods: {
          'listen': (visitor, target, positionalArgs, namedArgs) {
            final onData = positionalArgs.get<dynamic>(0);
            final onError = namedArgs['onError'];
            final onDone = namedArgs['onDone'];
            final cancelOnError = namedArgs.get<bool?>('cancelOnError');

            void handleData(dynamic message) {
              if (onData is InterpretedFunction) {
                onData.call(visitor, [message]);
              } else if (onData is Callable) {
                onData.call(visitor, [message], {});
              } else if (onData is Function) {
                (onData as dynamic)(message);
              }
            }

            void Function(Object, [StackTrace?])? handleError;
            if (onError != null) {
              handleError = (error, [stackTrace]) {
                if (onError is InterpretedFunction) {
                  onError.call(visitor, [error]);
                } else if (onError is Callable) {
                  onError.call(visitor, [error], {});
                } else if (onError is Function) {
                  (onError as dynamic)(error);
                }
              };
            }

            void Function()? handleDone;
            if (onDone != null) {
              handleDone = () {
                if (onDone is InterpretedFunction) {
                  onDone.call(visitor, []);
                } else if (onDone is Callable) {
                  onDone.call(visitor, [], {});
                } else if (onDone is Function) {
                  (onDone as dynamic)();
                }
              };
            }

            return (target as ReceivePort).listen(
              onData == null ? null : handleData,
              onError: handleError,
              onDone: handleDone,
              cancelOnError: cancelOnError,
            );
          },
          'close': (visitor, target, positionalArgs, namedArgs) {
            (target as ReceivePort).close();
            return null;
          },
          // Stream methods
          'map': (visitor, target, positionalArgs, namedArgs) {
            final transform = positionalArgs[0];
            if (transform is! InterpretedFunction && transform is! Callable && transform is! Function) {
              throw RuntimeError(
                  'Stream.map requires a Function for transform.');
            }
            return (target as Stream).map((event) {
              if (transform is InterpretedFunction) {
                return transform.call(visitor, [event]);
              } else if (transform is Callable) {
                return transform.call(visitor, [event], {});
              } else if (transform is Function) {
                return (transform as dynamic)(event);
              }
            });
          },
          'where': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0];
            if (test is! InterpretedFunction && test is! Callable && test is! Function) {
              throw RuntimeError('Stream.where requires a Function for test.');
            }
            return (target as Stream).where((event) {
              if (test is InterpretedFunction) {
                return test.call(visitor, [event]) as bool;
              } else if (test is Callable) {
                return test.call(visitor, [event], {}) as bool;
              } else if (test is Function) {
                return (test as dynamic)(event) as bool;
              }
              return false;
            });
          },
          'take': (visitor, target, positionalArgs, namedArgs) {
            final count = positionalArgs[0] as int;
            return (target as Stream).take(count);
          },
          'skip': (visitor, target, positionalArgs, namedArgs) {
            final count = positionalArgs[0] as int;
            return (target as Stream).skip(count);
          },
        },
      );
}

/// A low-level asynchronous message receiver.
class RawReceivePortIsolate {
  static BridgedClass get definition => BridgedClass(
        nativeType: RawReceivePort,
        name: 'RawReceivePort',
        typeParameterCount: 0,
        isSubtypeOfFunc: (value) => value is RawReceivePort,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final handler = positionalArgs.get<dynamic>(0);
            final debugName = positionalArgs.get<String>(1) ?? '';
            final rawPort = RawReceivePort(null, debugName);
            if (handler != null) {
              rawPort.handler = (message) {
                if (handler is InterpretedFunction) {
                  handler.call(visitor, [message]);
                } else if (handler is Callable) {
                  handler.call(visitor, [message], {});
                } else if (handler is Function) {
                  (handler as dynamic)(message);
                }
              };
            }
            return rawPort;
          },
        },
        getters: {
          'sendPort': (visitor, target) => (target as RawReceivePort).sendPort,
          'keepIsolateAlive': (visitor, target) =>
              (target as RawReceivePort).keepIsolateAlive,
          'hashCode': (visitor, target) => (target as RawReceivePort).hashCode,
          'runtimeType': (visitor, target) =>
              (target as RawReceivePort).runtimeType,
        },
        setters: {
          'handler': (visitor, target, value) {
            if (value == null) {
              (target as RawReceivePort).handler = null;
            } else {
              (target as RawReceivePort).handler = (message) {
                if (value is InterpretedFunction) {
                  value.call(visitor!, [message]);
                } else if (value is Callable) {
                  value.call(visitor!, [message], {});
                } else if (value is Function) {
                  (value as dynamic)(message);
                }
              };
            }
          },
          'keepIsolateAlive': (visitor, target, value) {
            (target as RawReceivePort).keepIsolateAlive = value as bool;
          },
        },
        methods: {
          'close': (visitor, target, positionalArgs, namedArgs) {
            (target as RawReceivePort).close();
            return null;
          },
        },
      );
}

/// Description of an error from another isolate.
class RemoteErrorIsolate {
  static BridgedClass get definition => BridgedClass(
        nativeType: RemoteError,
        name: 'RemoteError',
        typeParameterCount: 0,
        isSubtypeOfFunc: (value) => value is RemoteError || value is Error,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final description = positionalArgs[0] as String;
            final stackDescription = positionalArgs[1] as String;
            return RemoteError(description, stackDescription);
          },
        },
        getters: {
          'stackTrace': (visitor, target) => (target as RemoteError).stackTrace,
          'toString': (visitor, target) => (target as RemoteError).toString(),
          'hashCode': (visitor, target) => (target as RemoteError).hashCode,
          'runtimeType': (visitor, target) =>
              (target as RemoteError).runtimeType,
        },
        methods: {
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as RemoteError).toString();
          },
        },
      );
}

/// An efficiently transferable sequence of byte values.
class TransferableTypedDataIsolate {
  static BridgedClass get definition => BridgedClass(
        nativeType: TransferableTypedData,
        name: 'TransferableTypedData',
        typeParameterCount: 0,
        isSubtypeOfFunc: (value) => value is TransferableTypedData,
        constructors: {
          'fromList': (visitor, positionalArgs, namedArgs) {
            final list = positionalArgs[0];
            if (list is! List) {
              throw RuntimeError(
                  'TransferableTypedData.fromList requires a List<TypedData>.');
            }

            return TransferableTypedData.fromList(
                list.toNativeList().cast<TypedData>());
          },
        },
        methods: {
          'materialize': (visitor, target, positionalArgs, namedArgs) {
            return (target as TransferableTypedData).materialize();
          },
        },
        getters: {
          'hashCode': (visitor, target) =>
              (target as TransferableTypedData).hashCode,
          'runtimeType': (visitor, target) =>
              (target as TransferableTypedData).runtimeType,
        },
      );
}
