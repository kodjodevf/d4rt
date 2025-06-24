import 'package:d4rt/src/bridge/registration.dart';

class RunesCore {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: Runes,
        name: 'Runes',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            return Runes(positionalArgs[0] as String);
          },
        },
        methods: {
          'iterator': (visitor, target, positionalArgs, namedArgs) {
            return (target as Runes).iterator;
          },
          'contains': (visitor, target, positionalArgs, namedArgs) {
            return (target as Runes).contains(positionalArgs[0]);
          },
          'elementAt': (visitor, target, positionalArgs, namedArgs) {
            return (target as Runes).elementAt(positionalArgs[0] as int);
          },
          'every': (visitor, target, positionalArgs, namedArgs) {
            return (target as Runes)
                .every(positionalArgs[0] as bool Function(int));
          },
          'any': (visitor, target, positionalArgs, namedArgs) {
            return (target as Runes)
                .any(positionalArgs[0] as bool Function(int));
          },
          'expand': (visitor, target, positionalArgs, namedArgs) {
            return (target as Runes)
                .expand(positionalArgs[0] as Iterable<dynamic> Function(int));
          },
          'firstWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as bool Function(int);
            final orElse = namedArgs['orElse'] as int Function()?;
            return (target as Runes).firstWhere(test, orElse: orElse);
          },
          'lastWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as bool Function(int);
            final orElse = namedArgs['orElse'] as int Function()?;
            return (target as Runes).lastWhere(test, orElse: orElse);
          },
          'singleWhere': (visitor, target, positionalArgs, namedArgs) {
            final test = positionalArgs[0] as bool Function(int);
            final orElse = namedArgs['orElse'] as int Function()?;
            return (target as Runes).singleWhere(test, orElse: orElse);
          },
          'forEach': (visitor, target, positionalArgs, namedArgs) {
            (target as Runes).forEach(positionalArgs[0] as void Function(int));
            return null;
          },
          'map': (visitor, target, positionalArgs, namedArgs) {
            return (target as Runes)
                .map(positionalArgs[0] as dynamic Function(int));
          },
          'where': (visitor, target, positionalArgs, namedArgs) {
            return (target as Runes)
                .where(positionalArgs[0] as bool Function(int));
          },
          'whereType': (visitor, target, positionalArgs, namedArgs) {
            return (target as Runes).whereType();
          },
          'skip': (visitor, target, positionalArgs, namedArgs) {
            return (target as Runes).skip(positionalArgs[0] as int);
          },
          'skipWhile': (visitor, target, positionalArgs, namedArgs) {
            return (target as Runes)
                .skipWhile(positionalArgs[0] as bool Function(int));
          },
          'take': (visitor, target, positionalArgs, namedArgs) {
            return (target as Runes).take(positionalArgs[0] as int);
          },
          'takeWhile': (visitor, target, positionalArgs, namedArgs) {
            return (target as Runes)
                .takeWhile(positionalArgs[0] as bool Function(int));
          },
          'toList': (visitor, target, positionalArgs, namedArgs) {
            final growable = namedArgs['growable'] as bool? ?? true;
            return (target as Runes).toList(growable: growable);
          },
          'toSet': (visitor, target, positionalArgs, namedArgs) {
            return (target as Runes).toSet();
          },
          'fold': (visitor, target, positionalArgs, namedArgs) {
            return (target as Runes).fold(positionalArgs[0],
                positionalArgs[1] as dynamic Function(dynamic, int));
          },
          'reduce': (visitor, target, positionalArgs, namedArgs) {
            return (target as Runes)
                .reduce(positionalArgs[0] as int Function(int, int));
          },
          'join': (visitor, target, positionalArgs, namedArgs) {
            final separator =
                positionalArgs.isNotEmpty ? positionalArgs[0] as String : '';
            return (target as Runes).join(separator);
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as Runes).toString();
          },
          'cast': (visitor, target, positionalArgs, namedArgs) {
            return (target as Runes).cast();
          },
          'followedBy': (visitor, target, positionalArgs, namedArgs) {
            return (target as Runes)
                .followedBy(positionalArgs[0] as Iterable<int>);
          },
        },
        getters: {
          'length': (visitor, target) {
            return (target as Runes).length;
          },
          'isEmpty': (visitor, target) {
            return (target as Runes).isEmpty;
          },
          'isNotEmpty': (visitor, target) {
            return (target as Runes).isNotEmpty;
          },
          'first': (visitor, target) {
            return (target as Runes).first;
          },
          'last': (visitor, target) {
            return (target as Runes).last;
          },
          'single': (visitor, target) {
            return (target as Runes).single;
          },
          'string': (visitor, target) {
            return (target as Runes).string;
          },
          'hashCode': (visitor, target) {
            return (target as Runes).hashCode;
          },
          'runtimeType': (visitor, target) {
            return (target as Runes).runtimeType;
          },
        },
      );
}
