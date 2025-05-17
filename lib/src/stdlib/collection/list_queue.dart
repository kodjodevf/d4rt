import 'dart:collection';

import 'package:d4rt/src/bridge/registration.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/callable.dart';

void registerListQueue(Environment environment) {
  final listQueueDefinition = BridgedClassDefinition(
    nativeType: ListQueue,
    name: 'ListQueue',
    typeParameterCount: 1,
    constructors: {
      '': (InterpreterVisitor visitor, List<Object?> positionalArgs,
          Map<String, Object?> namedArgs) {
        if (positionalArgs.length > 1) {
          throw RuntimeError(
              "Constructor ListQueue() takes at most one positional argument for initialCapacity.");
        }
        int? initialCapacity;
        if (positionalArgs.isNotEmpty) {
          if (positionalArgs[0] is int) {
            initialCapacity = positionalArgs[0] as int;
          } else if (positionalArgs[0] != null) {
            throw RuntimeError(
                "initialCapacity for ListQueue() must be an int.");
          }
        }
        return ListQueue<dynamic>(initialCapacity);
      },
      'from': (InterpreterVisitor visitor, List<Object?> positionalArgs,
          Map<String, Object?> namedArgs) {
        if (positionalArgs.length != 1) {
          throw RuntimeError(
              "Constructor ListQueue.from(Iterable elements) expects one positional argument.");
        }
        final elements = positionalArgs[0];
        if (elements is Iterable) {
          return ListQueue<dynamic>.from(elements);
        }
        throw RuntimeError("Argument to ListQueue.from must be an Iterable.");
      },
    },
    methods: {
      'add': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is ListQueue && positionalArgs.length == 1) {
          target.add(positionalArgs[0]);
          return null;
        }
        throw RuntimeError("Invalid arguments for ListQueue.add");
      },
      'addFirst': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is ListQueue && positionalArgs.length == 1) {
          target.addFirst(positionalArgs[0]);
          return null;
        }
        throw RuntimeError("Invalid arguments for ListQueue.addFirst");
      },
      'addLast': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is ListQueue && positionalArgs.length == 1) {
          target.addLast(positionalArgs[0]);
          return null;
        }
        throw RuntimeError("Invalid arguments for ListQueue.addLast");
      },
      'addAll': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is ListQueue && positionalArgs.length == 1) {
          final elements = positionalArgs[0];
          if (elements is Iterable) {
            target.addAll(elements);
            return null;
          }
          throw RuntimeError(
              "Argument to ListQueue.addAll must be an Iterable.");
        }
        throw RuntimeError("Invalid arguments for ListQueue.addAll");
      },
      'clear': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is ListQueue &&
            positionalArgs.isEmpty &&
            namedArgs.isEmpty) {
          target.clear();
          return null;
        }
        throw RuntimeError("Invalid arguments for ListQueue.clear");
      },
      'removeFirst': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is ListQueue &&
            positionalArgs.isEmpty &&
            namedArgs.isEmpty) {
          if (target.isEmpty) {
            throw RuntimeError("Cannot removeFirst from an empty ListQueue.");
          }
          return target.removeFirst();
        }
        throw RuntimeError("Invalid arguments for ListQueue.removeFirst");
      },
      'removeLast': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is ListQueue &&
            positionalArgs.isEmpty &&
            namedArgs.isEmpty) {
          if (target.isEmpty) {
            throw RuntimeError("Cannot removeLast from an empty ListQueue.");
          }
          return target.removeLast();
        }
        throw RuntimeError("Invalid arguments for ListQueue.removeLast");
      },
      'remove': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is ListQueue && positionalArgs.length == 1) {
          return target.remove(positionalArgs[0]);
        }
        throw RuntimeError("Invalid arguments for ListQueue.remove");
      },
      'forEach': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is ListQueue && positionalArgs.length == 1) {
          final action = positionalArgs[0];
          if (action is Callable) {
            for (var element in target) {
              action.call(visitor, [element], {});
            }
            return null;
          }
          throw RuntimeError(
              "Argument to ListQueue.forEach must be a function.");
        }
        throw RuntimeError("Invalid arguments for ListQueue.forEach");
      },
      'toList': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is ListQueue && positionalArgs.isEmpty) {
          bool growable = namedArgs['growable'] as bool? ?? true;
          return target.toList(growable: growable);
        }
        throw RuntimeError("Invalid arguments for ListQueue.toList");
      },
    },
    getters: {
      'length': (InterpreterVisitor? visitor, Object target) {
        if (target is ListQueue) return target.length;
        throw RuntimeError("Target is not a ListQueue for getter 'length'");
      },
      'isEmpty': (InterpreterVisitor? visitor, Object target) {
        if (target is ListQueue) return target.isEmpty;
        throw RuntimeError("Target is not a ListQueue for getter 'isEmpty'");
      },
      'isNotEmpty': (InterpreterVisitor? visitor, Object target) {
        if (target is ListQueue) return target.isNotEmpty;
        throw RuntimeError("Target is not a ListQueue for getter 'isNotEmpty'");
      },
      'first': (InterpreterVisitor? visitor, Object target) {
        if (target is ListQueue) {
          if (target.isEmpty) {
            throw RuntimeError("ListQueue is empty (for getter 'first').");
          }
          return target.first;
        }
        throw RuntimeError("Target is not a ListQueue for getter 'first'");
      },
      'last': (InterpreterVisitor? visitor, Object target) {
        if (target is ListQueue) {
          if (target.isEmpty) {
            throw RuntimeError("ListQueue is empty (for getter 'last').");
          }
          return target.last;
        }
        throw RuntimeError("Target is not a ListQueue for getter 'last'");
      },
      'single': (InterpreterVisitor? visitor, Object target) {
        if (target is ListQueue) {
          if (target.length != 1) {
            if (target.isEmpty) {
              throw RuntimeError("ListQueue is empty (for getter 'single').");
            } else {
              throw RuntimeError(
                  "ListQueue has more than one element (for getter 'single').");
            }
          }
          return target.single;
        }
        throw RuntimeError("Target is not a ListQueue for getter 'single'");
      },
      'iterator': (InterpreterVisitor? visitor, Object target) {
        if (target is ListQueue) return target.iterator;
        throw RuntimeError("Target is not a ListQueue for getter 'iterator'");
      },
    },
    setters: {},
  );

  environment.defineBridge(listQueueDefinition);
}
