import 'dart:collection';

import 'package:d4rt/src/bridge/registration.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';

void registerQueue(Environment environment) {
  final queueDefinition = BridgedClassDefinition(
    nativeType: Queue,
    name: 'Queue',
    typeParameterCount: 1,
    constructors: {
      '': (InterpreterVisitor visitor, List<Object?> positionalArgs,
          Map<String, Object?> namedArgs) {
        if (positionalArgs.isNotEmpty || namedArgs.isNotEmpty) {
          throw RuntimeError("Constructor Queue() does not take arguments.");
        }
        return Queue<dynamic>();
      },
      'from': (InterpreterVisitor visitor, List<Object?> positionalArgs,
          Map<String, Object?> namedArgs) {
        if (positionalArgs.length != 1 || namedArgs.isNotEmpty) {
          throw RuntimeError(
              "Constructor Queue.from(elements) expects one positional argument.");
        }
        final elements = positionalArgs[0];
        if (elements is Iterable) {
          return Queue<dynamic>.from(elements);
        } else if (elements == null) {
          throw RuntimeError(
              "The argument type 'Null' can't be assigned to the parameter type 'Iterable<dynamic>'.");
        }
        throw RuntimeError("Argument to Queue.from must be an Iterable.");
      },
    },
    methods: {
      'add': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is Queue &&
            positionalArgs.length == 1 &&
            namedArgs.isEmpty) {
          target.add(positionalArgs[0]);
          return null;
        }
        throw RuntimeError("Invalid arguments for Queue.add");
      },
      'removeFirst': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is Queue && positionalArgs.isEmpty && namedArgs.isEmpty) {
          if (target.isEmpty) {
            throw RuntimeError("Cannot removeFirst from an empty queue.");
          }
          return target.removeFirst();
        }
        throw RuntimeError("Invalid arguments for Queue.removeFirst");
      },
      'clear': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is Queue && positionalArgs.isEmpty && namedArgs.isEmpty) {
          target.clear();
          return null;
        }
        throw RuntimeError("Invalid arguments for Queue.clear");
      },
      'contains': (InterpreterVisitor visitor, Object target,
          List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
        if (target is Queue &&
            positionalArgs.length == 1 &&
            namedArgs.isEmpty) {
          return target.contains(positionalArgs[0]);
        }
        throw RuntimeError("Invalid arguments for Queue.contains");
      },
    },
    getters: {
      'length': (InterpreterVisitor? visitor, Object target) {
        if (target is Queue) {
          return target.length;
        }
        throw RuntimeError("Target is not a Queue for getter 'length'");
      },
      'isEmpty': (InterpreterVisitor? visitor, Object target) {
        if (target is Queue) {
          return target.isEmpty;
        }
        throw RuntimeError("Target is not a Queue for getter 'isEmpty'");
      },
      'isNotEmpty': (InterpreterVisitor? visitor, Object target) {
        if (target is Queue) {
          return target.isNotEmpty;
        }
        throw RuntimeError("Target is not a Queue for getter 'isNotEmpty'");
      },
      'first': (InterpreterVisitor? visitor, Object target) {
        if (target is Queue) {
          if (target.isEmpty) {
            throw RuntimeError("Cannot get first from an empty queue.");
          }
          return target.first;
        }
        throw RuntimeError("Target is not a Queue for getter 'first'");
      },
      'last': (InterpreterVisitor? visitor, Object target) {
        if (target is Queue) {
          if (target.isEmpty) {
            throw RuntimeError("Cannot get last from an empty queue.");
          }
          return target.last;
        }
        throw RuntimeError("Target is not a Queue for getter 'last'");
      },
    },
    setters: {},
  );
  environment.defineBridge(queueDefinition);
}
