import 'dart:collection';

import 'package:d4rt/src/bridge/registration.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/callable.dart';

void registerSplayTreeMap(Environment environment) {
  final splayTreeMapDefinition = BridgedClassDefinition(
    nativeType: SplayTreeMap,
    name: 'SplayTreeMap',
    typeParameterCount: 2,
    constructors: {
      '': (InterpreterVisitor visitor, List<Object?> positionalArgs,
          Map<String, Object?> namedArgs) {
        if (positionalArgs.length > 1) {
          throw RuntimeError(
              "Constructor SplayTreeMap() takes at most one positional argument for compare function.");
        }

        Callable? compareFn;
        if (positionalArgs.isNotEmpty && positionalArgs[0] != null) {
          if (positionalArgs[0] is Callable) {
            compareFn = positionalArgs[0] as Callable;
          } else {
            throw RuntimeError("The 'compare' argument must be a function.");
          }
        }

        int Function(dynamic, dynamic)? actualCompare;
        if (compareFn != null) {
          actualCompare = (k1, k2) {
            final result = compareFn!.call(visitor, [k1, k2], {});
            if (result is int) {
              return result;
            }
            throw RuntimeError("Compare function must return an int.");
          };
        }
        return SplayTreeMap<dynamic, dynamic>(actualCompare);
      },
      'from': (InterpreterVisitor visitor, List<Object?> positionalArgs,
          Map<String, Object?> namedArgs) {
        if (positionalArgs.isEmpty || positionalArgs.length > 2) {
          throw RuntimeError(
              "Constructor SplayTreeMap.from() expects one or two positional arguments (otherMap, [compare]).");
        }
        final otherMap = positionalArgs[0];
        if (otherMap is! Map) {
          throw RuntimeError(
              "First argument to SplayTreeMap.from must be a Map.");
        }

        Callable? compareFn;
        if (positionalArgs.length > 1 && positionalArgs[1] != null) {
          if (positionalArgs[1] is Callable) {
            compareFn = positionalArgs[1] as Callable;
          } else {
            throw RuntimeError("The 'compare' argument must be a function.");
          }
        }
        int Function(dynamic, dynamic)? actualCompare;
        if (compareFn != null) {
          actualCompare = (k1, k2) {
            final result = compareFn!.call(visitor, [k1, k2], {});
            if (result is int) return result;
            throw RuntimeError("Compare function must return an int.");
          };
        }
        return SplayTreeMap<dynamic, dynamic>.from(otherMap, actualCompare);
      },
      'of': (InterpreterVisitor visitor, List<Object?> positionalArgs,
          Map<String, Object?> namedArgs) {
        if (positionalArgs.isEmpty || positionalArgs.length > 2) {
          throw RuntimeError(
              "Constructor SplayTreeMap.of() expects one or two positional arguments (otherMap, [compare]).");
        }
        final otherMap = positionalArgs[0];
        if (otherMap is! Map) {
          throw RuntimeError(
              "First argument to SplayTreeMap.of must be a Map.");
        }
        Callable? compareFn;
        if (positionalArgs.length > 1 && positionalArgs[1] != null) {
          if (positionalArgs[1] is Callable) {
            compareFn = positionalArgs[1] as Callable;
          } else {
            throw RuntimeError("The 'compare' argument must be a function.");
          }
        }
        int Function(dynamic, dynamic)? actualCompare;
        if (compareFn != null) {
          actualCompare = (k1, k2) {
            final result = compareFn!.call(visitor, [k1, k2], {});
            if (result is int) return result;
            throw RuntimeError("Compare function must return an int.");
          };
        }
        return SplayTreeMap<dynamic, dynamic>.of(
            otherMap.cast<dynamic, dynamic>(), actualCompare);
      },
    },
    methods: {
      '[]': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is SplayTreeMap && positionalArgs.length == 1) {
          return target[positionalArgs[0]];
        }
        throw RuntimeError("Invalid arguments for SplayTreeMap[] getter");
      },
      '[]=': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is SplayTreeMap && positionalArgs.length == 2) {
          target[positionalArgs[0]] = positionalArgs[1];
          return positionalArgs[1];
        }
        throw RuntimeError("Invalid arguments for SplayTreeMap[]= setter");
      },
      'addAll': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is SplayTreeMap && positionalArgs.length == 1) {
          final otherMap = positionalArgs[0];
          if (otherMap is Map) {
            target.addAll(otherMap.cast<dynamic, dynamic>());
            return null;
          }
          throw RuntimeError("Argument to SplayTreeMap.addAll must be a Map.");
        }
        throw RuntimeError("Invalid arguments for SplayTreeMap.addAll");
      },
      'clear': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is SplayTreeMap &&
            positionalArgs.isEmpty &&
            namedArgs.isEmpty) {
          target.clear();
          return null;
        }
        throw RuntimeError("Invalid arguments for SplayTreeMap.clear");
      },
      'containsKey': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is SplayTreeMap && positionalArgs.length == 1) {
          return target.containsKey(positionalArgs[0]);
        }
        throw RuntimeError("Invalid arguments for SplayTreeMap.containsKey");
      },
      'containsValue': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is SplayTreeMap && positionalArgs.length == 1) {
          return target.containsValue(positionalArgs[0]);
        }
        throw RuntimeError("Invalid arguments for SplayTreeMap.containsValue");
      },
      'forEach': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is SplayTreeMap && positionalArgs.length == 1) {
          final action = positionalArgs[0];
          if (action is Callable) {
            for (var entry in target.entries) {
              action.call(visitor, [entry.key, entry.value], {});
            }
            return null;
          }
          throw RuntimeError(
              "Argument to SplayTreeMap.forEach must be a function.");
        }
        throw RuntimeError("Invalid arguments for SplayTreeMap.forEach");
      },
      'putIfAbsent': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is SplayTreeMap && positionalArgs.length == 2) {
          final key = positionalArgs[0];
          final ifAbsent = positionalArgs[1];
          if (ifAbsent is Callable) {
            return target.putIfAbsent(
                key, () => ifAbsent.call(visitor, [], {}));
          }
          throw RuntimeError(
              "Second argument to SplayTreeMap.putIfAbsent (ifAbsent) must be a function.");
        }
        throw RuntimeError("Invalid arguments for SplayTreeMap.putIfAbsent");
      },
      'remove': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is SplayTreeMap && positionalArgs.length == 1) {
          return target.remove(positionalArgs[0]);
        }
        throw RuntimeError("Invalid arguments for SplayTreeMap.remove");
      },
      'firstKey': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is SplayTreeMap && positionalArgs.isEmpty) {
          if (target.isEmpty) throw RuntimeError("Map is empty");
          return target.firstKey();
        }
        throw RuntimeError("Invalid arguments for SplayTreeMap.firstKey");
      },
      'lastKey': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is SplayTreeMap && positionalArgs.isEmpty) {
          if (target.isEmpty) throw RuntimeError("Map is empty");
          return target.lastKey();
        }
        throw RuntimeError("Invalid arguments for SplayTreeMap.lastKey");
      }
    },
    getters: {
      'length': (InterpreterVisitor? visitor, Object target) {
        if (target is SplayTreeMap) return target.length;
        throw RuntimeError("Target is not a SplayTreeMap for getter 'length'");
      },
      'isEmpty': (InterpreterVisitor? visitor, Object target) {
        if (target is SplayTreeMap) return target.isEmpty;
        throw RuntimeError("Target is not a SplayTreeMap for getter 'isEmpty'");
      },
      'isNotEmpty': (InterpreterVisitor? visitor, Object target) {
        if (target is SplayTreeMap) return target.isNotEmpty;
        throw RuntimeError(
            "Target is not a SplayTreeMap for getter 'isNotEmpty'");
      },
      'keys': (InterpreterVisitor? visitor, Object target) {
        if (target is SplayTreeMap) return target.keys;
        throw RuntimeError("Target is not a SplayTreeMap for getter 'keys'");
      },
      'values': (InterpreterVisitor? visitor, Object target) {
        if (target is SplayTreeMap) return target.values;
        throw RuntimeError("Target is not a SplayTreeMap for getter 'values'");
      },
      'entries': (InterpreterVisitor? visitor, Object target) {
        if (target is SplayTreeMap) return target.entries;
        throw RuntimeError("Target is not a SplayTreeMap for getter 'entries'");
      }
    },
    setters: {},
  );

  environment.defineBridge(splayTreeMapDefinition);
}
