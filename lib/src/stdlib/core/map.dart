import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/map.dart';

class MapCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Define Map type (likely just resolves the name)
    environment.define(
        'Map',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Actual Map construction is complex (literals, from, etc.)
          // Handle specific constructors like Map.from in static methods if needed.
          return Map;
        }, arity: 0, name: 'Map'));

    // Define MapEntry constructor
    environment.define(
        'MapEntry',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          if (arguments.length != 2) {
            throw RuntimeError(
                'MapEntry constructor requires 2 arguments (key, value).');
          }
          return MapEntry(arguments[0], arguments[1]);
        }, arity: 2, name: 'MapEntry'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is MapEntry) {
      switch (name) {
        case 'key':
          return target.key;
        case 'value':
          return target.value;
        case 'hashCode':
          return target;
        case 'toString':
          return target.toString();
        default:
          throw RuntimeError(
              'MapEntry has no instance method mapping for "$name"');
      }
    } else if (target is Map) {
      target = target.cast<dynamic, dynamic>(); // Ensure dynamic keys/values
      switch (name) {
        case '[]': // Index operator
          if (arguments.length != 1) {
            throw RuntimeError(
                'Map index operator [] requires one argument (key).');
          }
          return target[arguments[0]];
        case '[]=': // Index assignment operator
          if (arguments.length != 2) {
            throw RuntimeError(
                'Map index assignment operator []= requires two arguments (key, value).');
          }
          target[arguments[0]] = arguments[1];
          return arguments[1]; // Assignment returns the assigned value
        case 'addAll':
          target.addAll(arguments[0] as Map);
          return null;
        case 'clear':
          target.clear();
          return null;
        case 'containsKey':
          return target.containsKey(arguments[0]);
        case 'containsValue':
          return target.containsValue(arguments[0]);
        case 'remove':
          return target.remove(arguments[0]);
        case 'length':
          return target.length;
        case 'isEmpty':
          return target.isEmpty;
        case 'isNotEmpty':
          return target.isNotEmpty;
        case 'keys':
          return target.keys;
        case 'values':
          return target.values;
        case 'update':
          final key = arguments[0];
          final update = arguments[1];
          if (update is! InterpretedFunction) {
            throw RuntimeError(
                'Expected an InterpretedFunction for update callback');
          }
          final ifAbsent = namedArguments.get<InterpretedFunction?>("ifAbsent");
          return target.update(
              key,
              // Use visitor for the update callback
              (existingValue) => update.call(visitor, [existingValue]),
              // Use visitor for the ifAbsent callback
              ifAbsent:
                  ifAbsent == null ? null : () => ifAbsent.call(visitor, []));
        case 'putIfAbsent':
          final key = arguments[0];
          final ifAbsent = arguments[1];
          if (ifAbsent is! InterpretedFunction) {
            throw RuntimeError(
                'Expected an InterpretedFunction for putIfAbsent');
          }
          // Use visitor for the ifAbsent callback
          return target.putIfAbsent(key, () => ifAbsent.call(visitor, []));
        case 'addEntries':
          final entries = arguments[0];

          if (entries is! List) {
            throw RuntimeError('Expected an Iterable<MapEntry> for addEntries');
          }
          target.addEntries(entries.map((e) => e as MapEntry));
          return null;
        case 'updateAll':
          final update = arguments[0];
          if (update is! InterpretedFunction) {
            throw RuntimeError('Expected an InterpretedFunction for updateAll');
          }
          // Use visitor for the update callback
          target.updateAll((key, value) => update.call(visitor, [key, value]));
          return null;
        case 'removeWhere':
          final test = arguments[0];
          if (test is! InterpretedFunction) {
            throw RuntimeError(
                'Expected an InterpretedFunction for removeWhere');
          }
          // Use visitor for the test callback
          target.removeWhere(
              (key, value) => test.call(visitor, [key, value]) as bool);
          return null;
        case 'map':
          final transform = arguments[0];
          if (transform is! InterpretedFunction) {
            throw RuntimeError('Expected an InterpretedFunction for map');
          }
          // Use visitor for the transform callback
          return target.map((key, value) =>
              transform.call(visitor, [key, value]) as MapEntry);
        case 'entries':
          return target.entries;
        case 'cast':
          // Type arguments for cast<RK, RV>() would need special handling
          return target.cast<dynamic, dynamic>();
        // 'contains' removed as containsKey is the primary method
        case 'forEach':
          final action = arguments[0];
          if (action is! InterpretedFunction) {
            throw RuntimeError('Expected an InterpretedFunction for forEach');
          }
          // Use visitor for the action callback
          target.forEach((key, value) => action.call(visitor, [key, value]));
          return null;
        case 'hashCode':
          return target.hashCode;
        case 'toString':
          return target.toString();
        default:
          throw RuntimeError('Map has no instance method mapping for "$name"');
      }
    } else {
      // static methods
      switch (name) {
        case 'castFrom': // Not standard dart:core Map
          throw RuntimeError('Static method castFrom is not standard on Map.');
        // return Map.castFrom<dynamic, dynamic, dynamic, dynamic>(
        //     arguments[0] as Map);
        case 'from':
          return Map<dynamic, dynamic>.from(arguments[0] as Map);
        case 'fromEntries':
          final entries = arguments[0];
          if (entries is! Iterable<dynamic>) {
            throw RuntimeError(
                'Map.fromEntries requires an Iterable<MapEntry>.');
          }
          return Map<dynamic, dynamic>.fromEntries(entries.cast());
        case 'fromIterable':
          final iterable = arguments[0] as Iterable;
          final keyFunc = namedArguments.get<InterpretedFunction?>("key");
          final valueFunc = namedArguments.get<InterpretedFunction?>("value");
          return Map<dynamic, dynamic>.fromIterable(iterable,
              // Use visitor for key/value callbacks
              key: keyFunc == null
                  ? (item) => item
                  : (item) => keyFunc.call(visitor, [item]),
              value: valueFunc == null
                  ? (item) => item
                  : (item) => valueFunc.call(visitor, [item]));
        case 'fromIterables':
          return Map<dynamic, dynamic>.fromIterables(
              arguments[0] as Iterable, arguments[1] as Iterable);
        case 'identity':
          return Map<dynamic, dynamic>.identity();
        case 'of':
          return Map.of(arguments[0] as Map);
        case 'unmodifiable':
          return Map<dynamic, dynamic>.unmodifiable(arguments[0] as Map);
        default:
          throw RuntimeError('Map has no static method mapping for "$name"');
      }
    }
  }
}

class MapEntryCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Define MapEntry constructor
    environment.define(
        'MapEntry',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          if (arguments.length != 2) {
            throw RuntimeError(
                'MapEntry constructor requires 2 arguments (key, value).');
          }
          return MapEntry(arguments[0], arguments[1]);
        }, arity: 2, name: 'MapEntry'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is MapEntry) {
      switch (name) {
        case 'key':
          return target.key;
        case 'value':
          return target.value;
        case 'hashCode':
          return target;
        case 'toString':
          return target.toString();
        default:
          throw RuntimeError(
              'MapEntry has no instance method mapping for "$name"');
      }
    } else {
      // static methods
      throw RuntimeError('Map has no static method mapping for "$name"');
    }
  }
}
