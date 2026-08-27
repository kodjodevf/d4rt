import 'dart:collection';
import 'package:d4rt/d4rt.dart';

class DoubleLinkedQueueCollection {
  static BridgedClass get definition => BridgedClass(
        nativeType: DoubleLinkedQueue,
        name: 'DoubleLinkedQueue',
        typeParameterCount: 1,
        isSubtypeOfFunc: (value) => value is DoubleLinkedQueue,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            return DoubleLinkedQueue<dynamic>();
          },
          'from': (visitor, positionalArgs, namedArgs) {
            final elements = positionalArgs[0] as Iterable;
            return DoubleLinkedQueue<dynamic>.from(elements);
          },
          'of': (visitor, positionalArgs, namedArgs) {
            final elements = positionalArgs[0] as Iterable;
            return DoubleLinkedQueue<dynamic>.of(elements);
          },
        },
        methods: {
          'add': (visitor, target, positionalArgs, namedArgs) {
            (target as DoubleLinkedQueue).add(positionalArgs[0]);
            return null;
          },
          'addAll': (visitor, target, positionalArgs, namedArgs) {
            (target as DoubleLinkedQueue).addAll(positionalArgs[0] as Iterable);
            return null;
          },
          'addFirst': (visitor, target, positionalArgs, namedArgs) {
            (target as DoubleLinkedQueue).addFirst(positionalArgs[0]);
            return null;
          },
          'addLast': (visitor, target, positionalArgs, namedArgs) {
            (target as DoubleLinkedQueue).addLast(positionalArgs[0]);
            return null;
          },
          'clear': (visitor, target, positionalArgs, namedArgs) {
            (target as DoubleLinkedQueue).clear();
            return null;
          },
          'remove': (visitor, target, positionalArgs, namedArgs) {
            return (target as DoubleLinkedQueue).remove(positionalArgs[0]);
          },
          'removeFirst': (visitor, target, positionalArgs, namedArgs) {
            return (target as DoubleLinkedQueue).removeFirst();
          },
          'removeLast': (visitor, target, positionalArgs, namedArgs) {
            return (target as DoubleLinkedQueue).removeLast();
          },
          'firstEntry': (visitor, target, positionalArgs, namedArgs) {
            return (target as DoubleLinkedQueue).firstEntry();
          },
          'lastEntry': (visitor, target, positionalArgs, namedArgs) {
            return (target as DoubleLinkedQueue).lastEntry();
          },
          'contains': (visitor, target, positionalArgs, namedArgs) {
            return (target as DoubleLinkedQueue).contains(positionalArgs[0]);
          },
          'toList': (visitor, target, positionalArgs, namedArgs) {
            final growable = namedArgs['growable'] as bool? ?? true;
            return (target as DoubleLinkedQueue).toList(growable: growable);
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as DoubleLinkedQueue).toString();
          },
        },
        getters: {
          'length': (visitor, target) => (target as DoubleLinkedQueue).length,
          'isEmpty': (visitor, target) => (target as DoubleLinkedQueue).isEmpty,
          'isNotEmpty': (visitor, target) =>
              (target as DoubleLinkedQueue).isNotEmpty,
          'first': (visitor, target) => (target as DoubleLinkedQueue).first,
          'last': (visitor, target) => (target as DoubleLinkedQueue).last,
          'iterator': (visitor, target) =>
              (target as DoubleLinkedQueue).iterator,
          'hashCode': (visitor, target) =>
              (target as DoubleLinkedQueue).hashCode,
          'runtimeType': (visitor, target) =>
              (target as DoubleLinkedQueue).runtimeType,
        },
      );
}

class DoubleLinkedQueueEntryCollection {
  static BridgedClass get definition => BridgedClass(
        nativeType: DoubleLinkedQueueEntry,
        name: 'DoubleLinkedQueueEntry',
        typeParameterCount: 1,
        isSubtypeOfFunc: (value) => value is DoubleLinkedQueueEntry,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final element =
                positionalArgs.isNotEmpty ? positionalArgs[0] : null;
            return DoubleLinkedQueueEntry<dynamic>(element);
          },
        },
        methods: {
          'append': (visitor, target, positionalArgs, namedArgs) {
            (target as DoubleLinkedQueueEntry).append(positionalArgs[0]);
            return null;
          },
          'prepend': (visitor, target, positionalArgs, namedArgs) {
            (target as DoubleLinkedQueueEntry).prepend(positionalArgs[0]);
            return null;
          },
          'remove': (visitor, target, positionalArgs, namedArgs) {
            return (target as DoubleLinkedQueueEntry).remove();
          },
          'previousEntry': (visitor, target, positionalArgs, namedArgs) {
            return (target as DoubleLinkedQueueEntry).previousEntry();
          },
          'nextEntry': (visitor, target, positionalArgs, namedArgs) {
            return (target as DoubleLinkedQueueEntry).nextEntry();
          },
        },
        getters: {
          'element': (visitor, target) =>
              (target as DoubleLinkedQueueEntry).element,
          'hashCode': (visitor, target) =>
              (target as DoubleLinkedQueueEntry).hashCode,
          'runtimeType': (visitor, target) =>
              (target as DoubleLinkedQueueEntry).runtimeType,
        },
        setters: {
          'element': (visitor, target, value) {
            (target as DoubleLinkedQueueEntry).element = value;
          },
        },
      );
}
