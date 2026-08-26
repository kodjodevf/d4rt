import 'dart:developer';
import 'dart:isolate';
import 'package:d4rt/d4rt.dart';

class ServiceDeveloper {
  static BridgedClass get definition => BridgedClass(
        nativeType: Service,
        name: 'Service',
        typeParameterCount: 0,
        isSubtypeOfFunc: (value) => value is Service,
        staticMethods: {
          'getInfo': (visitor, positionalArgs, namedArgs) {
            return Service.getInfo();
          },
          'getIsolateId': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty || positionalArgs[0] is! Isolate) {
              throw RuntimeError("Service.getIsolateId expects an Isolate argument.");
            }
            return Service.getIsolateId(positionalArgs[0] as Isolate);
          },
          'controlWebServer': (visitor, positionalArgs, namedArgs) {
            final enable = namedArgs['enable'] as bool? ?? false;
            final silenceOutput = namedArgs['silenceOutput'] as bool?;
            return Service.controlWebServer(
                enable: enable, silenceOutput: silenceOutput);
          },
        },
      );
}

class ServiceExtensionResponseDeveloper {
  static BridgedClass get definition => BridgedClass(
        nativeType: ServiceExtensionResponse,
        name: 'ServiceExtensionResponse',
        typeParameterCount: 0,
        isSubtypeOfFunc: (value) => value is ServiceExtensionResponse,
        constructors: {
          'result': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty || positionalArgs[0] is! String) {
              throw RuntimeError(
                  "ServiceExtensionResponse.result expects a String result.");
            }
            return ServiceExtensionResponse.result(positionalArgs[0] as String);
          },
          'error': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length < 2 ||
                positionalArgs[0] is! int ||
                positionalArgs[1] is! String) {
              throw RuntimeError(
                  "ServiceExtensionResponse.error expects an int errorCode and a String errorDetail.");
            }
            return ServiceExtensionResponse.error(
                positionalArgs[0] as int, positionalArgs[1] as String);
          },
        },
        staticMethods: {
          'result': (visitor, positionalArgs, namedArgs) {
            return ServiceExtensionResponse.result(positionalArgs[0] as String);
          },
          'error': (visitor, positionalArgs, namedArgs) {
            return ServiceExtensionResponse.error(
                positionalArgs[0] as int, positionalArgs[1] as String);
          },
        },
        getters: {
          'result': (visitor, target) =>
              (target as ServiceExtensionResponse).result,
          'errorCode': (visitor, target) =>
              (target as ServiceExtensionResponse).errorCode,
          'errorDetail': (visitor, target) =>
              (target as ServiceExtensionResponse).errorDetail,
          'hashCode': (visitor, target) =>
              (target as ServiceExtensionResponse).hashCode,
          'runtimeType': (visitor, target) =>
              (target as ServiceExtensionResponse).runtimeType,
        },
      );
}
