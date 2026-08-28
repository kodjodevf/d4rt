import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

enum NativeTestEnum { first, second, third }

void main() {
  group('Enum Switch Tests', () {
    late D4rt d4rt;

    setUp(() {
      d4rt = D4rt();
      d4rt.registerBridgedEnum(
        BridgedEnumDefinition<NativeTestEnum>(
          name: 'NativeTestEnum',
          values: NativeTestEnum.values,
          getters: {
            'name': (visitor, target) => (target as NativeTestEnum).name,
            'index': (visitor, target) => (target as NativeTestEnum).index,
          },
        ),
        'package:test/enums.dart',
      );
    });

    test('Interpreted enum in switch statement and expression', () {
      final result = d4rt.execute(source: '''
        enum Status { pending, active, completed }

        String getStatusLabel(Status s) {
          switch (s) {
            case Status.pending:
              return 'Pending';
            case Status.active:
              return 'Active';
            case Status.completed:
              return 'Completed';
          }
          return 'Unknown';
        }

        String getStatusExpr(Status s) => switch (s) {
          Status.pending => 'PendingExpr',
          Status.active => 'ActiveExpr',
          Status.completed => 'CompletedExpr',
          _ => 'UnknownExpr',
        };

        main() {
          return [
            getStatusLabel(Status.pending),
            getStatusLabel(Status.active),
            getStatusLabel(Status.completed),
            getStatusExpr(Status.pending),
            getStatusExpr(Status.active),
            getStatusExpr(Status.completed),
          ];
        }
      ''') as List;

      expect(result, equals([
        'Pending',
        'Active',
        'Completed',
        'PendingExpr',
        'ActiveExpr',
        'CompletedExpr',
      ]));
    });

    test('Bridged enum in switch statement and expression', () {
      final result = d4rt.execute(
        source: '''
          import 'package:test/enums.dart';

          String getNativeLabel(NativeTestEnum e) {
            switch (e) {
              case NativeTestEnum.first:
                return 'First';
              case NativeTestEnum.second:
                return 'Second';
              case NativeTestEnum.third:
                return 'Third';
            }
            return 'Unknown';
          }

          String getNativeExpr(NativeTestEnum e) => switch (e) {
            NativeTestEnum.first => 'FirstExpr',
            NativeTestEnum.second => 'SecondExpr',
            NativeTestEnum.third => 'ThirdExpr',
            _ => 'UnknownExpr',
          };

          main() {
            return [
              getNativeLabel(NativeTestEnum.first),
              getNativeLabel(NativeTestEnum.second),
              getNativeLabel(NativeTestEnum.third),
              getNativeExpr(NativeTestEnum.first),
              getNativeExpr(NativeTestEnum.second),
              getNativeExpr(NativeTestEnum.third),
            ];
          }
        ''',
      ) as List;

      expect(result, equals([
        'First',
        'Second',
        'Third',
        'FirstExpr',
        'SecondExpr',
        'ThirdExpr',
      ]));
    });
  });
}
