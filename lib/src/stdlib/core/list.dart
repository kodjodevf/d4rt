import 'package:d4rt/d4rt.dart';

class ListCore {
  static BridgedClass get definition => BridgedClass(
        nativeType: List,
        name: 'List',
        typeParameterCount: 1,
        staticMethods: {
          'castFrom': (visitor, positionalArgs, namedArgs) {
            return List.castFrom<dynamic, dynamic>(positionalArgs[0] as List);
          },
          'from': (visitor, positionalArgs, namedArgs) {
            return List<dynamic>.from(
              positionalArgs[0] as Iterable,
              growable: namedArgs['growable'] as bool? ?? true,
            );
          },
          'empty': (visitor, positionalArgs, namedArgs) {
            bool growable = namedArgs['growable'] as bool? ?? false;
            return List<dynamic>.empty(growable: growable);
          },
          'generate': (visitor, positionalArgs, namedArgs) {
            final generator = positionalArgs[1];
            if (generator is! InterpretedFunction) {
              throw RuntimeError('Expected a InterpretedFunction for generate');
            }
            return List<dynamic>.generate(
              positionalArgs[0] as int,
              (i) => generator.call(visitor, [i]),
              growable: namedArgs['growable'] as bool? ?? true,
            );
          },
          'copyRange': (visitor, positionalArgs, namedArgs) {
            List.copyRange(
              positionalArgs[0] as List,
              positionalArgs[1] as int,
              positionalArgs[2] as List,
              positionalArgs.length > 3 ? positionalArgs[3] as int? : null,
              positionalArgs.length > 4 ? positionalArgs[4] as int? : null,
            );
            return null;
          },
          'filled': (visitor, positionalArgs, namedArgs) {
            return List.filled(
              positionalArgs[0] as int,
              positionalArgs[1],
              growable: namedArgs['growable'] as bool? ?? true,
            );
          },
          'of': (visitor, positionalArgs, namedArgs) {
            return List.of(
              positionalArgs[0] as Iterable,
              growable: namedArgs['growable'] as bool? ?? true,
            );
          },
          'unmodifiable': (visitor, positionalArgs, namedArgs) {
            return List<dynamic>.unmodifiable(positionalArgs[0] as Iterable);
          },
          'writeIterable': (visitor, positionalArgs, namedArgs) {
            List.writeIterable(
              positionalArgs[0] as List,
              positionalArgs[1] as int,
              positionalArgs[2] as Iterable,
            );
            return null;
          },
        },
        methods: {
          '[]': (visitor, target, positionalArgs, namedArgs) {
            return (target as List)[positionalArgs[0] as int];
          },
          '[]=': (visitor, target, positionalArgs, namedArgs) {
            (target as List)[positionalArgs[0] as int] = positionalArgs[1];
            return null;
          },
          'add': (visitor, target, positionalArgs, namedArgs) {
            (target as List).add(positionalArgs[0]);
            return null;
          },
          'addAll': (visitor, target, positionalArgs, namedArgs) {
            (target as List).addAll(positionalArgs[0] as Iterable);
            return null;
          },
          'remove': (visitor, target, positionalArgs, namedArgs) {
            return (target as List).remove(positionalArgs[0]);
          },
          'removeAt': (visitor, target, positionalArgs, namedArgs) {
            return (target as List).removeAt(positionalArgs[0] as int);
          },
          'removeLast': (visitor, target, positionalArgs, namedArgs) {
            return (target as List).removeLast();
          },
          'clear': (visitor, target, positionalArgs, namedArgs) {
            (target as List).clear();
            return null;
          },
          'contains': (visitor, target, positionalArgs, namedArgs) {
            return (target as List).contains(positionalArgs[0]);
          },
          'indexOf': (visitor, target, positionalArgs, namedArgs) {
            int start =
                positionalArgs.length == 2 ? positionalArgs[1] as int : 0;
            return (target as List).indexOf(positionalArgs[0], start);
          },
          'lastIndexOf': (visitor, target, positionalArgs, namedArgs) {
            int? start =
                positionalArgs.length == 2 ? positionalArgs[1] as int? : null;
            return (target as List).lastIndexOf(positionalArgs[0], start);
          },
          'sublist': (visitor, target, positionalArgs, namedArgs) {
            int? end =
                positionalArgs.length == 2 ? positionalArgs[1] as int? : null;
            return (target as List).sublist(positionalArgs[0] as int, end);
          },
          'forEach': (visitor, target, positionalArgs, namedArgs) {
            final callback = positionalArgs[0];
            if (callback is! Callable) {
              throw RuntimeError('Expected a Callable for forEach');
            }
            for (final element in target as List) {
              callback.call(visitor, [element], {});
            }
            return null;
          },
          'any': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as Callable;
            return (target as List)
                .any((element) => test.call(visitor, [element], {}) as bool);
          },
          'every': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as Callable;
            return (target as List)
                .every((element) => test.call(visitor, [element], {}) as bool);
          },
          'map': (visitor, target, positionalArgs, namedArgs) {
            final toElement = positionalArgs[0] as Callable;
            return (target as List)
                .map((element) => toElement.call(visitor, [element], {}));
          },
          'indexWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as Callable;
            return (target as List).indexWhere(
                (element) => test.call(visitor, [element], {}) as bool,
                positionalArgs.optional<int>(1, 'start', 0));
          },
          'lastIndexWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as Callable;
            return (target as List).lastIndexWhere(
                (element) => test.call(visitor, [element], {}) as bool,
                positionalArgs.optional<int?>(1, 'start', null));
          },
          'where': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as Callable;
            return (target as List)
                .where((element) => test.call(visitor, [element], {}) as bool);
          },
          'expand': (visitor, target, positionalArgs, namedArgs) {
            final toElements = positionalArgs[0] as Callable;
            return (target as List).expand((element) =>
                toElements.call(visitor, [element], {}) as Iterable);
          },
          'reduce': (visitor, target, positionalArgs, namedArgs) {
            final combine = positionalArgs[0] as Callable;
            return (target as List).reduce((value, element) =>
                combine.call(visitor, [value, element], {}));
          },
          'fold': (visitor, target, positionalArgs, namedArgs) {
            final initialValue = positionalArgs[0];
            final combine = positionalArgs[1] as Callable;
            return (target as List).fold(
              initialValue,
              (previousValue, element) =>
                  combine.call(visitor, [previousValue, element], {}),
            );
          },
          'join': (visitor, target, positionalArgs, namedArgs) {
            final separator =
                positionalArgs.isNotEmpty ? positionalArgs[0] as String : '';
            return (target as List).join(separator);
          },
          'take': (visitor, target, positionalArgs, namedArgs) {
            return (target as List).take(positionalArgs[0] as int);
          },
          'takeWhile': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as Callable;
            return (target as List)
                .takeWhile((value) => test.call(visitor, [value], {}) as bool);
          },
          'skip': (visitor, target, positionalArgs, namedArgs) {
            return (target as List).skip(positionalArgs[0] as int);
          },
          'skipWhile': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as Callable;
            return (target as List)
                .skipWhile((value) => test.call(visitor, [value], {}) as bool);
          },
          'toList': (visitor, target, positionalArgs, namedArgs) {
            return (target as List)
                .toList(growable: namedArgs['growable'] as bool? ?? true);
          },
          'toSet': (visitor, target, positionalArgs, namedArgs) {
            return (target as List).toSet();
          },
          'firstWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as Callable;
            final orElse = namedArgs['orElse'] as Callable?;

            // Implémentation manuelle pour éviter les problèmes de types génériques
            final list = target as List;
            for (final element in list) {
              if (test.call(visitor, [element], {}) as bool) {
                return element;
              }
            }

            // Si aucun élément trouvé, utilise orElse ou lance une exception
            if (orElse != null) {
              return orElse.call(visitor, [], {});
            } else {
              throw RuntimeError(
                  'No element found matching the test condition');
            }
          },
          'lastWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as Callable;
            final orElse = namedArgs['orElse'] as Callable?;
            return (target as List).lastWhere(
              (element) => test.call(visitor, [element], {}) as bool,
              orElse:
                  orElse == null ? null : () => orElse.call(visitor, [], {}),
            );
          },
          'singleWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as Callable;
            final orElse = namedArgs['orElse'] as Callable?;
            return (target as List).singleWhere(
              (element) => test.call(visitor, [element], {}) as bool,
              orElse:
                  orElse == null ? null : () => orElse.call(visitor, [], {}),
            );
          },
          'insert': (visitor, target, positionalArgs, namedArgs) {
            (target as List)
                .insert(positionalArgs[0] as int, positionalArgs[1]);
            return null;
          },
          'insertAll': (visitor, target, positionalArgs, namedArgs) {
            (target as List).insertAll(
                positionalArgs[0] as int, positionalArgs[1] as Iterable);
            return null;
          },
          'setAll': (visitor, target, positionalArgs, namedArgs) {
            (target as List).setAll(
                positionalArgs[0] as int, positionalArgs[1] as Iterable);
            return null;
          },
          'fillRange': (visitor, target, positionalArgs, namedArgs) {
            (target as List).fillRange(
              positionalArgs[0] as int,
              positionalArgs[1] as int,
              positionalArgs.length > 2 ? positionalArgs[2] : null,
            );
            return null;
          },
          'replaceRange': (visitor, target, positionalArgs, namedArgs) {
            (target as List).replaceRange(
              positionalArgs[0] as int,
              positionalArgs[1] as int,
              positionalArgs[2] as Iterable,
            );
            return null;
          },
          'removeRange': (visitor, target, positionalArgs, namedArgs) {
            (target as List).removeRange(
                positionalArgs[0] as int, positionalArgs[1] as int);
            return null;
          },
          'retainWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as Callable;
            (target as List).retainWhere(
                (element) => test.call(visitor, [element], {}) as bool);
            return null;
          },
          'removeWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as Callable;
            (target as List).removeWhere(
                (element) => test.call(visitor, [element], {}) as bool);
            return null;
          },
          'sort': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty) {
              (target as List).sort();
            } else {
              final compare = positionalArgs[0] as Callable;
              (target as List)
                  .sort((a, b) => compare.call(visitor, [a, b], {}) as int);
            }
            return null;
          },
          'shuffle': (visitor, target, positionalArgs, namedArgs) {
            (target as List).shuffle();
            return null;
          },
          'asMap': (visitor, target, positionalArgs, namedArgs) {
            return (target as List).asMap();
          },
          'cast': (visitor, target, positionalArgs, namedArgs) {
            return (target as List).cast<dynamic>();
          },
          'followedBy': (visitor, target, positionalArgs, namedArgs) {
            return (target as List).followedBy(positionalArgs[0] as Iterable);
          },
          'elementAt': (visitor, target, positionalArgs, namedArgs) {
            return (target as List).elementAt(positionalArgs[0] as int);
          },
          'setRange': (visitor, target, positionalArgs, namedArgs) {
            int skipCount =
                positionalArgs.length > 3 ? positionalArgs[3] as int? ?? 0 : 0;
            (target as List).setRange(
              positionalArgs[0] as int,
              positionalArgs[1] as int,
              positionalArgs[2] as Iterable,
              skipCount,
            );
            return null;
          },
          'getRange': (visitor, target, positionalArgs, namedArgs) {
            return (target as List)
                .getRange(positionalArgs[0] as int, positionalArgs[1] as int);
          },
        },
        getters: {
          'length': (visitor, target) => (target as List).length,
          'isEmpty': (visitor, target) => (target as List).isEmpty,
          'isNotEmpty': (visitor, target) => (target as List).isNotEmpty,
          'first': (visitor, target) => (target as List).first,
          'last': (visitor, target) => (target as List).last,
          'single': (visitor, target) => (target as List).single,
          'reversed': (visitor, target) => (target as List).reversed,
          'iterator': (visitor, target) => (target as List).iterator,
          'runtimeType': (visitor, target) => (target as List).runtimeType,
          'hashCode': (visitor, target) => (target as List).hashCode,
        },
        setters: {
          'length': (visitor, target, value) {
            (target as List).length = value as int;
          },
          'first': (visitor, target, value) {
            (target as List).first = value;
          },
          'last': (visitor, target, value) {
            (target as List).last = value;
          },
        },
      );
}
