import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('Comprehensive Null Safety Tests', () {
    late D4rt d4rt;

    setUp(() {
      d4rt = D4rt();
    });

    test('complex null safety scenario with chaining and coalescing', () {
      final result = d4rt.execute(source: '''
        class User {
          String? name;
          Profile? profile;
          
          User(this.name, this.profile);
        }
        
        class Profile {
          String? bio;
          Address? address;
          
          Profile(this.bio, this.address);
        }
        
        class Address {
          String? street;
          String? city;
          
          Address(this.street, this.city);
        }
        
        main() {
          User? user1 = null;
          User? user2 = User('John', null);
          User? user3 = User('Jane', Profile('Developer', Address('123 Main St', 'NYC')));
          
          // Test chained null-aware access
          var street1 = user1?.profile?.address?.street;
          var street2 = user2?.profile?.address?.street;
          var street3 = user3?.profile?.address?.street;
          
          // Test null coalescing with chained access
          var defaultStreet = user1?.profile?.address?.street ?? 'Unknown';
          
          // Test null assertion where we know it's safe
          var knownStreet = user3!.profile!.address!.street!;
          
          return [street1, street2, street3, defaultStreet, knownStreet];
        }
      ''');

      expect(result, [null, null, '123 Main St', 'Unknown', '123 Main St']);
    });

    test('null-aware method calls with complex return types', () {
      final result = d4rt.execute(source: '''
        class Calculator {
          int? getValue() => 42;
          Calculator? getChild() => null;
        }
        
        main() {
          Calculator? calc1 = null;
          Calculator? calc2 = Calculator();
          
          var result1 = calc1?.getValue();
          var result2 = calc2?.getValue();
          var result3 = calc2?.getChild()?.getValue();
          
          return [result1, result2, result3];
        }
      ''');

      expect(result, [null, 42, null]);
    });
    test('null-aware assignment with complex expressions', () {
      final result = d4rt.execute(source: '''
        class Container {
          String? value = null;
        }
        
        main() {
          Container? container = Container();
          
          // Multiple null-aware assignments
          container.value ??= 'first';
          container.value ??= 'second';  // Should not override
          
          String? nullValue = null;
          nullValue ??= 'assigned';
          
          String? nonNullValue = 'original';
          nonNullValue ??= 'not assigned';
          
          return [container.value, nullValue, nonNullValue];
        }
      ''');

      expect(result, ['first', 'assigned', 'original']);
    });

    test('spread null-aware with nested collections', () {
      final result = d4rt.execute(source: '''
        main() {
          List<int>? nullList = null;
          List<int>? validList = [4, 5];
          List<int>? anotherNull = null;
          
          var combined = [1, 2, ...?nullList, 3, ...?validList, ...?anotherNull, 6];
          
          return combined;
        }
      ''');

      expect(result, [1, 2, 3, 4, 5, 6]);
    });

    test('mixed null safety operators in single expression', () {
      final result = d4rt.execute(source: '''
        class Service {
          String? getData() => null;
          String? getBackup() => 'backup';
        }
        
        main() {
          Service? service = Service();
          
          // Complex expression: null-aware call + coalescing + null assertion
          var data = (service?.getData() ?? service?.getBackup())!;
          
          return data;
        }
      ''');

      expect(result, 'backup');
    });

    test('null safety with method parameters and return values', () {
      final result = d4rt.execute(source: '''
        class Processor {
          String? process(String? input) {
            if (input == null) return null;
            return 'processed: ' + input;
          }
        }
        
        main() {
          Processor? processor = Processor();
          
          var result1 = processor?.process(null);
          var result2 = processor?.process('test');
          
          // Chain with null coalescing
          var final1 = processor?.process(null) ?? 'default';
          var final2 = processor?.process('test') ?? 'default';
          
          return [result1, result2, final1, final2];
        }
      ''');

      expect(result, [null, 'processed: test', 'default', 'processed: test']);
    });

    test('null safety with collection operations', () {
      final result = d4rt.execute(source: '''
        main() {
          List<String>? names1 = null;
          List<String>? names2 = ['Alice', 'Bob'];
          List<String>? names3 = null;
          List<String>? names4 = ['Charlie'];
          
          // Multiple null-aware spreads in a single collection
          var allNames = [
            'Start',
            ...?names1,
            ...?names2,
            'Middle',
            ...?names3,
            ...?names4,
            'End'
          ];
          
          return allNames;
        }
      ''');

      expect(result, ['Start', 'Alice', 'Bob', 'Middle', 'Charlie', 'End']);
    });
  });
}
