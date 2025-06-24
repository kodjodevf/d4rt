import 'package:d4rt/d4rt.dart';

class RegExpCore {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: RegExp,
        name: 'RegExp',
        typeParameterCount: 0,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            final source = positionalArgs[0] as String;
            final multiLine = namedArgs['multiLine'] as bool? ?? false;
            final caseSensitive = namedArgs['caseSensitive'] as bool? ?? true;
            final unicode = namedArgs['unicode'] as bool? ?? false;
            final dotAll = namedArgs['dotAll'] as bool? ?? false;
            return RegExp(source,
                multiLine: multiLine,
                caseSensitive: caseSensitive,
                unicode: unicode,
                dotAll: dotAll);
          },
        },
        staticMethods: {
          'escape': (visitor, positionalArgs, namedArgs) {
            return RegExp.escape(positionalArgs[0] as String);
          },
        },
        methods: {
          'hasMatch': (visitor, target, positionalArgs, namedArgs) {
            return (target as RegExp).hasMatch(positionalArgs[0] as String);
          },
          'firstMatch': (visitor, target, positionalArgs, namedArgs) {
            return (target as RegExp).firstMatch(positionalArgs[0] as String);
          },
          'allMatches': (visitor, target, positionalArgs, namedArgs) {
            final input = positionalArgs[0] as String;
            final start =
                positionalArgs.length > 1 ? positionalArgs[1] as int : 0;
            return (target as RegExp).allMatches(input, start);
          },
          'stringMatch': (visitor, target, positionalArgs, namedArgs) {
            return (target as RegExp).stringMatch(positionalArgs[0] as String);
          },
          'matchAsPrefix': (visitor, target, positionalArgs, namedArgs) {
            final string = positionalArgs[0] as String;
            final start =
                positionalArgs.length > 1 ? positionalArgs[1] as int : 0;
            return (target as RegExp).matchAsPrefix(string, start);
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as RegExp).toString();
          },
          'noSuchMethod': (visitor, target, positionalArgs, namedArgs) {
            return (target as RegExp)
                .noSuchMethod(positionalArgs[0] as Invocation);
          },
          '==': (visitor, target, positionalArgs, namedArgs) {
            return (target as RegExp) == positionalArgs[0];
          },
        },
        getters: {
          'pattern': (visitor, target) => (target as RegExp).pattern,
          'isMultiLine': (visitor, target) => (target as RegExp).isMultiLine,
          'isCaseSensitive': (visitor, target) =>
              (target as RegExp).isCaseSensitive,
          'isUnicode': (visitor, target) => (target as RegExp).isUnicode,
          'isDotAll': (visitor, target) => (target as RegExp).isDotAll,
          'hashCode': (visitor, target) => (target as RegExp).hashCode,
          'runtimeType': (visitor, target) => (target as RegExp).runtimeType,
        },
      );
}

class RegExpMatchCore {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: RegExpMatch,
        name: 'RegExpMatch',
        typeParameterCount: 0,
        constructors: {},
        methods: {
          // Methods inherited from Match
          'group': (visitor, target, positionalArgs, namedArgs) {
            return (target as RegExpMatch).group(positionalArgs[0] as int);
          },
          'groups': (visitor, target, positionalArgs, namedArgs) {
            return (target as RegExpMatch)
                .groups(positionalArgs[0] as List<int>);
          },
          '[]': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! int) {
              throw RuntimeError(
                  'RegExpMatch index operator [] requires one integer argument (group index).');
            }
            return (target as RegExpMatch)[positionalArgs[0] as int];
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as RegExpMatch).toString();
          },
          'noSuchMethod': (visitor, target, positionalArgs, namedArgs) {
            return (target as RegExpMatch)
                .noSuchMethod(positionalArgs[0] as Invocation);
          },
          '==': (visitor, target, positionalArgs, namedArgs) {
            return (target as RegExpMatch) == positionalArgs[0];
          },
          // RegExpMatch-specific methods
          'namedGroup': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
              throw RuntimeError(
                  'RegExpMatch.namedGroup requires one String argument (group name).');
            }
            return (target as RegExpMatch)
                .namedGroup(positionalArgs[0] as String);
          },
        },
        getters: {
          // Properties inherited from Match
          'end': (visitor, target) => (target as RegExpMatch).end,
          'groupCount': (visitor, target) => (target as RegExpMatch).groupCount,
          'input': (visitor, target) => (target as RegExpMatch).input,
          'start': (visitor, target) => (target as RegExpMatch).start,
          'hashCode': (visitor, target) => (target as RegExpMatch).hashCode,
          'runtimeType': (visitor, target) =>
              (target as RegExpMatch).runtimeType,
          // pattern property returns RegExp instead of Pattern for RegExpMatch
          'pattern': (visitor, target) => (target as RegExpMatch).pattern,
          // RegExpMatch-specific properties
          'groupNames': (visitor, target) => (target as RegExpMatch).groupNames,
        },
      );
}
