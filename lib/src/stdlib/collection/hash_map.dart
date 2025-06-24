import 'dart:collection';

import 'package:d4rt/d4rt.dart';

class HashMapCollection {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: HashMap,
        name: 'HashMap',
        typeParameterCount: 2,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty) {
              throw RuntimeError(
                  "Constructor HashMap() does not take positional arguments.");
            }
            return HashMap<dynamic, dynamic>();
          },
          'from': (visitor, positionalArgs, namedArgs) {
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
          'of': (visitor, positionalArgs, namedArgs) {
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
          'identity': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty) {
              throw RuntimeError(
                  "Constructor HashMap.identity() does not take positional arguments.");
            }
            return HashMap<dynamic, dynamic>.identity();
          },
        },
        methods: {
          '[]': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashMap && positionalArgs.length == 1) {
              return target[positionalArgs[0]];
            }
            throw RuntimeError("Invalid arguments for HashMap[] getter");
          },
          '[]=': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashMap && positionalArgs.length == 2) {
              target[positionalArgs[0]] = positionalArgs[1];
              return positionalArgs[1];
            }
            throw RuntimeError("Invalid arguments for HashMap[]= setter");
          },
          'addAll': (visitor, target, positionalArgs, namedArgs) {
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
          'clear': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashMap &&
                positionalArgs.isEmpty &&
                namedArgs.isEmpty) {
              target.clear();
              return null;
            }
            throw RuntimeError("Invalid arguments for HashMap.clear");
          },
          'containsKey': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashMap && positionalArgs.length == 1) {
              return target.containsKey(positionalArgs[0]);
            }
            throw RuntimeError("Invalid arguments for HashMap.containsKey");
          },
          'containsValue': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashMap && positionalArgs.length == 1) {
              return target.containsValue(positionalArgs[0]);
            }
            throw RuntimeError("Invalid arguments for HashMap.containsValue");
          },
          'forEach': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashMap && positionalArgs.length == 1) {
              final action = positionalArgs[0];
              if (action is Callable) {
                target.forEach((key, value) {
                  action.call(visitor, [key, value], {});
                });
                return null;
              }
              throw RuntimeError(
                  "Argument to HashMap.forEach must be a function.");
            }
            throw RuntimeError("Invalid arguments for HashMap.forEach");
          },
          'putIfAbsent': (visitor, target, positionalArgs, namedArgs) {
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
          'remove': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashMap && positionalArgs.length == 1) {
              return target.remove(positionalArgs[0]);
            }
            throw RuntimeError("Invalid arguments for HashMap.remove");
          },
          'removeWhere': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashMap && positionalArgs.length == 1) {
              final test = positionalArgs[0];
              if (test is Callable) {
                target.removeWhere((key, value) {
                  final result = test.call(visitor, [key, value], {});
                  return result is bool && result;
                });
                return null;
              }
              throw RuntimeError(
                  "Argument to HashMap.removeWhere must be a function.");
            }
            throw RuntimeError("Invalid arguments for HashMap.removeWhere");
          },
          'update': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashMap && positionalArgs.length == 2) {
              final key = positionalArgs[0];
              final update = positionalArgs[1];
              final ifAbsent = namedArgs['ifAbsent'] as Callable?;
              if (update is Callable) {
                return target.update(
                    key, (value) => update.call(visitor, [value], {}),
                    ifAbsent: ifAbsent == null
                        ? null
                        : () => ifAbsent.call(visitor, [], {}));
              }
              throw RuntimeError(
                  "Second argument to HashMap.update must be a function.");
            }
            throw RuntimeError("Invalid arguments for HashMap.update");
          },
          'updateAll': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashMap && positionalArgs.length == 1) {
              final update = positionalArgs[0];
              if (update is Callable) {
                target.updateAll(
                    (key, value) => update.call(visitor, [key, value], {}));
                return null;
              }
              throw RuntimeError(
                  "Argument to HashMap.updateAll must be a function.");
            }
            throw RuntimeError("Invalid arguments for HashMap.updateAll");
          },
          'addEntries': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashMap && positionalArgs.length == 1) {
              final newEntries = positionalArgs[0];
              if (newEntries is Iterable) {
                target.addEntries(newEntries.cast());
                return null;
              }
              throw RuntimeError(
                  "Argument to HashMap.addEntries must be an Iterable.");
            }
            throw RuntimeError("Invalid arguments for HashMap.addEntries");
          },
          'cast': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashMap) {
              return target.cast<dynamic, dynamic>();
            }
            throw RuntimeError("Invalid arguments for HashMap.cast");
          },
          'map': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashMap && positionalArgs.length == 1) {
              final transform = positionalArgs[0];
              if (transform is Callable) {
                return target.map((key, value) =>
                    MapEntry(key, transform.call(visitor, [key, value], {})));
              }
              throw RuntimeError("Argument to HashMap.map must be a function.");
            }
            throw RuntimeError("Invalid arguments for HashMap.map");
          },
        },
        getters: {
          'length': (visitor, target) {
            if (target is HashMap) return target.length;
            throw RuntimeError("Target is not a HashMap for getter 'length'");
          },
          'isEmpty': (visitor, target) {
            if (target is HashMap) return target.isEmpty;
            throw RuntimeError("Target is not a HashMap for getter 'isEmpty'");
          },
          'isNotEmpty': (visitor, target) {
            if (target is HashMap) return target.isNotEmpty;
            throw RuntimeError(
                "Target is not a HashMap for getter 'isNotEmpty'");
          },
          'keys': (visitor, target) {
            if (target is HashMap) return target.keys;
            throw RuntimeError("Target is not a HashMap for getter 'keys'");
          },
          'values': (visitor, target) {
            if (target is HashMap) return target.values;
            throw RuntimeError("Target is not a HashMap for getter 'values'");
          },
          'entries': (visitor, target) {
            if (target is HashMap) return target.entries;
            throw RuntimeError("Target is not a HashMap for getter 'entries'");
          },
          'hashCode': (visitor, target) {
            if (target is HashMap) return target.hashCode;
            throw RuntimeError("Target is not a HashMap for getter 'hashCode'");
          },
          'runtimeType': (visitor, target) {
            if (target is HashMap) return target.runtimeType;
            throw RuntimeError(
                "Target is not a HashMap for getter 'runtimeType'");
          },
        },
      );
}
