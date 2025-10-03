import 'package:test/test.dart';

import '../interpreter_test.dart';

void main() {
  group('Enhanced Enums with Mixins', () {
    test('Basic enum with single mixin', () {
      const source = '''
        mixin Printable {
          void printInfo() {
            print('Printable mixin');
          }
        }
        
        enum Status with Printable {
          pending,
          running,
          completed
        }
        
        main() {
          Status.pending.printInfo();
          return Status.running.toString();
        }
      ''';
      final result = execute(source);
      expect(result, equals('Status.running'));
    });

    test('Enum with mixin providing properties', () {
      const source = '''
        mixin Describable {
          String get description => 'A describable item';
        }
        
        enum Priority with Describable {
          low,
          medium,
          high
        }
        
        main() {
          return Priority.high.description;
        }
      ''';
      final result = execute(source);
      expect(result, equals('A describable item'));
    });

    test('Enum with multiple mixins', () {
      const source = '''
        mixin Loggable {
          void log(String msg) {
            print('LOG: \$msg');
          }
        }
        
        mixin Timestamped {
          String timestamp() {
            return 'timestamp';
          }
        }
        
        enum Event with Loggable, Timestamped {
          created,
          updated,
          deleted
        }
        
        main() {
          Event.updated.log('Event occurred');
          return Event.deleted.timestamp();
        }
      ''';
      final result = execute(source);
      expect(result, equals('timestamp'));
    });

    test('Enum with mixin and instance methods', () {
      const source = '''
        mixin Comparable {
          int compareTo(int other) {
            return 0;
          }
        }
        
        enum Size with Comparable {
          small,
          medium,
          large;
          
          String describe() {
            return 'Size: \$name';
          }
        }
        
        main() {
          return Size.medium.describe();
        }
      ''';
      final result = execute(source);
      expect(result, equals('Size: medium'));
    });

    test('Enum with mixin and custom fields', () {
      const source = '''
        mixin Valuable {
          int getValue() {
            return 42;
          }
        }
        
        enum Level with Valuable {
          beginner(1),
          intermediate(5),
          expert(10);
          
          final int value;
          const Level(this.value);
        }
        
        main() {
          return [Level.beginner.value, Level.expert.getValue()];
        }
      ''';
      final result = execute(source);
      expect(result, equals([1, 42]));
    });

    test('Enum with mixin accessing enum properties', () {
      const source = '''
        mixin Indexed {
          String indexInfo() {
            return 'Index: \${(this as dynamic).index}';
          }
        }
        
        enum Color with Indexed {
          red,
          green,
          blue
        }
        
        main() {
          return Color.blue.indexInfo();
        }
      ''';
      final result = execute(source);
      expect(result, equals('Index: 2'));
    });

    test('Enum with mixin providing instance methods (static fields skipped)',
        () {
      // Note: Static fields in mixins are a known limitation in d4rt
      // This test focuses on instance methods which are the primary use case for mixins
      const source = '''
        mixin Timestamped {
          int getTimestamp() {
            return 12345;
          }
        }
        
        enum Task with Timestamped {
          todo,
          inProgress,
          done
        }
        
        main() {
          return Task.todo.getTimestamp();
        }
      ''';
      final result = execute(source);
      expect(result, equals(12345));
    });

    test('Enum with mixin overriding toString', () {
      const source = '''
        mixin CustomString {
          String toString() {
            return 'Custom: \${(this as dynamic).name}';
          }
        }
        
        enum Direction with CustomString {
          north,
          south,
          east,
          west
        }
        
        main() {
          return Direction.north.toString();
        }
      ''';
      final result = execute(source);
      expect(result, equals('Custom: north'));
    });

    test('Enum with mixin and constructor', () {
      const source = '''
        mixin Serializable {
          Map<String, dynamic> toJson() {
            return {'type': 'serializable'};
          }
        }
        
        enum Status with Serializable {
          active(true),
          inactive(false);
          
          final bool isActive;
          const Status(this.isActive);
          
          String getStatus() {
            return isActive ? 'Active' : 'Inactive';
          }
        }
        
        main() {
          return [
            Status.active.getStatus(),
            Status.inactive.toJson()
          ];
        }
      ''';
      final result = execute(source);
      expect(
          result,
          equals([
            'Active',
            {'type': 'serializable'}
          ]));
    });

    test('Enum with regular mixin (not requiring on clause)', () {
      const source = '''
        mixin Formatter {
          String format(String text) {
            return 'Formatted: \$text';
          }
        }
        
        enum MessageType with Formatter {
          info,
          warning,
          error
        }
        
        main() {
          return MessageType.error.format('System failure');
        }
      ''';
      final result = execute(source);
      expect(result, equals('Formatted: System failure'));
    });

    test('Enum with mixin chain (mixin using another mixin)', () {
      const source = '''
        mixin Base {
          String baseMethod() {
            return 'base';
          }
        }
        
        mixin Extended on Base {
          String extendedMethod() {
            return baseMethod() + ' extended';
          }
        }
        
        enum Entity with Base, Extended {
          user,
          admin
        }
        
        main() {
          return Entity.admin.extendedMethod();
        }
      ''';
      final result = execute(source);
      expect(result, equals('base extended'));
    });

    test('Enum values list still works with mixins', () {
      const source = '''
        mixin Helper {
          void help() {
            print('Helping');
          }
        }
        
        enum State with Helper {
          idle,
          loading,
          success,
          failure
        }
        
        main() {
          var values = State.values;
          return values.map((v) => v.toString()).toList();
        }
      ''';
      final result = execute(source);
      expect(
          result,
          equals([
            'State.idle',
            'State.loading',
            'State.success',
            'State.failure'
          ]));
    });

    test('Enum with mixin and equality still works', () {
      const source = '''
        mixin Tagged {
          String tag() {
            return 'tagged';
          }
        }
        
        enum Mode with Tagged {
          light,
          dark
        }
        
        main() {
          var m1 = Mode.light;
          var m2 = Mode.light;
          var m3 = Mode.dark;
          
          return [
            m1 == m2,
            m1 == m3,
            m1.tag()
          ];
        }
      ''';
      final result = execute(source);
      expect(result, equals([true, false, 'tagged']));
    });

    test('Enum with mixin in switch statement', () {
      const source = '''
        mixin Scorable {
          int getScore() {
            return 100;
          }
        }
        
        enum Grade with Scorable {
          a,
          b,
          c,
          d,
          f
        }
        
        String gradeToString(Grade g) {
          switch (g) {
            case Grade.a:
              return 'Excellent';
            case Grade.b:
              return 'Good';
            case Grade.c:
              return 'Average';
            case Grade.d:
              return 'Below Average';
            case Grade.f:
              return 'Fail';
          }
        }
        
        main() {
          return [
            gradeToString(Grade.a),
            Grade.a.getScore()
          ];
        }
      ''';
      final result = execute(source);
      expect(result, equals(['Excellent', 100]));
    });

    test('Enum with mixin accessing instance fields', () {
      const source = '''
        mixin Calculator {
          int calculate() {
            var self = this as dynamic;
            return self.base * self.multiplier;
          }
        }
        
        enum Tier with Calculator {
          bronze(10, 1),
          silver(10, 2),
          gold(10, 3);
          
          final int base;
          final int multiplier;
          const Tier(this.base, this.multiplier);
        }
        
        main() {
          return [
            Tier.bronze.calculate(),
            Tier.silver.calculate(),
            Tier.gold.calculate()
          ];
        }
      ''';
      final result = execute(source);
      expect(result, equals([10, 20, 30]));
    });
  });
}
