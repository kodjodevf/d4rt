import 'package:d4rt/d4rt.dart';

class StringCore {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
        nativeType: String,
        name: 'String',
        typeParameterCount: 0,
        staticMethods: {
          'fromCharCode': (visitor, positionalArgs, namedArgs) {
            return String.fromCharCode(positionalArgs[0] as int);
          },
          'fromCharCodes': (visitor, positionalArgs, namedArgs) {
            return String.fromCharCodes(
              (positionalArgs[0] as List).cast<int>(),
              positionalArgs.length > 1 ? positionalArgs[1] as int? ?? 0 : 0,
              positionalArgs.length > 2 ? positionalArgs[2] as int? : null,
            );
          },
          'fromEnvironment': (visitor, positionalArgs, namedArgs) {
            return String.fromEnvironment(
              positionalArgs[0] as String,
              defaultValue: namedArgs['defaultValue'] as String? ?? '',
            );
          },
        },
        methods: {
          '[]': (visitor, target, positionalArgs, namedArgs) {
            if (positionalArgs.length != 1 || positionalArgs[0] is! int) {
              throw RuntimeError(
                  'String index operator [] requires one int argument.');
            }
            return (target as String)[positionalArgs[0] as int];
          },
          'substring': (visitor, target, positionalArgs, namedArgs) {
            return (target as String).substring(
              positionalArgs[0] as int,
              positionalArgs.length > 1 ? positionalArgs[1] as int? : null,
            );
          },
          'toUpperCase': (visitor, target, positionalArgs, namedArgs) {
            return (target as String).toUpperCase();
          },
          'toLowerCase': (visitor, target, positionalArgs, namedArgs) {
            return (target as String).toLowerCase();
          },
          'contains': (visitor, target, positionalArgs, namedArgs) {
            return (target as String).contains(
              positionalArgs[0] as Pattern,
              positionalArgs.length > 1 ? positionalArgs[1] as int? ?? 0 : 0,
            );
          },
          'startsWith': (visitor, target, positionalArgs, namedArgs) {
            return (target as String).startsWith(
              positionalArgs[0] as Pattern,
              positionalArgs.length > 1 ? positionalArgs[1] as int? ?? 0 : 0,
            );
          },
          'endsWith': (visitor, target, positionalArgs, namedArgs) {
            return (target as String).endsWith(positionalArgs[0] as String);
          },
          'indexOf': (visitor, target, positionalArgs, namedArgs) {
            return (target as String).indexOf(
              positionalArgs[0] as Pattern,
              positionalArgs.length > 1 ? positionalArgs[1] as int? ?? 0 : 0,
            );
          },
          'lastIndexOf': (visitor, target, positionalArgs, namedArgs) {
            return (target as String).lastIndexOf(
              positionalArgs[0] as Pattern,
              positionalArgs.length > 1 ? positionalArgs[1] as int? : null,
            );
          },
          'trim': (visitor, target, positionalArgs, namedArgs) {
            return (target as String).trim();
          },
          'trimLeft': (visitor, target, positionalArgs, namedArgs) {
            return (target as String).trimLeft();
          },
          'trimRight': (visitor, target, positionalArgs, namedArgs) {
            return (target as String).trimRight();
          },
          'replaceAll': (visitor, target, positionalArgs, namedArgs) {
            return (target as String).replaceAll(
              positionalArgs[0] as Pattern,
              positionalArgs[1] as String,
            );
          },
          'split': (visitor, target, positionalArgs, namedArgs) {
            return (target as String).split(positionalArgs[0] as Pattern);
          },
          'splitMapJoin': (visitor, target, positionalArgs, namedArgs) {
            final pattern = positionalArgs[0] as Pattern;
            final onMatch = namedArgs['onMatch'] as InterpretedFunction?;
            final onNonMatch = namedArgs['onNonMatch'] as InterpretedFunction?;
            return (target as String).splitMapJoin(
              pattern,
              onMatch: onMatch == null
                  ? null
                  : (Match m) => onMatch.call(visitor, [m]) as String,
              onNonMatch: onNonMatch == null
                  ? null
                  : (String s) => onNonMatch.call(visitor, [s]) as String,
            );
          },
          'padLeft': (visitor, target, positionalArgs, namedArgs) {
            return (target as String).padLeft(
              positionalArgs[0] as int,
              positionalArgs.length > 1
                  ? positionalArgs[1] as String? ?? ' '
                  : ' ',
            );
          },
          'padRight': (visitor, target, positionalArgs, namedArgs) {
            return (target as String).padRight(
              positionalArgs[0] as int,
              positionalArgs.length > 1
                  ? positionalArgs[1] as String? ?? ' '
                  : ' ',
            );
          },
          'replaceFirst': (visitor, target, positionalArgs, namedArgs) {
            return (target as String).replaceFirst(
              positionalArgs[0] as Pattern,
              positionalArgs[1] as String,
              positionalArgs.length > 2 ? positionalArgs[2] as int? ?? 0 : 0,
            );
          },
          'replaceRange': (visitor, target, positionalArgs, namedArgs) {
            return (target as String).replaceRange(
              positionalArgs[0] as int,
              positionalArgs.length > 1 ? positionalArgs[1] as int? : null,
              positionalArgs[2] as String,
            );
          },
          'codeUnitAt': (visitor, target, positionalArgs, namedArgs) {
            return (target as String).codeUnitAt(positionalArgs[0] as int);
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as String).toString();
          },
          'compareTo': (visitor, target, positionalArgs, namedArgs) {
            return (target as String).compareTo(positionalArgs[0] as String);
          },
          'allMatches': (visitor, target, positionalArgs, namedArgs) {
            return (target as String).allMatches(
              positionalArgs[0] as String,
              positionalArgs.length > 1 ? positionalArgs[1] as int? ?? 0 : 0,
            );
          },
          'replaceAllMapped': (visitor, target, positionalArgs, namedArgs) {
            final pattern = positionalArgs[0] as Pattern;
            final replace = positionalArgs[1];
            if (replace is! InterpretedFunction) {
              throw RuntimeError(
                  'Expected an InterpretedFunction for replaceAllMapped');
            }
            return (target as String).replaceAllMapped(pattern, (match) {
              return replace.call(visitor, [match]) as String;
            });
          },
          'replaceFirstMapped': (visitor, target, positionalArgs, namedArgs) {
            final pattern = positionalArgs[0] as Pattern;
            final replace = positionalArgs[1];
            if (replace is! InterpretedFunction) {
              throw RuntimeError(
                  'Expected an InterpretedFunction for replaceFirstMapped');
            }
            final startIndex =
                positionalArgs.length > 2 ? positionalArgs[2] as int? ?? 0 : 0;
            return (target as String).replaceFirstMapped(pattern, (match) {
              return replace.call(visitor, [match]) as String;
            }, startIndex);
          },
        },
        getters: {
          'isEmpty': (visitor, target) => (target as String).isEmpty,
          'runtimeType': (visitor, target) => (target as String).runtimeType,
          'isNotEmpty': (visitor, target) => (target as String).isNotEmpty,
          'length': (visitor, target) => (target as String).length,
          'codeUnits': (visitor, target) => (target as String).codeUnits,
          'runes': (visitor, target) => (target as String).runes,
          'hashCode': (visitor, target) => (target as String).hashCode,
        },
      );
}
