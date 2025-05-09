import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/utils/extensions/list.dart';
import 'package:d4rt/src/utils/extensions/map.dart';

class ListCore implements MethodInterface {
  @override
  void setEnvironment(Environment environment) {
    environment.define(
        'List',
        NativeFunction((visitor, arguments, namedArguments, typeArguments) {
          return List;
        }, arity: 0, name: 'List'));
  }

  @override
  Object? evalMethod(target, name, arguments, namedArguments, visitor) {
    if (target is List) {
      target = target.cast<dynamic>();
      switch (name) {
        case 'add':
          target.add(arguments[0]);
          return null;
        case 'addAll':
          target.addAll(arguments[0] as Iterable);
          return null;
        case 'remove':
          return target.remove(arguments[0]);
        case 'removeAt':
          return target.removeAt(arguments[0] as int);
        case 'removeLast':
          return target.removeLast();
        case 'clear':
          target.clear();
          return null;
        case 'contains':
          return target.contains(arguments[0]);
        case 'indexOf':
          int start = arguments.length == 2 ? arguments[1] as int : 0;
          return target.indexOf(arguments[0], start);
        case 'lastIndexOf':
          int? start = arguments.length == 2 ? arguments[1] as int? : null;
          return target.lastIndexOf(arguments[0], start);
        case 'length':
          return target.length;
        case 'isEmpty':
          return target.isEmpty;
        case 'isNotEmpty':
          return target.isNotEmpty;
        case 'sublist':
          int? end = arguments.length == 2 ? arguments[1] as int? : null;
          return target.sublist(arguments[0] as int, end);
        case 'forEach':
          final callback = arguments[0];
          if (callback is! InterpretedFunction) {
            throw RuntimeError('Expected a InterpretedFunction for forEach');
          }
          for (final element in target) {
            callback.call(visitor, [element]);
          }
          return null;
        case 'any':
          final test = arguments[0] as InterpretedFunction;
          return target.any((element) => test.call(visitor, [element]) as bool);
        case 'every':
          final test = arguments[0] as InterpretedFunction;
          return target
              .every((element) => test.call(visitor, [element]) as bool);
        case 'map':
          final toElement = arguments[0] as InterpretedFunction;
          return target.map((element) => toElement.call(visitor, [element]));
        case 'where':
          final test = arguments[0] as InterpretedFunction;
          return target
              .where((element) => test.call(visitor, [element]) as bool);
        case 'expand':
          final toElements = arguments[0] as InterpretedFunction;
          return target.expand(
              (element) => toElements.call(visitor, [element]) as Iterable);
        case 'reduce':
          final combine = arguments[0] as InterpretedFunction;
          return target.reduce(
              (value, element) => combine.call(visitor, [value, element]));
        case 'fold':
          final initialValue = arguments[0];
          final combine = arguments[1] as InterpretedFunction;
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
          final test = arguments[0] as InterpretedFunction;
          return target
              .takeWhile((value) => test.call(visitor, [value]) as bool);
        case 'skip':
          return target.skip(arguments[0] as int);
        case 'skipWhile':
          final test = arguments[0] as InterpretedFunction;
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
          final test = arguments[0] as InterpretedFunction;
          final orElse = namedArguments.get<InterpretedFunction?>("orElse");
          return target.firstWhere(
            (element) => test.call(visitor, [element]) as bool,
            orElse: orElse == null ? null : () => orElse.call(visitor, []),
          );
        case 'lastWhere':
          final test = arguments[0] as InterpretedFunction;
          final orElse = namedArguments.get<InterpretedFunction?>("orElse");
          return target.lastWhere(
              (element) => test.call(visitor, [element]) as bool,
              orElse: orElse == null ? null : () => orElse.call(visitor, []));
        case 'singleWhere':
          final test = arguments[0] as InterpretedFunction;
          final orElse = namedArguments.get<InterpretedFunction?>("orElse");
          return target.singleWhere(
              (element) => test.call(visitor, [element]) as bool,
              orElse: orElse == null ? null : () => orElse.call(visitor, []));
        case 'insert':
          target.insert(arguments[0] as int, arguments[1]);
          return null;
        case 'insertAll':
          target.insertAll(arguments[0] as int, arguments[1] as Iterable);
          return null;
        case 'setAll':
          target.setAll(arguments[0] as int, arguments[1] as Iterable);
          return null;
        case 'fillRange':
          target.fillRange(arguments[0] as int, arguments[1] as int,
              arguments.get<dynamic>(2));
          return null;
        case 'replaceRange':
          target.replaceRange(arguments[0] as int, arguments[1] as int,
              arguments[2] as Iterable);
          return null;
        case 'removeRange':
          target.removeRange(arguments[0] as int, arguments[1] as int);
          return null;
        case 'retainWhere':
          final test = arguments[0] as InterpretedFunction;
          target
              .retainWhere((element) => test.call(visitor, [element]) as bool);
          return null;
        case 'removeWhere':
          final test = arguments[0] as InterpretedFunction;
          target
              .removeWhere((element) => test.call(visitor, [element]) as bool);
          return null;
        case 'sort':
          if (arguments.isEmpty) {
            target.sort();
          } else {
            final compare = arguments[0] as InterpretedFunction;
            target.sort((a, b) => compare.call(visitor, [a, b]) as int);
          }
          return null;
        case 'shuffle':
          target.shuffle();
          return null;
        case 'asMap':
          return target.asMap();
        case 'cast':
          return target.cast<dynamic>();
        case 'followedBy':
          return target.followedBy(arguments[0] as Iterable);
        case 'elementAt':
          return target.elementAt(arguments[0] as int);
        case 'setRange':
          int skipCount = arguments.get<int>(3) ?? 0;
          target.setRange(arguments[0] as int, arguments[1] as int,
              arguments[2] as Iterable, skipCount);
          return null;
        case 'getRange':
          return target.getRange(arguments[0] as int, arguments[1] as int);
        case 'reversed':
          return target.reversed;
        case 'iterator':
          return target.iterator;
        default:
          throw RuntimeError('List has no method mapping for "$name"');
      }
    } else {
      // static methods
      switch (name) {
        case 'castFrom':
          return List.castFrom<dynamic, dynamic>(arguments[0] as List);
        case 'from':
          return List<dynamic>.from(arguments[0] as Iterable,
              growable: namedArguments.get<bool?>("growable") ?? true);
        case 'empty':
          return List<dynamic>.empty();
        case 'generate':
          final generator = arguments[1];
          if (generator is! InterpretedFunction) {
            throw RuntimeError('Expected a InterpretedFunction for generate');
          }
          return List<dynamic>.generate(
              arguments[0] as int, (i) => generator.call(visitor, [i]),
              growable: namedArguments.get<bool?>("growable") ?? true);
        case 'copyRange':
          List.copyRange(
              arguments[0] as List,
              arguments[1] as int,
              arguments[2] as List,
              arguments.get<int?>(3),
              arguments.get<int?>(4));
          return null;
        case 'filled':
          return List.filled(arguments[0] as int, arguments[1],
              growable: namedArguments.get<bool?>("growable") ?? true);
        case 'of':
          return List.of(arguments[0] as Iterable,
              growable: namedArguments.get<bool?>("growable") ?? true);
        case 'unmodifiable':
          return List<dynamic>.unmodifiable(arguments[0] as Iterable);
        case 'writeIterable':
          List.writeIterable(arguments[0] as List, arguments[1] as int,
              arguments[2] as Iterable);
          return null;
        default:
          throw RuntimeError('List has no static method mapping for "$name"');
      }
    }
  }
}
