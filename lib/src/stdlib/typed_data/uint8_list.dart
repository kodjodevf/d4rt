import 'dart:math';
import 'dart:typed_data';
import 'package:d4rt/d4rt.dart';

// Helper function to run interpreted functions
T? _runAction<T>(InterpreterVisitor visitor, InterpretedFunction? function,
    List<Object?> args) {
  if (function == null) return null;
  try {
    return function.call(visitor, args) as T?;
  } catch (e) {
    rethrow;
  }
}

class Uint8ListTypedData {
  static BridgedClass get definition => BridgedClass(
        name: 'Uint8List',
        nativeType: Uint8List,
        nativeNames: ['_Uint8ArrayView'],
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length == 1 && positionalArgs[0] is int) {
              return Uint8List(positionalArgs[0] as int);
            }
            throw RuntimeError(
                "Uint8List constructor expects one int argument (length).");
          },
          'fromList': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.length == 1 && positionalArgs[0] is List) {
              final sourceList = positionalArgs[0] as List;
              final intList = sourceList.toNativeList().map((e) {
                if (e is int) return e;
                throw RuntimeError("Uint8List.fromList expects a List<int>.");
              }).toList();
              return Uint8List.fromList(intList);
            }
            throw RuntimeError(
                "Uint8List.fromList expects one List<int> argument.");
          },
          'view': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty && positionalArgs[0] is ByteBuffer) {
              final buffer = positionalArgs[0] as ByteBuffer;
              final offsetInBytes = positionalArgs.length > 1
                  ? positionalArgs[1] as int? ?? 0
                  : 0;
              final length =
                  positionalArgs.length > 2 ? positionalArgs[2] as int? : null;
              return Uint8List.view(buffer, offsetInBytes, length);
            }
            throw RuntimeError(
                "Uint8List.view expects ByteBuffer and optional int arguments.");
          },
          'sublistView': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isNotEmpty && positionalArgs[0] is TypedData) {
              final data = positionalArgs[0] as TypedData;
              final start = positionalArgs.length > 1
                  ? positionalArgs[1] as int? ?? 0
                  : 0;
              final end =
                  positionalArgs.length > 2 ? positionalArgs[2] as int? : null;
              return Uint8List.sublistView(data, start, end);
            }
            throw RuntimeError(
                "Uint8List.sublistView expects TypedData and optional int arguments.");
          },
        },
        methods: {
          // Index operators
          '[]': (visitor, target, positionalArgs, namedArgs) {
            if (target is Uint8List &&
                positionalArgs.length == 1 &&
                positionalArgs[0] is int) {
              return target[positionalArgs[0] as int];
            }
            throw RuntimeError("Uint8List[index] expects an int index.");
          },
          '[]=': (visitor, target, positionalArgs, namedArgs) {
            if (target is Uint8List &&
                positionalArgs.length == 2 &&
                positionalArgs[0] is int &&
                positionalArgs[1] is int) {
              final index = positionalArgs[0] as int;
              final value = positionalArgs[1] as int;
              target[index] = value;
              return value;
            }
            throw RuntimeError(
                "Uint8List[index] = value expects int index and int value.");
          },

          // List methods
          'add': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uint8List).add(positionalArgs[0] as int);
          },
          'addAll': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uint8List)
                .addAll(positionalArgs[0] as Iterable<int>);
          },
          'any': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            return (target as Uint8List).any((element) =>
                _runAction<bool>(visitor, test, [element]) == true);
          },
          'asMap': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uint8List).asMap();
          },
          'asUnmodifiableView': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uint8List).asUnmodifiableView();
          },
          'cast': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uint8List).cast();
          },
          'clear': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uint8List).clear();
          },
          'contains': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uint8List).contains(positionalArgs[0]);
          },
          'elementAt': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uint8List).elementAt(positionalArgs[0] as int);
          },
          'every': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            return (target as Uint8List).every((element) =>
                _runAction<bool>(visitor, test, [element]) == true);
          },
          'expand': (visitor, target, positionalArgs, namedArgs) {
            final toElements = positionalArgs[0] as InterpretedFunction;
            return (target as Uint8List).expand((element) =>
                _runAction<Iterable>(visitor, toElements, [element]) ?? []);
          },
          'fillRange': (visitor, target, positionalArgs, namedArgs) {
            final start = positionalArgs[0] as int;
            final end = positionalArgs[1] as int;
            final fillValue =
                positionalArgs.length > 2 ? positionalArgs[2] as int? : null;
            return (target as Uint8List).fillRange(start, end, fillValue);
          },
          'firstWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            final orElse = namedArgs['orElse'] as InterpretedFunction?;
            return (target as Uint8List).firstWhere(
              (element) => _runAction<bool>(visitor, test, [element]) == true,
              orElse: orElse != null
                  ? () => _runAction<int>(visitor, orElse, [])!
                  : null,
            );
          },
          'fold': (visitor, target, positionalArgs, namedArgs) {
            final initialValue = positionalArgs[0];
            final combine = positionalArgs[1] as InterpretedFunction;
            return (target as Uint8List).fold(
                initialValue,
                (prev, element) =>
                    _runAction(visitor, combine, [prev, element]));
          },
          'followedBy': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uint8List)
                .followedBy(positionalArgs[0] as Iterable<int>);
          },
          'forEach': (visitor, target, positionalArgs, namedArgs) {
            final action = positionalArgs[0] as InterpretedFunction;
            for (var element in (target as Uint8List)) {
              _runAction<void>(visitor, action, [element]);
            }
            return null;
          },
          'getRange': (visitor, target, positionalArgs, namedArgs) {
            final start = positionalArgs[0] as int;
            final end = positionalArgs[1] as int;
            return (target as Uint8List).getRange(start, end);
          },
          'indexOf': (visitor, target, positionalArgs, namedArgs) {
            final element = positionalArgs[0] as int;
            final start =
                positionalArgs.length > 1 ? positionalArgs[1] as int : 0;
            return (target as Uint8List).indexOf(element, start);
          },
          'indexWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            final start =
                positionalArgs.length > 1 ? positionalArgs[1] as int : 0;
            return (target as Uint8List).indexWhere(
                (element) => _runAction<bool>(visitor, test, [element]) == true,
                start);
          },
          'insert': (visitor, target, positionalArgs, namedArgs) {
            final index = positionalArgs[0] as int;
            final element = positionalArgs[1] as int;
            return (target as Uint8List).insert(index, element);
          },
          'insertAll': (visitor, target, positionalArgs, namedArgs) {
            final index = positionalArgs[0] as int;
            final iterable = positionalArgs[1] as Iterable<int>;
            return (target as Uint8List).insertAll(index, iterable);
          },
          'join': (visitor, target, positionalArgs, namedArgs) {
            final separator =
                positionalArgs.isNotEmpty ? positionalArgs[0] as String : "";
            return (target as Uint8List).join(separator);
          },
          'lastIndexOf': (visitor, target, positionalArgs, namedArgs) {
            final element = positionalArgs[0] as int;
            final start =
                positionalArgs.length > 1 ? positionalArgs[1] as int? : null;
            return (target as Uint8List).lastIndexOf(element, start);
          },
          'lastIndexWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            final start =
                positionalArgs.length > 1 ? positionalArgs[1] as int? : null;
            return (target as Uint8List).lastIndexWhere(
                (element) => _runAction<bool>(visitor, test, [element]) == true,
                start);
          },
          'lastWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            final orElse = namedArgs['orElse'] as InterpretedFunction?;
            return (target as Uint8List).lastWhere(
              (element) => _runAction<bool>(visitor, test, [element]) == true,
              orElse: orElse != null
                  ? () => _runAction<int>(visitor, orElse, [])!
                  : null,
            );
          },
          'map': (visitor, target, positionalArgs, namedArgs) {
            final toElement = positionalArgs[0] as InterpretedFunction;
            return (target as Uint8List)
                .map((element) => _runAction(visitor, toElement, [element]));
          },
          'noSuchMethod': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uint8List)
                .noSuchMethod(positionalArgs[0] as Invocation);
          },
          'reduce': (visitor, target, positionalArgs, namedArgs) {
            final combine = positionalArgs[0] as InterpretedFunction;
            return (target as Uint8List).reduce((value, element) =>
                _runAction<int>(visitor, combine, [value, element])!);
          },
          'remove': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uint8List).remove(positionalArgs[0]);
          },
          'removeAt': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uint8List).removeAt(positionalArgs[0] as int);
          },
          'removeLast': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uint8List).removeLast();
          },
          'removeRange': (visitor, target, positionalArgs, namedArgs) {
            final start = positionalArgs[0] as int;
            final end = positionalArgs[1] as int;
            return (target as Uint8List).removeRange(start, end);
          },
          'removeWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            return (target as Uint8List).removeWhere((element) =>
                _runAction<bool>(visitor, test, [element]) == true);
          },
          'replaceRange': (visitor, target, positionalArgs, namedArgs) {
            final start = positionalArgs[0] as int;
            final end = positionalArgs[1] as int;
            final replacements = positionalArgs[2] as Iterable<int>;
            return (target as Uint8List).replaceRange(start, end, replacements);
          },
          'retainWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            return (target as Uint8List).retainWhere((element) =>
                _runAction<bool>(visitor, test, [element]) == true);
          },
          'setAll': (visitor, target, positionalArgs, namedArgs) {
            final index = positionalArgs[0] as int;
            final iterable = positionalArgs[1] as Iterable<int>;
            return (target as Uint8List).setAll(index, iterable);
          },
          'setRange': (visitor, target, positionalArgs, namedArgs) {
            final start = positionalArgs[0] as int;
            final end = positionalArgs[1] as int;
            final iterable = positionalArgs[2] as Iterable<int>;
            final skipCount =
                positionalArgs.length > 3 ? positionalArgs[3] as int : 0;
            return (target as Uint8List)
                .setRange(start, end, iterable, skipCount);
          },
          'shuffle': (visitor, target, positionalArgs, namedArgs) {
            final random =
                positionalArgs.isNotEmpty ? positionalArgs[0] as Random? : null;
            return (target as Uint8List).shuffle(random);
          },
          'singleWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            final orElse = namedArgs['orElse'] as InterpretedFunction?;
            return (target as Uint8List).singleWhere(
              (element) => _runAction<bool>(visitor, test, [element]) == true,
              orElse: orElse != null
                  ? () => _runAction<int>(visitor, orElse, [])!
                  : null,
            );
          },
          'skip': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uint8List).skip(positionalArgs[0] as int);
          },
          'skipWhile': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            return (target as Uint8List).skipWhile((element) =>
                _runAction<bool>(visitor, test, [element]) == true);
          },
          'sort': (visitor, target, positionalArgs, namedArgs) {
            final compare = positionalArgs.isNotEmpty
                ? positionalArgs[0] as InterpretedFunction?
                : null;
            return (target as Uint8List).sort(compare != null
                ? (a, b) => _runAction<int>(visitor, compare, [a, b])!
                : null);
          },
          'sublist': (visitor, target, positionalArgs, namedArgs) {
            final start = positionalArgs[0] as int;
            final end =
                positionalArgs.length > 1 ? positionalArgs[1] as int? : null;
            return (target as Uint8List).sublist(start, end);
          },
          'take': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uint8List).take(positionalArgs[0] as int);
          },
          'takeWhile': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            return (target as Uint8List).takeWhile((element) =>
                _runAction<bool>(visitor, test, [element]) == true);
          },
          'toList': (visitor, target, positionalArgs, namedArgs) {
            final growable = namedArgs['growable'] as bool? ?? true;
            return (target as Uint8List).toList(growable: growable);
          },
          'toSet': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uint8List).toSet();
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uint8List).toString();
          },
          'where': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            return (target as Uint8List).where((element) =>
                _runAction<bool>(visitor, test, [element]) == true);
          },
          'whereType': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uint8List).whereType();
          },

          // Operators
          '+': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uint8List) + (positionalArgs[0] as List<int>);
          },
          '==': (visitor, target, positionalArgs, namedArgs) {
            return (target as Uint8List) == positionalArgs[0];
          },
        },
        getters: {
          'length': (visitor, target) => (target as Uint8List).length,
          'elementSizeInBytes': (visitor, target) =>
              (target as Uint8List).elementSizeInBytes,
          'buffer': (visitor, target) => (target as Uint8List).buffer,
          'lengthInBytes': (visitor, target) =>
              (target as Uint8List).lengthInBytes,
          'offsetInBytes': (visitor, target) =>
              (target as Uint8List).offsetInBytes,
          'first': (visitor, target) => (target as Uint8List).first,
          'last': (visitor, target) => (target as Uint8List).last,
          'isEmpty': (visitor, target) => (target as Uint8List).isEmpty,
          'isNotEmpty': (visitor, target) => (target as Uint8List).isNotEmpty,
          'iterator': (visitor, target) => (target as Uint8List).iterator,
          'reversed': (visitor, target) => (target as Uint8List).reversed,
          'single': (visitor, target) => (target as Uint8List).single,
          'hashCode': (visitor, target) => (target as Uint8List).hashCode,
          'runtimeType': (visitor, target) => (target as Uint8List).runtimeType,
        },
        setters: {
          'length': (visitor, target, value) {
            (target as Uint8List).length = value as int;
          },
          'first': (visitor, target, value) {
            (target as Uint8List).first = value as int;
          },
          'last': (visitor, target, value) {
            (target as Uint8List).last = value as int;
          },
        },
      );
}
