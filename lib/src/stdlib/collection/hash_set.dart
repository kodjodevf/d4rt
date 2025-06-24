import 'dart:collection';

import 'package:d4rt/d4rt.dart';

class HashSetCollection {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: HashSet,
        name: 'HashSet',
        typeParameterCount: 1,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty) {
              throw RuntimeError(
                  "Constructor HashSet() does not take positional arguments.");
            }
            return HashSet<dynamic>();
          },
          'from': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1) {
              throw RuntimeError(
                  "Constructor HashSet.from(Iterable elements) expects one positional argument.");
            }
            final elements = positionalArgs[0];
            if (elements is Iterable) {
              return HashSet<dynamic>.from(elements);
            }
            throw RuntimeError("Argument to HashSet.from must be an Iterable.");
          },
        },
        methods: {
          'add': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              return target.add(positionalArgs[0]);
            }
            throw RuntimeError("Invalid arguments for HashSet.add");
          },
          'addAll': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              final elements = positionalArgs[0];
              if (elements is Iterable) {
                target.addAll(elements);
                return null;
              }
              throw RuntimeError(
                  "Argument to HashSet.addAll must be an Iterable.");
            }
            throw RuntimeError("Invalid arguments for HashSet.addAll");
          },
          'clear': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet &&
                positionalArgs.isEmpty &&
                namedArgs.isEmpty) {
              target.clear();
              return null;
            }
            throw RuntimeError("Invalid arguments for HashSet.clear");
          },
          'contains': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              return target.contains(positionalArgs[0]);
            }
            throw RuntimeError("Invalid arguments for HashSet.contains");
          },
          'containsAll': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              final elements = positionalArgs[0];
              if (elements is Iterable) {
                return target.containsAll(elements);
              }
              throw RuntimeError(
                  "Argument to HashSet.containsAll must be an Iterable.");
            }
            throw RuntimeError("Invalid arguments for HashSet.containsAll");
          },
          'forEach': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              final action = positionalArgs[0];
              if (action is InterpretedFunction) {
                for (var element in target) {
                  action.call(visitor, [element]);
                }
                return null;
              }
              throw RuntimeError(
                  "Argument to HashSet.forEach must be a function.");
            }
            throw RuntimeError("Invalid arguments for HashSet.forEach");
          },
          'remove': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              return target.remove(positionalArgs[0]);
            }
            throw RuntimeError("Invalid arguments for HashSet.remove");
          },
          'removeAll': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              final elements = positionalArgs[0];
              if (elements is Iterable) {
                target.removeAll(elements);
                return null;
              }
              throw RuntimeError(
                  "Argument to HashSet.removeAll must be an Iterable.");
            }
            throw RuntimeError("Invalid arguments for HashSet.removeAll");
          },
          'retainAll': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              final elements = positionalArgs[0];
              if (elements is Iterable) {
                target.retainAll(elements);
                return null;
              }
              throw RuntimeError(
                  "Argument to HashSet.retainAll must be an Iterable.");
            }
            throw RuntimeError("Invalid arguments for HashSet.retainAll");
          },
          'removeWhere': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              final test = positionalArgs[0];
              if (test is InterpretedFunction) {
                target.removeWhere((element) {
                  final result = test.call(visitor, [element]);
                  return result is bool && result;
                });
                return null;
              }
              throw RuntimeError(
                  "Argument to HashSet.removeWhere must be a function.");
            }
            throw RuntimeError("Invalid arguments for HashSet.removeWhere");
          },
          'retainWhere': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              final test = positionalArgs[0];
              if (test is InterpretedFunction) {
                target.retainWhere((element) {
                  final result = test.call(visitor, [element]);
                  return result is bool && result;
                });
                return null;
              }
              throw RuntimeError(
                  "Argument to HashSet.retainWhere must be a function.");
            }
            throw RuntimeError("Invalid arguments for HashSet.retainWhere");
          },
          'any': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              final test = positionalArgs[0];
              if (test is InterpretedFunction) {
                return target.any((element) {
                  final result = test.call(visitor, [element]);
                  return result is bool && result;
                });
              }
              throw RuntimeError("Argument to HashSet.any must be a function.");
            }
            throw RuntimeError("Invalid arguments for HashSet.any");
          },
          'every': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              final test = positionalArgs[0];
              if (test is InterpretedFunction) {
                return target.every((element) {
                  final result = test.call(visitor, [element]);
                  return result is bool && result;
                });
              }
              throw RuntimeError(
                  "Argument to HashSet.every must be a function.");
            }
            throw RuntimeError("Invalid arguments for HashSet.every");
          },
          'where': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              final test = positionalArgs[0];
              if (test is InterpretedFunction) {
                return target.where((element) {
                  final result = test.call(visitor, [element]);
                  return result is bool && result;
                });
              }
              throw RuntimeError(
                  "Argument to HashSet.where must be a function.");
            }
            throw RuntimeError("Invalid arguments for HashSet.where");
          },
          'map': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              final f = positionalArgs[0];
              if (f is InterpretedFunction) {
                return target.map((element) => f.call(visitor, [element]));
              }
              throw RuntimeError("Argument to HashSet.map must be a function.");
            }
            throw RuntimeError("Invalid arguments for HashSet.map");
          },
          'expand': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              final f = positionalArgs[0];
              if (f is InterpretedFunction) {
                return target.expand((element) {
                  final result = f.call(visitor, [element]);
                  return result is Iterable ? result : [];
                });
              }
              throw RuntimeError(
                  "Argument to HashSet.expand must be a function.");
            }
            throw RuntimeError("Invalid arguments for HashSet.expand");
          },
          'fold': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 2) {
              final initialValue = positionalArgs[0];
              final combine = positionalArgs[1];
              if (combine is InterpretedFunction) {
                return target.fold(
                    initialValue,
                    (previousValue, element) =>
                        combine.call(visitor, [previousValue, element]));
              }
              throw RuntimeError(
                  "Second argument to HashSet.fold must be a function.");
            }
            throw RuntimeError("Invalid arguments for HashSet.fold");
          },
          'reduce': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              final combine = positionalArgs[0];
              if (combine is InterpretedFunction) {
                return target.reduce((value, element) =>
                    combine.call(visitor, [value, element]));
              }
              throw RuntimeError(
                  "Argument to HashSet.reduce must be a function.");
            }
            throw RuntimeError("Invalid arguments for HashSet.reduce");
          },
          'lookup': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              return target.lookup(positionalArgs[0]);
            }
            throw RuntimeError("Invalid arguments for HashSet.lookup");
          },
          'cast': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet) {
              return target.cast<dynamic>();
            }
            throw RuntimeError("Invalid arguments for HashSet.cast");
          },
          'followedBy': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              final other = positionalArgs[0];
              if (other is Iterable) {
                return target.followedBy(other);
              }
              throw RuntimeError(
                  "Argument to HashSet.followedBy must be an Iterable.");
            }
            throw RuntimeError("Invalid arguments for HashSet.followedBy");
          },
          'take': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              final count = positionalArgs[0] as int;
              return target.take(count);
            }
            throw RuntimeError("Invalid arguments for HashSet.take");
          },
          'skip': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              final count = positionalArgs[0] as int;
              return target.skip(count);
            }
            throw RuntimeError("Invalid arguments for HashSet.skip");
          },
          'takeWhile': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              final test = positionalArgs[0];
              if (test is InterpretedFunction) {
                return target.takeWhile((element) {
                  final result = test.call(visitor, [element]);
                  return result is bool && result;
                });
              }
              throw RuntimeError(
                  "Argument to HashSet.takeWhile must be a function.");
            }
            throw RuntimeError("Invalid arguments for HashSet.takeWhile");
          },
          'skipWhile': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              final test = positionalArgs[0];
              if (test is InterpretedFunction) {
                return target.skipWhile((element) {
                  final result = test.call(visitor, [element]);
                  return result is bool && result;
                });
              }
              throw RuntimeError(
                  "Argument to HashSet.skipWhile must be a function.");
            }
            throw RuntimeError("Invalid arguments for HashSet.skipWhile");
          },
          'firstWhere': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              final test = positionalArgs[0];
              final orElse = namedArgs['orElse'] as InterpretedFunction?;
              if (test is InterpretedFunction) {
                return target.firstWhere(
                  (element) {
                    final result = test.call(visitor, [element]);
                    return result is bool && result;
                  },
                  orElse:
                      orElse == null ? null : () => orElse.call(visitor, []),
                );
              }
              throw RuntimeError(
                  "Argument to HashSet.firstWhere must be a function.");
            }
            throw RuntimeError("Invalid arguments for HashSet.firstWhere");
          },
          'lastWhere': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              final test = positionalArgs[0];
              final orElse = namedArgs['orElse'] as InterpretedFunction?;
              if (test is InterpretedFunction) {
                return target.lastWhere(
                  (element) {
                    final result = test.call(visitor, [element]);
                    return result is bool && result;
                  },
                  orElse:
                      orElse == null ? null : () => orElse.call(visitor, []),
                );
              }
              throw RuntimeError(
                  "Argument to HashSet.lastWhere must be a function.");
            }
            throw RuntimeError("Invalid arguments for HashSet.lastWhere");
          },
          'singleWhere': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              final test = positionalArgs[0];
              final orElse = namedArgs['orElse'] as InterpretedFunction?;
              if (test is InterpretedFunction) {
                return target.singleWhere(
                  (element) {
                    final result = test.call(visitor, [element]);
                    return result is bool && result;
                  },
                  orElse:
                      orElse == null ? null : () => orElse.call(visitor, []),
                );
              }
              throw RuntimeError(
                  "Argument to HashSet.singleWhere must be a function.");
            }
            throw RuntimeError("Invalid arguments for HashSet.singleWhere");
          },
          'elementAt': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.length == 1) {
              final index = positionalArgs[0] as int;
              return target.elementAt(index);
            }
            throw RuntimeError("Invalid arguments for HashSet.elementAt");
          },
          'join': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet) {
              final separator =
                  positionalArgs.isNotEmpty ? positionalArgs[0] as String : "";
              return target.join(separator);
            }
            throw RuntimeError("Invalid arguments for HashSet.join");
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet &&
                positionalArgs.isEmpty &&
                namedArgs.isEmpty) {
              return target.toString();
            }
            throw RuntimeError("Invalid arguments for HashSet.toString");
          },
          'whereType': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet &&
                positionalArgs.isEmpty &&
                namedArgs.isEmpty) {
              return target.whereType<dynamic>();
            }
            throw RuntimeError("Invalid arguments for HashSet.whereType");
          },
          'toList': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet && positionalArgs.isEmpty) {
              bool growable = namedArgs['growable'] as bool? ?? true;
              return target.toList(growable: growable);
            }
            throw RuntimeError("Invalid arguments for HashSet.toList");
          },
          'toSet': (visitor, target, positionalArgs, namedArgs) {
            if (target is HashSet &&
                positionalArgs.isEmpty &&
                namedArgs.isEmpty) {
              return target.toSet();
            }
            throw RuntimeError("Invalid arguments for HashSet.toSet");
          },
        },
        getters: {
          'length': (visitor, target) {
            if (target is HashSet) return target.length;
            throw RuntimeError("Target is not a HashSet for getter 'length'");
          },
          'isEmpty': (visitor, target) {
            if (target is HashSet) return target.isEmpty;
            throw RuntimeError("Target is not a HashSet for getter 'isEmpty'");
          },
          'isNotEmpty': (visitor, target) {
            if (target is HashSet) return target.isNotEmpty;
            throw RuntimeError(
                "Target is not a HashSet for getter 'isNotEmpty'");
          },
          'first': (visitor, target) {
            if (target is HashSet) {
              try {
                return target.first;
              } catch (e) {
                throw RuntimeError("HashSet is empty (for getter 'first').");
              }
            }
            throw RuntimeError("Target is not a HashSet for getter 'first'");
          },
          'last': (visitor, target) {
            if (target is HashSet) {
              try {
                return target.last;
              } catch (e) {
                throw RuntimeError("HashSet is empty (for getter 'last').");
              }
            }
            throw RuntimeError("Target is not a HashSet for getter 'last'");
          },
          'single': (visitor, target) {
            if (target is HashSet) {
              try {
                return target.single;
              } catch (e) {
                if (target.isEmpty) {
                  throw RuntimeError("HashSet is empty (for getter 'single').");
                } else {
                  throw RuntimeError(
                      "HashSet has more than one element (for getter 'single').");
                }
              }
            }
            throw RuntimeError("Target is not a HashSet for getter 'single'");
          },
          'iterator': (visitor, target) {
            if (target is HashSet) return target.iterator;
            throw RuntimeError("Target is not a HashSet for getter 'iterator'");
          },
          'hashCode': (visitor, target) {
            if (target is HashSet) return target.hashCode;
            throw RuntimeError("Target is not a HashSet for getter 'hashCode'");
          },
          'runtimeType': (visitor, target) {
            if (target is HashSet) return target.runtimeType;
            throw RuntimeError(
                "Target is not a HashSet for getter 'runtimeType'");
          },
        },
      );
}
