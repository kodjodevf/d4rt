import 'package:d4rt/d4rt.dart';

class IterableCore {
  static BridgedClass get definition => BridgedClass(
        nativeType: Iterable,
        name: 'Iterable',
        typeParameterCount: 1,
        nativeNames: [
          '_GeneratorIterable',
          '_HashMapKeyIterable',
          '_HashMapValueIterable',
          '_CompactKeysIterable',
          '_CompactEntriesIterable',
          '_CompactValuesIterable',
          '_SplayTreeKeyIterable',
          '_SplayTreeValueIterable',
          '_AllMatchesIterable',
          '_SyncGeneratorIterable',
        ],
        staticMethods: {
          'generate': (visitor, positionalArgs, namedArgs) {
            final count = positionalArgs[0] as int;
            final generator = positionalArgs.length > 1
                ? positionalArgs[1] as InterpretedFunction?
                : null;

            return Iterable.generate(
                count,
                generator == null
                    ? null
                    : (index) {
                        return generator.call(visitor, [index]);
                      });
          },
          'empty': (visitor, positionalArgs, namedArgs) {
            return Iterable.empty();
          },
        },
        methods: {
          'map': (visitor, target, positionalArgs, namedArgs) {
            final f = positionalArgs[0] as InterpretedFunction;
            return (target as Iterable).map((element) {
              return f.call(visitor, [element]);
            });
          },
          'where': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            return (target as Iterable).where((element) {
              return test.call(visitor, [element]) as bool;
            });
          },
          'expand': (visitor, target, positionalArgs, namedArgs) {
            final f = positionalArgs[0] as InterpretedFunction;
            return (target as Iterable).expand((element) {
              return f.call(visitor, [element]) as Iterable;
            });
          },
          'contains': (visitor, target, positionalArgs, namedArgs) {
            return (target as Iterable).contains(positionalArgs[0]);
          },
          'forEach': (visitor, target, positionalArgs, namedArgs) {
            final action = positionalArgs[0] as InterpretedFunction;
            for (var element in (target as Iterable)) {
              action.call(visitor, [element]);
            }
            return null;
          },
          'reduce': (visitor, target, positionalArgs, namedArgs) {
            final combine = positionalArgs[0] as InterpretedFunction;
            return (target as Iterable).reduce((value, element) {
              return combine.call(visitor, [value, element]);
            });
          },
          'fold': (visitor, target, positionalArgs, namedArgs) {
            final initialValue = positionalArgs[0];
            final combine = positionalArgs[1] as InterpretedFunction;
            return (target as Iterable).fold(initialValue,
                (previousValue, element) {
              return combine.call(visitor, [previousValue, element]);
            });
          },
          'every': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            return (target as Iterable).every((element) {
              return test.call(visitor, [element]) as bool;
            });
          },
          'join': (visitor, target, positionalArgs, namedArgs) {
            final separator =
                positionalArgs.isNotEmpty ? positionalArgs[0] as String : '';
            return (target as Iterable).join(separator);
          },
          'any': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            return (target as Iterable).any((element) {
              return test.call(visitor, [element]) as bool;
            });
          },
          'toList': (visitor, target, positionalArgs, namedArgs) {
            final growable = namedArgs['growable'] as bool? ?? true;
            return (target as Iterable).toList(growable: growable);
          },
          'toSet': (visitor, target, positionalArgs, namedArgs) {
            return (target as Iterable).toSet();
          },
          'take': (visitor, target, positionalArgs, namedArgs) {
            return (target as Iterable).take(positionalArgs[0] as int);
          },
          'takeWhile': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            return (target as Iterable).takeWhile((element) {
              return test.call(visitor, [element]) as bool;
            });
          },
          'skip': (visitor, target, positionalArgs, namedArgs) {
            return (target as Iterable).skip(positionalArgs[0] as int);
          },
          'skipWhile': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            return (target as Iterable).skipWhile((element) {
              return test.call(visitor, [element]) as bool;
            });
          },
          'firstWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            final orElse = namedArgs['orElse'] as InterpretedFunction?;
            return (target as Iterable).firstWhere(
              (element) => test.call(visitor, [element]) as bool,
              orElse: orElse == null ? null : () => orElse.call(visitor, []),
            );
          },
          'lastWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            final orElse = namedArgs['orElse'] as InterpretedFunction?;
            return (target as Iterable).lastWhere(
              (element) => test.call(visitor, [element]) as bool,
              orElse: orElse == null ? null : () => orElse.call(visitor, []),
            );
          },
          'singleWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as InterpretedFunction;
            final orElse = namedArgs['orElse'] as InterpretedFunction?;
            return (target as Iterable).singleWhere(
              (element) => test.call(visitor, [element]) as bool,
              orElse: orElse == null ? null : () => orElse.call(visitor, []),
            );
          },
          'elementAt': (visitor, target, positionalArgs, namedArgs) {
            return (target as Iterable).elementAt(positionalArgs[0] as int);
          },
          'followedBy': (visitor, target, positionalArgs, namedArgs) {
            return (target as Iterable)
                .followedBy(positionalArgs[0] as Iterable);
          },
          'whereType': (visitor, target, positionalArgs, namedArgs) {
            return (target as Iterable).whereType();
          },
          'cast': (visitor, target, positionalArgs, namedArgs) {
            return (target as Iterable).cast();
          },
        },
        getters: {
          'length': (visitor, target) => (target as Iterable).length,
          'isEmpty': (visitor, target) => (target as Iterable).isEmpty,
          'isNotEmpty': (visitor, target) => (target as Iterable).isNotEmpty,
          'first': (visitor, target) => (target as Iterable).first,
          'last': (visitor, target) => (target as Iterable).last,
          'single': (visitor, target) => (target as Iterable).single,
          'iterator': (visitor, target) => (target as Iterable).iterator,
        },
      );
}
