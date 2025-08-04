import 'package:d4rt/d4rt.dart';

class UnmodifiableListViewCollection {
  static BridgedClass get definition => BridgedClass(
        nativeType: UnmodifiableListView,
        name: 'UnmodifiableListView',
        typeParameterCount: 1,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1) {
              throw RuntimeError(
                  "Constructor UnmodifiableListView() expects one positional argument (the source list).");
            }
            final sourceList = positionalArgs[0];
            if (sourceList is List) {
              return UnmodifiableListView<dynamic>(sourceList);
            }
            throw RuntimeError(
                "Argument to UnmodifiableListView() must be a List.");
          },
        },
        methods: {
          '[]': (visitor, target, positionalArgs, namedArgs) {
            if (target is UnmodifiableListView && positionalArgs.length == 1) {
              return target[positionalArgs[0] as int];
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView[] getter");
          },
          '[]=': (visitor, target, positionalArgs, namedArgs) {
            throw RuntimeError(
                "Unsupported operation: Cannot modify an unmodifiable list");
          },
          'add': (visitor, target, positionalArgs, namedArgs) {
            throw RuntimeError(
                "Unsupported operation: Cannot modify an unmodifiable list");
          },
          'addAll': (visitor, target, positionalArgs, namedArgs) {
            throw RuntimeError(
                "Unsupported operation: Cannot modify an unmodifiable list");
          },
          'clear': (visitor, target, positionalArgs, namedArgs) {
            throw RuntimeError(
                "Unsupported operation: Cannot modify an unmodifiable list");
          },
          'insert': (visitor, target, positionalArgs, namedArgs) {
            throw RuntimeError(
                "Unsupported operation: Cannot modify an unmodifiable list");
          },
          'insertAll': (visitor, target, positionalArgs, namedArgs) {
            throw RuntimeError(
                "Unsupported operation: Cannot modify an unmodifiable list");
          },
          'remove': (visitor, target, positionalArgs, namedArgs) {
            throw RuntimeError(
                "Unsupported operation: Cannot modify an unmodifiable list");
          },
          'removeAt': (visitor, target, positionalArgs, namedArgs) {
            throw RuntimeError(
                "Unsupported operation: Cannot modify an unmodifiable list");
          },
          'removeLast': (visitor, target, positionalArgs, namedArgs) {
            throw RuntimeError(
                "Unsupported operation: Cannot modify an unmodifiable list");
          },
          'removeRange': (visitor, target, positionalArgs, namedArgs) {
            throw RuntimeError(
                "Unsupported operation: Cannot modify an unmodifiable list");
          },
          'removeWhere': (visitor, target, positionalArgs, namedArgs) {
            throw RuntimeError(
                "Unsupported operation: Cannot modify an unmodifiable list");
          },
          'replaceRange': (visitor, target, positionalArgs, namedArgs) {
            throw RuntimeError(
                "Unsupported operation: Cannot modify an unmodifiable list");
          },
          'retainWhere': (visitor, target, positionalArgs, namedArgs) {
            throw RuntimeError(
                "Unsupported operation: Cannot modify an unmodifiable list");
          },
          'fillRange': (visitor, target, positionalArgs, namedArgs) {
            throw RuntimeError(
                "Unsupported operation: Cannot modify an unmodifiable list");
          },
          'setAll': (visitor, target, positionalArgs, namedArgs) {
            throw RuntimeError(
                "Unsupported operation: Cannot modify an unmodifiable list");
          },
          'setRange': (visitor, target, positionalArgs, namedArgs) {
            throw RuntimeError(
                "Unsupported operation: Cannot modify an unmodifiable list");
          },
          'shuffle': (visitor, target, positionalArgs, namedArgs) {
            throw RuntimeError(
                "Unsupported operation: Cannot modify an unmodifiable list");
          },
          'sort': (visitor, target, positionalArgs, namedArgs) {
            throw RuntimeError(
                "Unsupported operation: Cannot modify an unmodifiable list");
          },
          'elementAt': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.length == 1 && positionalArgs[0] is int) {
              return t.elementAt(positionalArgs[0] as int);
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.elementAt");
          },
          'followedBy': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.length == 1 && positionalArgs[0] is Iterable) {
              return t.followedBy(positionalArgs[0] as Iterable);
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.followedBy");
          },
          'forEach': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.length == 1 &&
                positionalArgs[0] is InterpretedFunction) {
              final action = positionalArgs[0] as InterpretedFunction;
              for (var element in t) {
                action.call(visitor, [element]);
              }
              return null;
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.forEach");
          },
          'map': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.length == 1 &&
                positionalArgs[0] is InterpretedFunction) {
              final toElement = positionalArgs[0] as InterpretedFunction;
              return t.map((e) => toElement.call(visitor, [e]));
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.map");
          },
          'where': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.length == 1 &&
                positionalArgs[0] is InterpretedFunction) {
              final test = positionalArgs[0] as InterpretedFunction;
              return t.where((e) {
                final result = test.call(visitor, [e]);
                if (result is bool) return result;
                throw RuntimeError(
                    "Test function for 'where' must return a bool.");
              });
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.where");
          },
          'any': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.length == 1 &&
                positionalArgs[0] is InterpretedFunction) {
              final test = positionalArgs[0] as InterpretedFunction;
              return t.any((e) {
                final result = test.call(visitor, [e]);
                if (result is bool) return result;
                throw RuntimeError(
                    "Test function for 'any' must return a bool.");
              });
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.any");
          },
          'every': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.length == 1 &&
                positionalArgs[0] is InterpretedFunction) {
              final test = positionalArgs[0] as InterpretedFunction;
              return t.every((e) {
                final result = test.call(visitor, [e]);
                if (result is bool) return result;
                throw RuntimeError(
                    "Test function for 'every' must return a bool.");
              });
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.every");
          },
          'contains': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.length == 1) {
              return t.contains(positionalArgs[0]);
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.contains");
          },
          'indexOf': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.isNotEmpty) {
              final element = positionalArgs[0];
              final startIndex = positionalArgs.length > 1
                  ? (positionalArgs[1] as int? ?? 0)
                  : 0;
              return t.indexOf(element, startIndex);
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.indexOf");
          },
          'lastIndexOf': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.isNotEmpty) {
              final element = positionalArgs[0];
              final startIndex = positionalArgs.length > 1
                  ? (positionalArgs[1] as int?)
                  : null;
              return t.lastIndexOf(element, startIndex);
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.lastIndexOf");
          },
          'join': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            String separator = "";
            if (positionalArgs.isNotEmpty) {
              separator = positionalArgs[0] as String? ?? "";
            }
            return t.join(separator);
          },
          'getRange': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.length == 2 &&
                positionalArgs[0] is int &&
                positionalArgs[1] is int) {
              return t.getRange(
                  positionalArgs[0] as int, positionalArgs[1] as int);
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.getRange");
          },
          'sublist': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.isNotEmpty && positionalArgs[0] is int) {
              final start = positionalArgs[0] as int;
              final end =
                  positionalArgs.length > 1 ? positionalArgs[1] as int? : null;
              return t.sublist(start, end);
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.sublist");
          },
          'toList': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            bool growable = namedArgs['growable'] as bool? ?? true;
            if (positionalArgs.isEmpty) {
              return t.toList(growable: growable);
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.toList");
          },
          'toSet': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.isEmpty) {
              return t.toSet();
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.toSet");
          },
          'cast': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            var castedSource = t.cast<dynamic>();
            return UnmodifiableListView(castedSource.toList());
          },
          'singleWhere': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.length == 1 &&
                positionalArgs[0] is InterpretedFunction) {
              final test = positionalArgs[0] as InterpretedFunction;
              final orElse = namedArgs['orElse'] as InterpretedFunction?;
              return t.singleWhere(
                (e) {
                  final result = test.call(visitor, [e]);
                  if (result is bool) return result;
                  throw RuntimeError(
                      "Test function for 'singleWhere' must return a bool.");
                },
                orElse: orElse == null ? null : () => orElse.call(visitor, []),
              );
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.singleWhere");
          },
          'firstWhere': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.length == 1 &&
                positionalArgs[0] is InterpretedFunction) {
              final test = positionalArgs[0] as InterpretedFunction;
              final orElse = namedArgs['orElse'] as InterpretedFunction?;
              return t.firstWhere(
                (e) {
                  final result = test.call(visitor, [e]);
                  if (result is bool) return result;
                  throw RuntimeError(
                      "Test function for 'firstWhere' must return a bool.");
                },
                orElse: orElse == null ? null : () => orElse.call(visitor, []),
              );
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.firstWhere");
          },
          'lastWhere': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.length == 1 &&
                positionalArgs[0] is InterpretedFunction) {
              final test = positionalArgs[0] as InterpretedFunction;
              final orElse = namedArgs['orElse'] as InterpretedFunction?;
              return t.lastWhere(
                (e) {
                  final result = test.call(visitor, [e]);
                  if (result is bool) return result;
                  throw RuntimeError(
                      "Test function for 'lastWhere' must return a bool.");
                },
                orElse: orElse == null ? null : () => orElse.call(visitor, []),
              );
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.lastWhere");
          },
          'skip': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.length == 1 && positionalArgs[0] is int) {
              return t.skip(positionalArgs[0] as int);
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.skip");
          },
          'take': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.length == 1 && positionalArgs[0] is int) {
              return t.take(positionalArgs[0] as int);
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.take");
          },
          'skipWhile': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.length == 1 &&
                positionalArgs[0] is InterpretedFunction) {
              final test = positionalArgs[0] as InterpretedFunction;
              return t.skipWhile((e) {
                final result = test.call(visitor, [e]);
                if (result is bool) return result;
                throw RuntimeError(
                    "Test function for 'skipWhile' must return a bool.");
              });
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.skipWhile");
          },
          'takeWhile': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.length == 1 &&
                positionalArgs[0] is InterpretedFunction) {
              final test = positionalArgs[0] as InterpretedFunction;
              return t.takeWhile((e) {
                final result = test.call(visitor, [e]);
                if (result is bool) return result;
                throw RuntimeError(
                    "Test function for 'takeWhile' must return a bool.");
              });
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.takeWhile");
          },
          'expand': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.length == 1 &&
                positionalArgs[0] is InterpretedFunction) {
              final toElements = positionalArgs[0] as InterpretedFunction;
              return t.expand((e) {
                final result = toElements.call(visitor, [e]);
                if (result is Iterable) return result;
                throw RuntimeError(
                    "Function for 'expand' must return an Iterable.");
              });
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.expand");
          },
          'fold': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.length == 2 &&
                positionalArgs[1] is InterpretedFunction) {
              final initialValue = positionalArgs[0];
              final combine = positionalArgs[1] as InterpretedFunction;
              return t.fold(
                  initialValue, (prev, e) => combine.call(visitor, [prev, e]));
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.fold");
          },
          'reduce': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.length == 1 &&
                positionalArgs[0] is InterpretedFunction) {
              final combine = positionalArgs[0] as InterpretedFunction;
              return t.reduce((prev, e) => combine.call(visitor, [prev, e]));
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.reduce");
          },
          'asMap': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.isEmpty && namedArgs.isEmpty) {
              return t.asMap();
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.asMap");
          },
          'reversed': (visitor, target, positionalArgs, namedArgs) {
            final t = target as UnmodifiableListView;
            if (positionalArgs.isEmpty && namedArgs.isEmpty) {
              return t.reversed;
            }
            throw RuntimeError(
                "Invalid arguments for UnmodifiableListView.reversed");
          },
        },
        getters: {
          'length': (visitor, target) {
            if (target is UnmodifiableListView) return target.length;
            throw RuntimeError(
                "Target is not an UnmodifiableListView for getter 'length'");
          },
          'isEmpty': (visitor, target) {
            if (target is UnmodifiableListView) return target.isEmpty;
            throw RuntimeError(
                "Target is not an UnmodifiableListView for getter 'isEmpty'");
          },
          'isNotEmpty': (visitor, target) {
            if (target is UnmodifiableListView) return target.isNotEmpty;
            throw RuntimeError(
                "Target is not an UnmodifiableListView for getter 'isNotEmpty'");
          },
          'first': (visitor, target) {
            if (target is UnmodifiableListView) {
              if (target.isEmpty) {
                throw RuntimeError(
                    "UnmodifiableListView is empty (for getter 'first').");
              }
              return target.first;
            }
            throw RuntimeError(
                "Target is not an UnmodifiableListView for getter 'first'");
          },
          'last': (visitor, target) {
            if (target is UnmodifiableListView) {
              if (target.isEmpty) {
                throw RuntimeError(
                    "UnmodifiableListView is empty (for getter 'last').");
              }
              return target.last;
            }
            throw RuntimeError(
                "Target is not an UnmodifiableListView for getter 'last'");
          },
          'single': (visitor, target) {
            if (target is UnmodifiableListView) {
              if (target.length != 1) {
                if (target.isEmpty) {
                  throw RuntimeError(
                      "UnmodifiableListView is empty (for getter 'single').");
                } else {
                  throw RuntimeError(
                      "UnmodifiableListView has more than one element (for getter 'single').");
                }
              }
              return target.single;
            }
            throw RuntimeError(
                "Target is not an UnmodifiableListView for getter 'single'");
          },
          'iterator': (visitor, target) {
            if (target is UnmodifiableListView) return target.iterator;
            throw RuntimeError(
                "Target is not an UnmodifiableListView for getter 'iterator'");
          },
          'reversed': (visitor, target) {
            if (target is UnmodifiableListView) return target.reversed;
            throw RuntimeError(
                "Target is not an UnmodifiableListView for getter 'reversed'");
          },
          'hashCode': (visitor, target) {
            if (target is UnmodifiableListView) return target.hashCode;
            throw RuntimeError(
                "Target is not an UnmodifiableListView for getter 'hashCode'");
          },
          'runtimeType': (visitor, target) {
            if (target is UnmodifiableListView) return target.runtimeType;
            throw RuntimeError(
                "Target is not an UnmodifiableListView for getter 'runtimeType'");
          },
        },
        setters: {
          'length': (visitor, target, value) {
            throw RuntimeError(
                "Unsupported operation: Cannot modify an unmodifiable list");
          },
          'first': (visitor, target, value) {
            throw RuntimeError(
                "Unsupported operation: Cannot modify an unmodifiable list");
          },
          'last': (visitor, target, value) {
            throw RuntimeError(
                "Unsupported operation: Cannot modify an unmodifiable list");
          },
        },
      );
}
