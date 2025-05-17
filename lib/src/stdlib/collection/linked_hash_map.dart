import 'dart:collection';

import 'package:d4rt/src/bridge/registration.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/callable.dart';

void registerLinkedHashMap(Environment environment) {
  final linkedHashMapDefinition = BridgedClassDefinition(
    nativeType: LinkedHashMap,
    name: 'LinkedHashMap',
    typeParameterCount: 2,
    constructors: {
      '': (InterpreterVisitor visitor, List<Object?> positionalArgs,
          Map<String, Object?> namedArgs) {
        if (positionalArgs.isNotEmpty) {
          throw RuntimeError(
              "Constructor LinkedHashMap() does not take positional arguments.");
        }
        return <dynamic, dynamic>{};
      },
      'from': (InterpreterVisitor visitor, List<Object?> positionalArgs,
          Map<String, Object?> namedArgs) {
        if (positionalArgs.length != 1) {
          throw RuntimeError(
              "Constructor LinkedHashMap.from(Map other) expects one positional argument.");
        }
        final otherMap = positionalArgs[0];
        if (otherMap is Map) {
          return LinkedHashMap<dynamic, dynamic>.from(otherMap);
        }
        throw RuntimeError("Argument to LinkedHashMap.from must be a Map.");
      },
      'of': (InterpreterVisitor visitor, List<Object?> positionalArgs,
          Map<String, Object?> namedArgs) {
        if (positionalArgs.length != 1) {
          throw RuntimeError(
              "Constructor LinkedHashMap.of(Map other) expects one positional argument.");
        }
        final otherMap = positionalArgs[0];
        if (otherMap is Map) {
          return LinkedHashMap<dynamic, dynamic>.of(otherMap);
        }
        throw RuntimeError("Argument to LinkedHashMap.of must be a Map.");
      },
      'identity': (InterpreterVisitor visitor, List<Object?> positionalArgs,
          Map<String, Object?> namedArgs) {
        if (positionalArgs.isNotEmpty) {
          throw RuntimeError(
              "Constructor LinkedHashMap.identity() does not take positional arguments.");
        }
        return LinkedHashMap<dynamic, dynamic>.identity();
      },
    },
    methods: {
      '[]': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is LinkedHashMap && positionalArgs.length == 1) {
          return target[positionalArgs[0]];
        }
        throw RuntimeError("Invalid arguments for LinkedHashMap[] getter");
      },
      '[]=': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is LinkedHashMap && positionalArgs.length == 2) {
          target[positionalArgs[0]] = positionalArgs[1];
          return positionalArgs[1];
        }
        throw RuntimeError("Invalid arguments for LinkedHashMap[]= setter");
      },
      'addAll': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is LinkedHashMap && positionalArgs.length == 1) {
          final otherMap = positionalArgs[0];
          if (otherMap is Map) {
            target.addAll(otherMap.cast<dynamic, dynamic>());
            return null;
          }
          throw RuntimeError("Argument to LinkedHashMap.addAll must be a Map.");
        }
        throw RuntimeError("Invalid arguments for LinkedHashMap.addAll");
      },
      'clear': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is LinkedHashMap &&
            positionalArgs.isEmpty &&
            namedArgs.isEmpty) {
          target.clear();
          return null;
        }
        throw RuntimeError("Invalid arguments for LinkedHashMap.clear");
      },
      'containsKey': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is LinkedHashMap && positionalArgs.length == 1) {
          return target.containsKey(positionalArgs[0]);
        }
        throw RuntimeError("Invalid arguments for LinkedHashMap.containsKey");
      },
      'containsValue': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is LinkedHashMap && positionalArgs.length == 1) {
          return target.containsValue(positionalArgs[0]);
        }
        throw RuntimeError("Invalid arguments for LinkedHashMap.containsValue");
      },
      'forEach': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is LinkedHashMap && positionalArgs.length == 1) {
          final action = positionalArgs[0];
          if (action is Callable) {
            target.forEach((key, value) {
              action.call(visitor, [key, value], {});
            });
            return null;
          }
          throw RuntimeError(
              "Argument to LinkedHashMap.forEach must be a function.");
        }
        throw RuntimeError("Invalid arguments for LinkedHashMap.forEach");
      },
      'putIfAbsent': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is LinkedHashMap && positionalArgs.length == 2) {
          final key = positionalArgs[0];
          final ifAbsent = positionalArgs[1];
          if (ifAbsent is Callable) {
            return target.putIfAbsent(
                key, () => ifAbsent.call(visitor, [], {}));
          }
          throw RuntimeError(
              "Second argument to LinkedHashMap.putIfAbsent (ifAbsent) must be a function.");
        }
        throw RuntimeError("Invalid arguments for LinkedHashMap.putIfAbsent");
      },
      'remove': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is LinkedHashMap && positionalArgs.length == 1) {
          return target.remove(positionalArgs[0]);
        }
        throw RuntimeError("Invalid arguments for LinkedHashMap.remove");
      },
    },
    getters: {
      'length': (InterpreterVisitor? visitor, Object target) {
        if (target is LinkedHashMap) return target.length;
        throw RuntimeError("Target is not a LinkedHashMap for getter 'length'");
      },
      'isEmpty': (InterpreterVisitor? visitor, Object target) {
        if (target is LinkedHashMap) return target.isEmpty;
        throw RuntimeError(
            "Target is not a LinkedHashMap for getter 'isEmpty'");
      },
      'isNotEmpty': (InterpreterVisitor? visitor, Object target) {
        if (target is LinkedHashMap) return target.isNotEmpty;
        throw RuntimeError(
            "Target is not a LinkedHashMap for getter 'isNotEmpty'");
      },
      'keys': (InterpreterVisitor? visitor, Object target) {
        if (target is LinkedHashMap) return target.keys;
        throw RuntimeError("Target is not a LinkedHashMap for getter 'keys'");
      },
      'values': (InterpreterVisitor? visitor, Object target) {
        if (target is LinkedHashMap) return target.values;
        throw RuntimeError("Target is not a LinkedHashMap for getter 'values'");
      },
      'entries': (InterpreterVisitor? visitor, Object target) {
        if (target is LinkedHashMap) return target.entries;
        throw RuntimeError(
            "Target is not a LinkedHashMap for getter 'entries'");
      }
    },
    setters: {},
  );

  environment.defineBridge(linkedHashMapDefinition);
}
