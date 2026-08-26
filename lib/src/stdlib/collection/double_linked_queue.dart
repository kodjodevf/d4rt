import 'dart:collection';
import 'package:d4rt/d4rt.dart';

class DoubleLinkedQueueCollection {
  static BridgedClass get definition => BridgedClass(
        nativeType: DoubleLinkedQueue,
        name: 'DoubleLinkedQueue',
        typeParameterCount: 1,
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
