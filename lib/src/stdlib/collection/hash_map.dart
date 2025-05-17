import 'dart:collection';

import 'package:d4rt/src/bridge/registration.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/callable.dart';

void registerHashMap(Environment environment) {
  final hashMapDefinition = BridgedClassDefinition(
    nativeType: HashMap,
    name: 'HashMap',
    typeParameterCount: 2,
    constructors: {
      '': (InterpreterVisitor visitor, List<Object?> positionalArgs,
          Map<String, Object?> namedArgs) {
        if (positionalArgs.isNotEmpty) {
          throw RuntimeError(
              "Constructor HashMap() does not take positional arguments.");
        }

        return HashMap<dynamic, dynamic>();
      },
      'from': (InterpreterVisitor visitor, List<Object?> positionalArgs,
          Map<String, Object?> namedArgs) {
        if (positionalArgs.length != 1) {
          throw RuntimeError(
              "Constructor HashMap.from(Map other) expects one positional argument.");
        }
        final otherMap = positionalArgs[0];
        if (otherMap is Map) {
          return HashMap<dynamic, dynamic>.from(otherMap);
        }
        throw RuntimeError("Argument to HashMap.from must be a Map.");
      },
      'of': (InterpreterVisitor visitor, List<Object?> positionalArgs,
          Map<String, Object?> namedArgs) {
        if (positionalArgs.length != 1) {
          throw RuntimeError(
              "Constructor HashMap.of(Map other) expects one positional argument.");
        }
        final otherMap = positionalArgs[0];
        if (otherMap is Map) {
          return HashMap<dynamic, dynamic>.of(otherMap);
        }
        throw RuntimeError("Argument to HashMap.of must be a Map.");
      },
    },
    methods: {
      '[]': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is HashMap && positionalArgs.length == 1) {
          return target[positionalArgs[0]];
        }
        throw RuntimeError("Invalid arguments for HashMap[] getter");
      },
      '[]=': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is HashMap && positionalArgs.length == 2) {
          target[positionalArgs[0]] = positionalArgs[1];
          return positionalArgs[1];
        }
        throw RuntimeError("Invalid arguments for HashMap[]= setter");
      },
      'addAll': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is HashMap && positionalArgs.length == 1) {
          final otherMap = positionalArgs[0];
          if (otherMap is Map) {
            target.addAll(otherMap.cast<dynamic, dynamic>());
            return null;
          }
          throw RuntimeError("Argument to HashMap.addAll must be a Map.");
        }
        throw RuntimeError("Invalid arguments for HashMap.addAll");
      },
      'clear': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is HashMap && positionalArgs.isEmpty && namedArgs.isEmpty) {
          target.clear();
          return null;
        }
        throw RuntimeError("Invalid arguments for HashMap.clear");
      },
      'containsKey': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is HashMap && positionalArgs.length == 1) {
          return target.containsKey(positionalArgs[0]);
        }
        throw RuntimeError("Invalid arguments for HashMap.containsKey");
      },
      'containsValue': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is HashMap && positionalArgs.length == 1) {
          return target.containsValue(positionalArgs[0]);
        }
        throw RuntimeError("Invalid arguments for HashMap.containsValue");
      },
      'forEach': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is HashMap && positionalArgs.length == 1) {
          final action = positionalArgs[0];
          if (action is Callable) {
            target.forEach((key, value) {
              action.call(visitor, [key, value], {});
            });
            return null;
          }
          throw RuntimeError("Argument to HashMap.forEach must be a function.");
        }
        throw RuntimeError("Invalid arguments for HashMap.forEach");
      },
      'putIfAbsent': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is HashMap && positionalArgs.length == 2) {
          final key = positionalArgs[0];
          final ifAbsent = positionalArgs[1];
          if (ifAbsent is Callable) {
            return target.putIfAbsent(
                key, () => ifAbsent.call(visitor, [], {}));
          }
          throw RuntimeError(
              "Second argument to HashMap.putIfAbsent (ifAbsent) must be a function.");
        }
        throw RuntimeError("Invalid arguments for HashMap.putIfAbsent");
      },
      'remove': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is HashMap && positionalArgs.length == 1) {
          return target.remove(positionalArgs[0]);
        }
        throw RuntimeError("Invalid arguments for HashMap.remove");
      },
    },
    getters: {
      'length': (InterpreterVisitor? visitor, Object target) {
        if (target is HashMap) return target.length;
        throw RuntimeError("Target is not a HashMap for getter 'length'");
      },
      'isEmpty': (InterpreterVisitor? visitor, Object target) {
        if (target is HashMap) return target.isEmpty;
        throw RuntimeError("Target is not a HashMap for getter 'isEmpty'");
      },
      'isNotEmpty': (InterpreterVisitor? visitor, Object target) {
        if (target is HashMap) return target.isNotEmpty;
        throw RuntimeError("Target is not a HashMap for getter 'isNotEmpty'");
      },
      'keys': (InterpreterVisitor? visitor, Object target) {
        if (target is HashMap) return target.keys;
        throw RuntimeError("Target is not a HashMap for getter 'keys'");
      },
      'values': (InterpreterVisitor? visitor, Object target) {
        if (target is HashMap) return target.values;
        throw RuntimeError("Target is not a HashMap for getter 'values'");
      },
    },
    setters: {},
  );

  environment.defineBridge(hashMapDefinition);
}
