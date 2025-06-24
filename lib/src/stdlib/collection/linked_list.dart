import 'dart:collection';
import 'package:d4rt/d4rt.dart';

class LinkedListCollection {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: LinkedList,
        name: 'LinkedList',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty || namedArgs.isNotEmpty) {
              throw RuntimeError(
                  "Constructor LinkedList() does not take arguments.");
            }
            return LinkedList<BridgedLinkedListEntry>();
          },
        },
        methods: {
          'add': (visitor, target, positionalArgs, namedArgs) {
            if (target is LinkedList<BridgedLinkedListEntry> &&
                positionalArgs.length == 1 &&
                positionalArgs[0] is BridgedLinkedListEntry &&
                namedArgs.isEmpty) {
              target.add(positionalArgs[0] as BridgedLinkedListEntry);
              return null;
            }
            throw RuntimeError(
                "Invalid arguments for LinkedList.add. Expected a BridgedLinkedListEntry.");
          },
          'remove': (visitor, target, positionalArgs, namedArgs) {
            if (target is LinkedList<BridgedLinkedListEntry> &&
                positionalArgs.length == 1 &&
                positionalArgs[0] is BridgedLinkedListEntry &&
                namedArgs.isEmpty) {
              return target.remove(positionalArgs[0] as BridgedLinkedListEntry);
            }
            throw RuntimeError(
                "Invalid arguments for LinkedList.remove. Expected a BridgedLinkedListEntry.");
          },
          'clear': (visitor, target, positionalArgs, namedArgs) {
            if (target is LinkedList<BridgedLinkedListEntry> &&
                positionalArgs.isEmpty &&
                namedArgs.isEmpty) {
              target.clear();
              return null;
            }
            throw RuntimeError("Invalid arguments for LinkedList.clear");
          },
          'removeFirst': (visitor, target, positionalArgs, namedArgs) {
            if (target is LinkedList<BridgedLinkedListEntry> &&
                positionalArgs.isEmpty &&
                namedArgs.isEmpty) {
              if (target.isEmpty) {
                throw RuntimeError(
                    "Cannot removeFirst from an empty LinkedList.");
              }
              final firstEntry = target.first;
              firstEntry.unlink();
              return firstEntry;
            }
            throw RuntimeError("Invalid arguments for LinkedList.removeFirst");
          },
        },
        getters: {
          'length': (visitor, target) {
            if (target is LinkedList<BridgedLinkedListEntry>) {
              return target.length;
            }
            throw RuntimeError(
                "Target is not a LinkedList for getter 'length'");
          },
          'isEmpty': (visitor, target) {
            if (target is LinkedList<BridgedLinkedListEntry>) {
              return target.isEmpty;
            }
            throw RuntimeError(
                "Target is not a LinkedList for getter 'isEmpty'");
          },
          'isNotEmpty': (visitor, target) {
            if (target is LinkedList<BridgedLinkedListEntry>) {
              return target.isNotEmpty;
            }
            throw RuntimeError(
                "Target is not a LinkedList for getter 'isNotEmpty'");
          },
          'first': (visitor, target) {
            if (target is LinkedList<BridgedLinkedListEntry>) {
              if (target.isEmpty) {
                throw RuntimeError(
                    "Cannot get first from an empty LinkedList.");
              }
              return target.first;
            }
            throw RuntimeError("Target is not a LinkedList for getter 'first'");
          },
          'last': (visitor, target) {
            if (target is LinkedList<BridgedLinkedListEntry>) {
              if (target.isEmpty) {
                throw RuntimeError("Cannot get last from an empty LinkedList.");
              }
              return target.last;
            }
            throw RuntimeError("Target is not a LinkedList for getter 'last'");
          },
        },
      );
}

final class BridgedLinkedListEntry
    extends LinkedListEntry<BridgedLinkedListEntry> {
  final Object? value;

  BridgedLinkedListEntry(this.value);

  @override
  String toString() => 'BridgedLinkedListEntry($value)';
}

class LinkedListEntryCollection {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: BridgedLinkedListEntry,
        name: 'LinkedListEntry',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length == 1 && namedArgs.isEmpty) {
              return BridgedLinkedListEntry(positionalArgs[0]);
            }
            throw RuntimeError(
                "Constructor LinkedListEntry(value) expects one positional argument.");
          },
        },
        methods: {
          'unlink': (visitor, target, positionalArgs, namedArgs) {
            if (target is BridgedLinkedListEntry &&
                positionalArgs.isEmpty &&
                namedArgs.isEmpty) {
              if (target.list == null) {
                throw RuntimeError(
                    "Cannot unlink an entry that is not in a list or already unlinked.");
              }
              target.unlink();
              return null;
            }
            throw RuntimeError("Invalid arguments for LinkedListEntry.unlink");
          },
        },
        getters: {
          'value': (visitor, target) {
            if (target is BridgedLinkedListEntry) {
              return target.value;
            }
            throw RuntimeError(
                "Target is not a LinkedListEntry for getter 'value'");
          },
          'list': (visitor, target) {
            if (target is BridgedLinkedListEntry) {
              return target.list;
            }
            throw RuntimeError(
                "Target is not a LinkedListEntry for getter 'list'");
          },
          'previous': (visitor, target) {
            if (target is BridgedLinkedListEntry) {
              return target.previous;
            }
            throw RuntimeError(
                "Target is not a LinkedListEntry for getter 'previous'");
          },
          'next': (visitor, target) {
            if (target is BridgedLinkedListEntry) {
              return target.next;
            }
            throw RuntimeError(
                "Target is not a LinkedListEntry for getter 'next'");
          },
        },
      );
}
