import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart';
import 'package:d4rt/src/utils/extensions/map.dart';

class SetCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'Set',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          // Actual Set construction handled by literals or static methods
          return Set;
        }, arity: 0, name: 'Set'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is Set) {
      target = target.cast<dynamic>(); // Ensure dynamic elements
      switch (name) {
        case 'add':
          return target.add(arguments[0]); // Returns bool
        case 'addAll':
          target.addAll(arguments[0] as Iterable);
          return null;
        case 'remove':
          return target.remove(arguments[0]); // Returns bool
        case 'clear':
          target.clear();
          return null;
        case 'contains':
          return target.contains(arguments[0]);
        case 'length':
          return target.length;
        case 'isEmpty':
          return target.isEmpty;
        case 'isNotEmpty':
          return target.isNotEmpty;
        case 'union':
          return target.union(arguments.get<Set<Object?>>(0)!);
        case 'intersection':
          return target.intersection(arguments.get<Set<Object?>>(0)!);
        case 'difference':
          return target.difference(arguments.get<Set<Object?>>(0)!);
        case 'join':
          return target.join(arguments.get<String?>(0) ?? '');
        case 'retainWhere':
          final test = arguments[0];
          if (test is! InterpretedFunction) {
            throw RuntimeError(
                'Expected an InterpretedFunction for retainWhere');
          }
          target
              .retainWhere((element) => test.call(visitor, [element]) as bool);
          return null;
        case 'removeWhere':
          final test = arguments[0];
          if (test is! InterpretedFunction) {
            throw RuntimeError(
                'Expected an InterpretedFunction for removeWhere');
          }
          target
              .removeWhere((element) => test.call(visitor, [element]) as bool);
          return null;
        case 'lookup':
          return target.lookup(arguments[0]);
        case 'toList':
          return target.toList(
              growable: namedArguments.get<bool?>('growable') ?? true);
        case 'toSet':
          return target.toSet();
        case 'containsAll':
          return target.containsAll(arguments[0] as Iterable);
        // Inherited from Iterable, but implement directly for clarity/potential overrides
        case 'followedBy':
          return target.followedBy(arguments[0] as Iterable);
        case 'cast':
          return target.cast<dynamic>();
        case 'hashCode':
          return target.hashCode;
        case 'toString':
          return target.toString();
        case 'any':
          final test = arguments[0];
          if (test is! InterpretedFunction) {
            throw RuntimeError('Expected an InterpretedFunction for any');
          }
          return target.any((element) => test.call(visitor, [element]) as bool);
        case 'every':
          final test = arguments[0];
          if (test is! InterpretedFunction) {
            throw RuntimeError('Expected an InterpretedFunction for every');
          }
          return target
              .every((element) => test.call(visitor, [element]) as bool);
        case 'where':
          final test = arguments[0];
          if (test is! InterpretedFunction) {
            throw RuntimeError('Expected an InterpretedFunction for where');
          }
          return target
              .where((element) => test.call(visitor, [element]) as bool);
        case 'map':
          final transform = arguments[0];
          if (transform is! InterpretedFunction) {
            throw RuntimeError('Expected an InterpretedFunction for map');
          }
          return target.map((element) => transform.call(visitor, [element]));
        case 'expand':
          final transform = arguments[0];
          if (transform is! InterpretedFunction) {
            throw RuntimeError('Expected an InterpretedFunction for expand');
          }
          return target.expand(
              (element) => transform.call(visitor, [element]) as Iterable);
        case 'reduce':
          final combine = arguments[0];
          if (combine is! InterpretedFunction) {
            throw RuntimeError('Expected an InterpretedFunction for reduce');
          }
          return target.reduce(
              (value, element) => combine.call(visitor, [value, element]));
        case 'fold':
          final initialValue = arguments[0];
          final combine = arguments[1];
          if (combine is! InterpretedFunction) {
            throw RuntimeError('Expected an InterpretedFunction for fold');
          }
          return target.fold(initialValue,
              (value, element) => combine.call(visitor, [value, element]));
        case 'take':
          return target.take(arguments[0] as int);
        case 'takeWhile':
          final test = arguments[0];
          if (test is! InterpretedFunction) {
            throw RuntimeError('Expected an InterpretedFunction for takeWhile');
          }
          return target
              .takeWhile((element) => test.call(visitor, [element]) as bool);
        case 'skip':
          return target.skip(arguments[0] as int);
        case 'skipWhile':
          final test = arguments[0];
          if (test is! InterpretedFunction) {
            throw RuntimeError('Expected an InterpretedFunction for skipWhile');
          }
          return target
              .skipWhile((element) => test.call(visitor, [element]) as bool);
        case 'firstWhere':
          final test = arguments[0];
          if (test is! InterpretedFunction) {
            throw RuntimeError(
                'Expected an InterpretedFunction for firstWhere test');
          }
          final orElse = namedArguments.get<InterpretedFunction?>("orElse");
          return target.firstWhere(
              (element) => test.call(visitor, [element]) as bool,
              orElse: orElse == null ? null : () => orElse.call(visitor, []));
        case 'lastWhere':
          final test = arguments[0];
          if (test is! InterpretedFunction) {
            throw RuntimeError(
                'Expected an InterpretedFunction for lastWhere test');
          }
          final orElse = namedArguments.get<InterpretedFunction?>("orElse");
          return target.lastWhere(
              (element) => test.call(visitor, [element]) as bool,
              orElse: orElse == null ? null : () => orElse.call(visitor, []));
        case 'singleWhere':
          final test = arguments[0];
          if (test is! InterpretedFunction) {
            throw RuntimeError(
                'Expected an InterpretedFunction for singleWhere test');
          }
          final orElse = namedArguments.get<InterpretedFunction?>("orElse");
          return target.singleWhere(
              (element) => test.call(visitor, [element]) as bool,
              orElse: orElse == null ? null : () => orElse.call(visitor, []));
        case 'elementAt':
          return target.elementAt(arguments[0] as int);
        case 'iterator':
          return target.iterator;
        case 'first':
          return target.first;
        case 'last':
          return target.last;
        case 'single':
          return target.single;
        default:
          throw RuntimeError('Set has no instance method mapping for "$name"');
      }
    } else {
      // static methods
      switch (name) {
        case 'castFrom': // Not standard dart:core Set
          throw RuntimeError('Static method castFrom is not standard on Set.');
        // return Set.castFrom<dynamic, dynamic>(arguments[0] as Set);
        case 'from':
          return Set<dynamic>.from(arguments[0] as Iterable);
        case 'of':
          return Set.of(arguments[0] as Iterable);
        case 'unmodifiable':
          return Set<dynamic>.unmodifiable(arguments[0] as Iterable);
        case 'identity':
          return Set<dynamic>.identity();
        default:
          throw RuntimeError('Set has no static method mapping for "$name"');
      }
    }
  }
}
