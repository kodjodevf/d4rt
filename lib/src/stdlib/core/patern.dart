import 'package:d4rt/d4rt.dart';

class PatternCore {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: Pattern,
        name: 'Pattern',
        typeParameterCount: 0,
        constructors: {},
        methods: {
          'allMatches': (visitor, target, positionalArgs, namedArgs) {
            return (target as Pattern).allMatches(
                positionalArgs[0] as String, positionalArgs.get<int>(1) ?? 0);
          },
          'matchAsPrefix': (visitor, target, positionalArgs, namedArgs) {
            return (target as Pattern).matchAsPrefix(
                positionalArgs[0] as String, positionalArgs.get<int>(1) ?? 0);
          },
          'hashCode': (visitor, target, positionalArgs, namedArgs) =>
              (target as Pattern).hashCode,
          'toString': (visitor, target, positionalArgs, namedArgs) =>
              (target as Pattern).toString(),
        },
        getters: {
          'hashCode': (visitor, target) => (target as Pattern).hashCode,
          'runtimeType': (visitor, target) => (target as Pattern).runtimeType,
        },
      );
}

class MatchCore {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: Match,
        name: 'Match',
        typeParameterCount: 0,
        constructors: {},
        methods: {
          'group': (visitor, target, positionalArgs, namedArgs) {
            return (target as Match).group(positionalArgs[0] as int);
          },
          'groups': (visitor, target, positionalArgs, namedArgs) {
            return (target as Match).groups(positionalArgs[0] as List<int>);
          },
          '[]': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! int) {
              throw RuntimeError(
                  'Match index operator [] requires one integer argument (group index).');
            }
            return (target as Match)[positionalArgs[0] as int];
          },
          'hashCode': (visitor, target, positionalArgs, namedArgs) =>
              (target as Match).hashCode,
          'toString': (visitor, target, positionalArgs, namedArgs) =>
              (target as Match).toString(),
        },
        getters: {
          'end': (visitor, target) => (target as Match).end,
          'groupCount': (visitor, target) => (target as Match).groupCount,
          'input': (visitor, target) => (target as Match).input,
          'start': (visitor, target) => (target as Match).start,
          'pattern': (visitor, target) => (target as Match).pattern,
          'hashCode': (visitor, target) => (target as Match).hashCode,
          'runtimeType': (visitor, target) => (target as Match).runtimeType,
        },
      );
}
