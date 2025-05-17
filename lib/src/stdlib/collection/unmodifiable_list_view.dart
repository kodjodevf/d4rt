import 'dart:collection';

import 'package:d4rt/src/bridge/registration.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/callable.dart';

void registerUnmodifiableListView(Environment environment) {
  final unmodifiableListViewDefinition = BridgedClassDefinition(
    nativeType: UnmodifiableListView,
    name: 'UnmodifiableListView',
    typeParameterCount: 1,
    constructors: {
      '': (InterpreterVisitor visitor, List<Object?> positionalArgs,
          Map<String, Object?> namedArgs) {
        if (positionalArgs.length != 1) {
          throw RuntimeError(
              "Constructor UnmodifiableListView() expects one positional argument (the source list).");
        }
        final sourceList = positionalArgs[0];
        if (sourceList is List) {
          return UnmodifiableListView<dynamic>(sourceList);
        }
        throw RuntimeError(
            "Argument to UnmodifiableListView() must be a List. BridgedInstance handling temporarily commented out.");
      },
    },
    methods: {
      'elementAt': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        final t = target as UnmodifiableListView;
        if (positionalArgs.length == 1 && positionalArgs[0] is int) {
          return t.elementAt(positionalArgs[0] as int);
        }
        throw RuntimeError(
            "Invalid arguments for UnmodifiableListView.elementAt");
      },
      'followedBy': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        final t = target as UnmodifiableListView;
        if (positionalArgs.length == 1 && positionalArgs[0] is Iterable) {
          return t.followedBy(positionalArgs[0] as Iterable);
        }
        throw RuntimeError(
            "Invalid arguments for UnmodifiableListView.followedBy");
      },
      'forEach': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        final t = target as UnmodifiableListView;
        if (positionalArgs.length == 1 && positionalArgs[0] is Callable) {
          final action = positionalArgs[0] as Callable;
          for (var element in t) {
            action.call(visitor, [element], {});
          }
          return null;
        }
        throw RuntimeError(
            "Invalid arguments for UnmodifiableListView.forEach");
      },
      'map': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        final t = target as UnmodifiableListView;
        if (positionalArgs.length == 1 && positionalArgs[0] is Callable) {
          final toElement = positionalArgs[0] as Callable;
          return t.map((e) => toElement.call(visitor, [e], {}));
        }
        throw RuntimeError("Invalid arguments for UnmodifiableListView.map");
      },
      'where': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        final t = target as UnmodifiableListView;
        if (positionalArgs.length == 1 && positionalArgs[0] is Callable) {
          final test = positionalArgs[0] as Callable;
          return t.where((e) {
            final result = test.call(visitor, [e], {});
            if (result is bool) return result;
            throw RuntimeError("Test function for 'where' must return a bool.");
          });
        }
        throw RuntimeError("Invalid arguments for UnmodifiableListView.where");
      },
      'any': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        final t = target as UnmodifiableListView;
        if (positionalArgs.length == 1 && positionalArgs[0] is Callable) {
          final test = positionalArgs[0] as Callable;
          return t.any((e) {
            final result = test.call(visitor, [e], {});
            if (result is bool) return result;
            throw RuntimeError("Test function for 'any' must return a bool.");
          });
        }
        throw RuntimeError("Invalid arguments for UnmodifiableListView.any");
      },
      'every': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        final t = target as UnmodifiableListView;
        if (positionalArgs.length == 1 && positionalArgs[0] is Callable) {
          final test = positionalArgs[0] as Callable;
          return t.every((e) {
            final result = test.call(visitor, [e], {});
            if (result is bool) return result;
            throw RuntimeError("Test function for 'every' must return a bool.");
          });
        }
        throw RuntimeError("Invalid arguments for UnmodifiableListView.every");
      },
      'contains': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        final t = target as UnmodifiableListView;
        if (positionalArgs.length == 1) {
          return t.contains(positionalArgs[0]);
        }
        throw RuntimeError(
            "Invalid arguments for UnmodifiableListView.contains");
      },
      'indexOf': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        final t = target as UnmodifiableListView;
        if (positionalArgs.isNotEmpty) {
          final element = positionalArgs[0];
          final startIndex =
              positionalArgs.length > 1 ? (positionalArgs[1] as int? ?? 0) : 0;
          return t.indexOf(element, startIndex);
        }
        throw RuntimeError(
            "Invalid arguments for UnmodifiableListView.indexOf");
      },
      'lastIndexOf': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        final t = target as UnmodifiableListView;
        if (positionalArgs.isNotEmpty) {
          final element = positionalArgs[0];
          final startIndex =
              positionalArgs.length > 1 ? (positionalArgs[1] as int?) : null;
          return t.lastIndexOf(element, startIndex);
        }
        throw RuntimeError(
            "Invalid arguments for UnmodifiableListView.lastIndexOf");
      },
      'join': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        final t = target as UnmodifiableListView;
        String separator = "";
        if (positionalArgs.isNotEmpty) {
          separator = positionalArgs[0] as String? ?? "";
        }
        return t.join(separator);
      },
      'getRange': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        final t = target as UnmodifiableListView;
        if (positionalArgs.length == 2 &&
            positionalArgs[0] is int &&
            positionalArgs[1] is int) {
          return t.getRange(positionalArgs[0] as int, positionalArgs[1] as int);
        }
        throw RuntimeError(
            "Invalid arguments for UnmodifiableListView.getRange");
      },
      'sublist': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        final t = target as UnmodifiableListView;
        if (positionalArgs.isNotEmpty && positionalArgs[0] is int) {
          final start = positionalArgs[0] as int;
          final end =
              positionalArgs.length > 1 ? positionalArgs[1] as int? : null;
          return t.sublist(
              start, end); // This returns a new List, which is fine.
        }
        throw RuntimeError(
            "Invalid arguments for UnmodifiableListView.sublist");
      },
      'toList': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        final t = target as UnmodifiableListView;
        bool growable = namedArgs['growable'] as bool? ?? true;
        if (positionalArgs.isEmpty) {
          return t.toList(growable: growable);
        }
        throw RuntimeError("Invalid arguments for UnmodifiableListView.toList");
      },
      'toSet': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        final t = target as UnmodifiableListView;
        if (positionalArgs.isEmpty) {
          return t.toSet();
        }
        throw RuntimeError("Invalid arguments for UnmodifiableListView.toSet");
      },
      'cast': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        final t = target as UnmodifiableListView;
        var castedSource = t.cast<dynamic>();
        return UnmodifiableListView(castedSource.toList());
      },
      'singleWhere': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        final t = target as UnmodifiableListView;
        if (positionalArgs.isNotEmpty && positionalArgs[0] is Callable) {
          final test = positionalArgs[0] as Callable;
          Object? Function()? orElseFn;
          if (namedArgs.containsKey('orElse')) {
            final orElseCallable = namedArgs['orElse'];
            if (orElseCallable is Callable) {
              orElseFn = () => orElseCallable.call(visitor, [], {});
            } else if (orElseCallable != null) {
              throw RuntimeError("'orElse' must be a function.");
            }
          }
          try {
            return t.singleWhere(
              (e) {
                final result = test.call(visitor, [e], {});
                if (result is bool) return result;
                throw RuntimeError(
                    "Test function for 'singleWhere' must return a bool.");
              },
              orElse: orElseFn,
            );
          } catch (e) {
            if (e is StateError) {
              throw RuntimeError("StateError in singleWhere: ${e.message}");
            }
            rethrow;
          }
        }
        throw RuntimeError(
            "Invalid arguments for UnmodifiableListView.singleWhere");
      },
      '[]': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        final t = target as UnmodifiableListView;
        if (positionalArgs.length == 1 && positionalArgs[0] is int) {
          return t[positionalArgs[0] as int];
        }
        throw RuntimeError(
            "Invalid arguments for UnmodifiableListView[] getter");
      },
      'add': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        throw UnsupportedError("Cannot add to an unmodifiable list");
      },
      'addAll': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        throw UnsupportedError("Cannot add to an unmodifiable list");
      },
      'clear': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        throw UnsupportedError("Cannot clear an unmodifiable list");
      },
      'fillRange': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        throw UnsupportedError("Cannot modify an unmodifiable list");
      },
      'insert': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        throw UnsupportedError("Cannot insert into an unmodifiable list");
      },
      'insertAll': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        throw UnsupportedError("Cannot insert into an unmodifiable list");
      },
      'remove': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        throw UnsupportedError("Cannot remove from an unmodifiable list");
      },
      'removeAt': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        throw UnsupportedError("Cannot remove from an unmodifiable list");
      },
      'removeLast': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        throw UnsupportedError("Cannot remove from an unmodifiable list");
      },
      'removeRange': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        throw UnsupportedError("Cannot remove from an unmodifiable list");
      },
      'removeWhere': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        throw UnsupportedError("Cannot remove from an unmodifiable list");
      },
      'replaceRange': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        throw UnsupportedError("Cannot modify an unmodifiable list");
      },
      'retainWhere': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        throw UnsupportedError("Cannot modify an unmodifiable list");
      },
      'setAll': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        throw UnsupportedError("Cannot modify an unmodifiable list");
      },
      'setRange': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        throw UnsupportedError("Cannot modify an unmodifiable list");
      },
      'shuffle': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        throw UnsupportedError("Cannot shuffle an unmodifiable list");
      },
      'sort': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        throw UnsupportedError("Cannot sort an unmodifiable list");
      },
    },
    getters: {
      'length': (InterpreterVisitor? visitor, Object target) =>
          (target as UnmodifiableListView).length,
      'isEmpty': (InterpreterVisitor? visitor, Object target) =>
          (target as UnmodifiableListView).isEmpty,
      'isNotEmpty': (InterpreterVisitor? visitor, Object target) =>
          (target as UnmodifiableListView).isNotEmpty,
      'first': (InterpreterVisitor? visitor, Object target) =>
          (target as UnmodifiableListView).first,
      'last': (InterpreterVisitor? visitor, Object target) =>
          (target as UnmodifiableListView).last,
      'single': (InterpreterVisitor? visitor, Object target) =>
          (target as UnmodifiableListView).single,
      'iterator': (InterpreterVisitor? visitor, Object target) {
        return (target as UnmodifiableListView).iterator;
      },
      'reversed': (InterpreterVisitor? visitor, Object target) {
        return (target as UnmodifiableListView).reversed;
      }
    },
    setters: {
      'length': (InterpreterVisitor? visitor, Object target, Object? value) {
        throw UnsupportedError(
            "Cannot change the length of an unmodifiable list");
      } as BridgedInstanceSetterAdapter,
      'first': (InterpreterVisitor? visitor, Object target, Object? value) {
        throw UnsupportedError(
            "Cannot change the first element of an unmodifiable list");
      } as BridgedInstanceSetterAdapter,
      'last': (InterpreterVisitor? visitor, Object target, Object? value) {
        throw UnsupportedError(
            "Cannot change the last element of an unmodifiable list");
      } as BridgedInstanceSetterAdapter,
    },
  );

  unmodifiableListViewDefinition.methods['[]='] = (InterpreterVisitor? visitor,
      Object target,
      List<Object?> positionalArgs,
      Map<String, Object?> namedArgs) {
    throw UnsupportedError("Cannot modify an unmodifiable list by index");
  };

  environment.defineBridge(unmodifiableListViewDefinition);
}
