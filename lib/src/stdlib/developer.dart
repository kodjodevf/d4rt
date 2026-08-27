import 'dart:async';
import 'dart:developer';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/exceptions.dart';
import 'developer/timeline.dart';
import 'developer/user_tag.dart';
import 'developer/service.dart';
import 'developer/flow.dart';

export 'package:d4rt/src/environment.dart';
export 'developer/timeline.dart';
export 'developer/user_tag.dart';
export 'developer/service.dart';
export 'developer/flow.dart';

class DeveloperStdlib {
  static void register(Environment environment) {
    // Register Bridged Classes
    environment.defineBridge(TimelineDeveloper.definition);
    environment.defineBridge(TimelineTaskDeveloper.definition);
    environment.defineBridge(UserTagDeveloper.definition);
    environment.defineBridge(ServiceDeveloper.definition);
    environment.defineBridge(ServiceExtensionResponseDeveloper.definition);
    environment.defineBridge(ServiceProtocolInfoDeveloper.definition);
    environment.defineBridge(FlowDeveloper.definition);

    // Register Global Functions
    environment.define(
        'log',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          if (arguments.isEmpty || arguments[0] is! String) {
            throw RuntimeError("log requires at least one String message argument.");
          }
          final message = arguments[0] as String;
          final time = namedArguments['time'] as DateTime?;
          final sequenceNumber = namedArguments['sequenceNumber'] as int?;
          final level = namedArguments['level'] as int? ?? 0;
          final name = namedArguments['name'] as String? ?? '';
          final zone = namedArguments['zone'] as Zone?;
          final error = namedArguments['error'];
          final stackTrace = namedArguments['stackTrace'] as StackTrace?;

          log(
            message,
            time: time,
            sequenceNumber: sequenceNumber,
            level: level,
            name: name,
            zone: zone,
            error: error,
            stackTrace: stackTrace,
          );
          return null;
        }, arity: 1, name: 'log'));

    environment.define(
        'debugger',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          final when = namedArguments['when'] as bool? ?? true;
          final message = namedArguments['message'] as String?;
          return debugger(when: when, message: message);
        }, arity: 0, name: 'debugger'));

    environment.define(
        'inspect',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          if (arguments.isEmpty) {
            throw RuntimeError("inspect requires one object argument.");
          }
          return inspect(arguments[0]);
        }, arity: 1, name: 'inspect'));

    environment.define(
        'postEvent',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          if (arguments.length < 2 ||
              arguments[0] is! String ||
              arguments[1] is! Map) {
            throw RuntimeError(
                "postEvent requires a String eventKind and a Map eventData.");
          }
          final eventKind = arguments[0] as String;
          final eventData = (arguments[1] as Map).cast<String, dynamic>();
          postEvent(eventKind, eventData);
          return null;
        }, arity: 2, name: 'postEvent'));

    environment.define(
        'registerExtension',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          if (arguments.length < 2 ||
              arguments[0] is! String) {
            throw RuntimeError(
                "registerExtension requires a String method and a function handler.");
          }
          final method = arguments[0] as String;
          final handler = arguments[1];
          registerExtension(method, (methodName, parameters) async {
            Object? result;
            if (handler is InterpretedFunction) {
              result = handler.call(visitor, [methodName, parameters]);
            } else if (handler is Callable) {
              result = handler.call(visitor, [methodName, parameters], {});
            } else if (handler is Function) {
              result = (handler as dynamic)(methodName, parameters);
            }
            final resolvedResult = result is Future ? await result : result;
            if (resolvedResult is ServiceExtensionResponse) {
              return resolvedResult;
            }
            throw RuntimeError("Service extension handler must return a ServiceExtensionResponse.");
          });
          return null;
        }, arity: 2, name: 'registerExtension'));
  }
}
