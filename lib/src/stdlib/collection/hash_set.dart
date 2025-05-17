import 'dart:collection';

import 'package:d4rt/src/bridge/registration.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/callable.dart';

void registerHashSet(Environment environment) {
  final hashSetDefinition = BridgedClassDefinition(
    nativeType: HashSet,
    name: 'HashSet',
    typeParameterCount: 1,
    constructors: {
      '': (InterpreterVisitor visitor, List<Object?> positionalArgs,
          Map<String, Object?> namedArgs) {
        if (positionalArgs.isNotEmpty) {
          throw RuntimeError(
              "Constructor HashSet() does not take positional arguments.");
        }
        return HashSet<dynamic>();
      },
      'from': (InterpreterVisitor visitor, List<Object?> positionalArgs,
          Map<String, Object?> namedArgs) {
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
      'add': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is HashSet && positionalArgs.length == 1) {
          return target.add(positionalArgs[0]);
        }
        throw RuntimeError("Invalid arguments for HashSet.add");
      },
      'addAll': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is HashSet && positionalArgs.length == 1) {
          final elements = positionalArgs[0];
          if (elements is Iterable) {
            target.addAll(elements);
            return null;
          }
          throw RuntimeError("Argument to HashSet.addAll must be an Iterable.");
        }
        throw RuntimeError("Invalid arguments for HashSet.addAll");
      },
      'clear': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is HashSet && positionalArgs.isEmpty && namedArgs.isEmpty) {
          target.clear();
          return null;
        }
        throw RuntimeError("Invalid arguments for HashSet.clear");
      },
      'contains': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is HashSet && positionalArgs.length == 1) {
          return target.contains(positionalArgs[0]);
        }
        throw RuntimeError("Invalid arguments for HashSet.contains");
      },
      'containsAll': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
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
      'forEach': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is HashSet && positionalArgs.length == 1) {
          final action = positionalArgs[0];
          if (action is Callable) {
            for (var element in target) {
              action.call(visitor, [element], {});
            }
            return null;
          }
          throw RuntimeError("Argument to HashSet.forEach must be a function.");
        }
        throw RuntimeError("Invalid arguments for HashSet.forEach");
      },
      'remove': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is HashSet && positionalArgs.length == 1) {
          return target.remove(positionalArgs[0]);
        }
        throw RuntimeError("Invalid arguments for HashSet.remove");
      },
      'removeAll': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
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
      'retainAll': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
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
      'toList': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is HashSet && positionalArgs.isEmpty) {
          bool growable = namedArgs['growable'] as bool? ?? true;
          return target.toList(growable: growable);
        }
        throw RuntimeError("Invalid arguments for HashSet.toList");
      },
      'toSet': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is HashSet && positionalArgs.isEmpty && namedArgs.isEmpty) {
          return target.toSet();
        }
        throw RuntimeError("Invalid arguments for HashSet.toSet");
      },
    },
    getters: {
      'length': (InterpreterVisitor? visitor, Object target) {
        if (target is HashSet) return target.length;
        throw RuntimeError("Target is not a HashSet for getter 'length'");
      },
      'isEmpty': (InterpreterVisitor? visitor, Object target) {
        if (target is HashSet) return target.isEmpty;
        throw RuntimeError("Target is not a HashSet for getter 'isEmpty'");
      },
      'isNotEmpty': (InterpreterVisitor? visitor, Object target) {
        if (target is HashSet) return target.isNotEmpty;
        throw RuntimeError("Target is not a HashSet for getter 'isNotEmpty'");
      },
      'first': (InterpreterVisitor? visitor, Object target) {
        if (target is HashSet) {
          try {
            return target.first;
          } catch (e) {
            throw RuntimeError("HashSet is empty (for getter 'first').");
          }
        }
        throw RuntimeError("Target is not a HashSet for getter 'first'");
      },
      'last': (InterpreterVisitor? visitor, Object target) {
        if (target is HashSet) {
          try {
            return target.last;
          } catch (e) {
            throw RuntimeError("HashSet is empty (for getter 'last').");
          }
        }
        throw RuntimeError("Target is not a HashSet for getter 'last'");
      },
      'single': (InterpreterVisitor? visitor, Object target) {
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
      'iterator': (InterpreterVisitor? visitor, Object target) {
        if (target is HashSet) return target.iterator;
        throw RuntimeError("Target is not a HashSet for getter 'iterator'");
      },
    },
    setters: {},
  );

  environment.defineBridge(hashSetDefinition);
}
