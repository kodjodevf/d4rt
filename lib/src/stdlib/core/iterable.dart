import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/map.dart';

class IterableCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    // Define Iterable type
    environment.define(
        'Iterable',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return Iterable;
        }, arity: 0, name: 'Iterable'));
  }

  @override
  Object? evalMethod(target, String name, List<Object?> arguments,
      Map<String, Object?> namedArguments, InterpreterVisitor visitor) {
    if (target is Iterable) {
      target = target.cast<dynamic>(); // Ensure dynamic elements
      switch (name) {
        case 'contains':
          return target.contains(arguments[0]);
        case 'length':
          return target.length;
        case 'isEmpty':
          return target.isEmpty;
        case 'isNotEmpty':
          return target.isNotEmpty;
        case 'forEach':
          final callback = arguments[0];
          if (callback is! InterpretedFunction) {
            throw RuntimeError('Expected an InterpretedFunction for forEach');
          }
          for (final element in target) {
            // Use visitor to call the interpreted function
            callback.call(visitor, [element]);
          }
          return null;
        case 'any':
          final test = arguments[0];
          if (test is! InterpretedFunction) {
            throw RuntimeError('Expected an InterpretedFunction for any');
          }
          // Use visitor to call the interpreted function
          return target.any((element) => test.call(visitor, [element]) as bool);
        case 'every':
          final test = arguments[0];
          if (test is! InterpretedFunction) {
            throw RuntimeError('Expected an InterpretedFunction for every');
          }
          // Use visitor to call the interpreted function
          return target
              .every((element) => test.call(visitor, [element]) as bool);
        case 'map':
          final toElement = arguments[0];
          if (toElement is! InterpretedFunction) {
            throw RuntimeError('Expected an InterpretedFunction for map');
          }
          // Use visitor to call the interpreted function
          // Need lazy evaluation, return a new iterable that calls on demand
          return target.map((element) => toElement.call(visitor, [element]));
        case 'where':
          final test = arguments[0];
          if (test is! InterpretedFunction) {
            throw RuntimeError('Expected an InterpretedFunction for where');
          }
          // Use visitor to call the interpreted function
          return target
              .where((element) => test.call(visitor, [element]) as bool);
        case 'expand':
          final toElements = arguments[0];
          if (toElements is! InterpretedFunction) {
            throw RuntimeError('Expected an InterpretedFunction for expand');
          }
          // Use visitor to call the interpreted function
          return target.expand(
              (element) => toElements.call(visitor, [element]) as Iterable);
        case 'reduce':
          final combine = arguments[0];
          if (combine is! InterpretedFunction) {
            throw RuntimeError('Expected an InterpretedFunction for reduce');
          }
          // Use visitor to call the interpreted function
          return target.reduce(
              (value, element) => combine.call(visitor, [value, element]));
        case 'fold':
          final initialValue = arguments[0];
          final combine = arguments[1];
          if (combine is! InterpretedFunction) {
            throw RuntimeError('Expected an InterpretedFunction for fold');
          }
          // Use visitor to call the interpreted function
          return target.fold(
              initialValue,
              (previousValue, element) =>
                  combine.call(visitor, [previousValue, element]));
        case 'join':
          final separator = arguments.isNotEmpty ? arguments[0] as String : '';
          return target.join(separator);
        case 'take':
          return target.take(arguments[0] as int);
        case 'takeWhile':
          final test = arguments[0];
          if (test is! InterpretedFunction) {
            throw RuntimeError('Expected an InterpretedFunction for takeWhile');
          }
          // Use visitor to call the interpreted function
          return target
              .takeWhile((value) => test.call(visitor, [value]) as bool);
        case 'skip':
          return target.skip(arguments[0] as int);
        case 'skipWhile':
          final test = arguments[0];
          if (test is! InterpretedFunction) {
            throw RuntimeError('Expected an InterpretedFunction for skipWhile');
          }
          // Use visitor to call the interpreted function
          return target
              .skipWhile((value) => test.call(visitor, [value]) as bool);
        case 'toList':
          return target.toList(
              growable: namedArguments.get<bool?>("growable") ?? true);
        case 'toSet':
          return target.toSet();
        case 'first':
          return target.first;
        case 'last':
          return target.last;
        case 'single':
          return target.single;
        case 'firstWhere':
          final test = arguments[0];
          if (test is! InterpretedFunction) {
            throw RuntimeError(
                'Expected an InterpretedFunction for firstWhere test');
          }
          final orElse = namedArguments.get<InterpretedFunction?>("orElse");
          return target.firstWhere(
            (element) => test.call(visitor, [element]) as bool,
            orElse: orElse == null ? null : () => orElse.call(visitor, []),
          );
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
        case 'cast':
          // Type arguments for cast<R>() would need special handling
          return target.cast<dynamic>();
        case 'followedBy':
          return target.followedBy(arguments[0] as Iterable);
        case 'elementAt':
          return target.elementAt(arguments[0] as int);
        case 'hashCode':
          return target.hashCode;
        case 'toString':
          return target.toString();
        case 'iterator':
          // Need to wrap the native iterator if state needs to be managed by interpreter
          return target.iterator;
        default:
          throw RuntimeError(
              'Iterable has no instance method mapping for "$name"');
      }
    } else {
      // static methods
      switch (name) {
        case 'castFrom': // Not standard dart:core Iterable
          throw RuntimeError(
              'Static method castFrom is not standard on Iterable.');
        // return Iterable.castFrom<dynamic, dynamic>(arguments[0] as Iterable);
        case 'empty':
          return Iterable<dynamic>.empty();
        case 'generate':
          final generator = arguments[1];
          if (generator is! InterpretedFunction) {
            throw RuntimeError('Expected an InterpretedFunction for generate');
          }
          // Use visitor to call the generator
          return Iterable<dynamic>.generate(
              arguments[0] as int, (i) => generator.call(visitor, [i]));
        case 'iterableToFullString': // internal helper?
          if (arguments.length != 1 || arguments[0] is! Iterable) {
            throw RuntimeError(
                'iterableToFullString expects one Iterable argument.');
          }
          return Iterable.iterableToFullString(arguments[0] as Iterable);
        case 'iterableToShortString': // internal helper?
          if (arguments.length != 1 || arguments[0] is! Iterable) {
            throw RuntimeError(
                'iterableToShortString expects one Iterable argument.');
          }
          return Iterable.iterableToShortString(arguments[0] as Iterable);
        default:
          throw RuntimeError(
              'Iterable has no static method mapping for "$name"');
      }
    }
  }
}
