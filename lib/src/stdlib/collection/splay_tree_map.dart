import 'dart:collection';
import 'package:d4rt/d4rt.dart';

class SplayTreeMapCollection {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: SplayTreeMap,
        name: 'SplayTreeMap',
        typeParameterCount: 2,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length > 1) {
              throw RuntimeError(
                  "Constructor SplayTreeMap() takes at most one positional argument for compare function.");
            }

            InterpretedFunction? compareFn;
            if (positionalArgs.isNotEmpty && positionalArgs[0] != null) {
              if (positionalArgs[0] is InterpretedFunction) {
                compareFn = positionalArgs[0] as InterpretedFunction;
              } else {
                throw RuntimeError(
                    "The 'compare' argument must be a function.");
              }
            }

            int Function(dynamic, dynamic)? actualCompare;
            if (compareFn != null) {
              actualCompare = (k1, k2) {
                final result = compareFn!.call(visitor, [k1, k2]);
                if (result is int) {
                  return result;
                }
                throw RuntimeError("Compare function must return an int.");
              };
            }
            return SplayTreeMap<dynamic, dynamic>(actualCompare);
          },
          'from': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty || positionalArgs.length > 2) {
              throw RuntimeError(
                  "Constructor SplayTreeMap.from() expects one or two positional arguments (otherMap, [compare]).");
            }
            final otherMap = positionalArgs[0];
            if (otherMap is! Map) {
              throw RuntimeError(
                  "First argument to SplayTreeMap.from must be a Map.");
            }

            InterpretedFunction? compareFn;
            if (positionalArgs.length > 1 && positionalArgs[1] != null) {
              if (positionalArgs[1] is InterpretedFunction) {
                compareFn = positionalArgs[1] as InterpretedFunction;
              } else {
                throw RuntimeError(
                    "The 'compare' argument must be a function.");
              }
            }
            int Function(dynamic, dynamic)? actualCompare;
            if (compareFn != null) {
              actualCompare = (k1, k2) {
                final result = compareFn!.call(visitor, [k1, k2]);
                if (result is int) return result;
                throw RuntimeError("Compare function must return an int.");
              };
            }
            return SplayTreeMap<dynamic, dynamic>.from(otherMap, actualCompare);
          },
          'of': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty || positionalArgs.length > 2) {
              throw RuntimeError(
                  "Constructor SplayTreeMap.of() expects one or two positional arguments (otherMap, [compare]).");
            }
            final otherMap = positionalArgs[0];
            if (otherMap is! Map) {
              throw RuntimeError(
                  "First argument to SplayTreeMap.of must be a Map.");
            }
            InterpretedFunction? compareFn;
            if (positionalArgs.length > 1 && positionalArgs[1] != null) {
              if (positionalArgs[1] is InterpretedFunction) {
                compareFn = positionalArgs[1] as InterpretedFunction;
              } else {
                throw RuntimeError(
                    "The 'compare' argument must be a function.");
              }
            }
            int Function(dynamic, dynamic)? actualCompare;
            if (compareFn != null) {
              actualCompare = (k1, k2) {
                final result = compareFn!.call(visitor, [k1, k2]);
                if (result is int) return result;
                throw RuntimeError("Compare function must return an int.");
              };
            }
            return SplayTreeMap<dynamic, dynamic>.of(
                otherMap.cast<dynamic, dynamic>(), actualCompare);
          },
        },
        methods: {
          '[]': (visitor, target, positionalArgs, namedArgs) {
            if (target is SplayTreeMap && positionalArgs.length == 1) {
              return target[positionalArgs[0]];
            }
            throw RuntimeError("Invalid arguments for SplayTreeMap[] getter");
          },
          '[]=': (visitor, target, positionalArgs, namedArgs) {
            if (target is SplayTreeMap && positionalArgs.length == 2) {
              target[positionalArgs[0]] = positionalArgs[1];
              return positionalArgs[1];
            }
            throw RuntimeError("Invalid arguments for SplayTreeMap[]= setter");
          },
          'addAll': (visitor, target, positionalArgs, namedArgs) {
            if (target is SplayTreeMap && positionalArgs.length == 1) {
              final otherMap = positionalArgs[0];
              if (otherMap is Map) {
                target.addAll(otherMap.cast<dynamic, dynamic>());
                return null;
              }
              throw RuntimeError(
                  "Argument to SplayTreeMap.addAll must be a Map.");
            }
            throw RuntimeError("Invalid arguments for SplayTreeMap.addAll");
          },
          'clear': (visitor, target, positionalArgs, namedArgs) {
            if (target is SplayTreeMap &&
                positionalArgs.isEmpty &&
                namedArgs.isEmpty) {
              target.clear();
              return null;
            }
            throw RuntimeError("Invalid arguments for SplayTreeMap.clear");
          },
          'containsKey': (visitor, target, positionalArgs, namedArgs) {
            if (target is SplayTreeMap && positionalArgs.length == 1) {
              return target.containsKey(positionalArgs[0]);
            }
            throw RuntimeError(
                "Invalid arguments for SplayTreeMap.containsKey");
          },
          'containsValue': (visitor, target, positionalArgs, namedArgs) {
            if (target is SplayTreeMap && positionalArgs.length == 1) {
              return target.containsValue(positionalArgs[0]);
            }
            throw RuntimeError(
                "Invalid arguments for SplayTreeMap.containsValue");
          },
          'forEach': (visitor, target, positionalArgs, namedArgs) {
            if (target is SplayTreeMap && positionalArgs.length == 1) {
              final action = positionalArgs[0];
              if (action is InterpretedFunction) {
                for (var entry in target.entries) {
                  action.call(visitor, [entry.key, entry.value]);
                }
                return null;
              }
              throw RuntimeError(
                  "Argument to SplayTreeMap.forEach must be a function.");
            }
            throw RuntimeError("Invalid arguments for SplayTreeMap.forEach");
          },
          'putIfAbsent': (visitor, target, positionalArgs, namedArgs) {
            if (target is SplayTreeMap && positionalArgs.length == 2) {
              final key = positionalArgs[0];
              final ifAbsent = positionalArgs[1];
              if (ifAbsent is InterpretedFunction) {
                return target.putIfAbsent(
                    key, () => ifAbsent.call(visitor, []));
              }
              throw RuntimeError(
                  "Second argument to SplayTreeMap.putIfAbsent (ifAbsent) must be a function.");
            }
            throw RuntimeError(
                "Invalid arguments for SplayTreeMap.putIfAbsent");
          },
          'remove': (visitor, target, positionalArgs, namedArgs) {
            if (target is SplayTreeMap && positionalArgs.length == 1) {
              return target.remove(positionalArgs[0]);
            }
            throw RuntimeError("Invalid arguments for SplayTreeMap.remove");
          },
          'firstKey': (visitor, target, positionalArgs, namedArgs) {
            if (target is SplayTreeMap && positionalArgs.isEmpty) {
              if (target.isEmpty) throw RuntimeError("Map is empty");
              return target.firstKey();
            }
            throw RuntimeError("Invalid arguments for SplayTreeMap.firstKey");
          },
          'lastKey': (visitor, target, positionalArgs, namedArgs) {
            if (target is SplayTreeMap && positionalArgs.isEmpty) {
              if (target.isEmpty) throw RuntimeError("Map is empty");
              return target.lastKey();
            }
            throw RuntimeError("Invalid arguments for SplayTreeMap.lastKey");
          },
        },
        getters: {
          'length': (visitor, target) {
            if (target is SplayTreeMap) return target.length;
            throw RuntimeError(
                "Target is not a SplayTreeMap for getter 'length'");
          },
          'isEmpty': (visitor, target) {
            if (target is SplayTreeMap) return target.isEmpty;
            throw RuntimeError(
                "Target is not a SplayTreeMap for getter 'isEmpty'");
          },
          'isNotEmpty': (visitor, target) {
            if (target is SplayTreeMap) return target.isNotEmpty;
            throw RuntimeError(
                "Target is not a SplayTreeMap for getter 'isNotEmpty'");
          },
          'keys': (visitor, target) {
            if (target is SplayTreeMap) return target.keys;
            throw RuntimeError(
                "Target is not a SplayTreeMap for getter 'keys'");
          },
          'values': (visitor, target) {
            if (target is SplayTreeMap) return target.values;
            throw RuntimeError(
                "Target is not a SplayTreeMap for getter 'values'");
          },
          'entries': (visitor, target) {
            if (target is SplayTreeMap) return target.entries;
            throw RuntimeError(
                "Target is not a SplayTreeMap for getter 'entries'");
          },
          'hashCode': (visitor, target) {
            if (target is SplayTreeMap) return target.hashCode;
            throw RuntimeError(
                "Target is not a SplayTreeMap for getter 'hashCode'");
          },
          'runtimeType': (visitor, target) {
            if (target is SplayTreeMap) return target.runtimeType;
            throw RuntimeError(
                "Target is not a SplayTreeMap for getter 'runtimeType'");
          },
        },
      );
}
