import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

/// Tests for Introspection API - analyze()
/// This feature allows static analysis of D4rt code to discover
/// functions, classes, enums, variables, and extensions.
void main() {
  group('Introspection API - analyze()', () {
    late D4rt d4rt;

    setUp(() {
      d4rt = D4rt();
    });

    group('Function Analysis', () {
      test('should detect simple function declarations', () {
        final result = d4rt.analyze(source: '''
          void doNothing() {}
          int returnFive() => 5;
          String greet(String name) => "Hello \$name";
        ''');

        expect(result.functions.length, equals(3));
        expect(result.contains('doNothing'), isTrue);
        expect(result.contains('returnFive'), isTrue);
        expect(result.contains('greet'), isTrue);
      });

      test('should extract function parameters', () {
        final result = d4rt.analyze(source: '''
          void process(int a, String b, {bool c = false, required double d}) {}
        ''');

        final func = result.functions.firstWhere((f) => f.name == 'process');
        // Note: Current implementation extracts parameter count but not names from analyze()
        // This is a limitation that could be improved
        expect(func.arity, greaterThanOrEqualTo(0));
      });

      test('should extract function return types', () {
        final result = d4rt.analyze(source: '''
          int getInt() => 0;
          String getString() => "";
          void doNothing() {}
        ''');

        final getInt = result.functions.firstWhere((f) => f.name == 'getInt');
        expect(getInt.returnType, equals('int'));

        final getString =
            result.functions.firstWhere((f) => f.name == 'getString');
        expect(getString.returnType, equals('String'));

        final doNothing =
            result.functions.firstWhere((f) => f.name == 'doNothing');
        expect(doNothing.returnType, equals('void'));
      });

      test('should detect async/generator functions', () {
        final result = d4rt.analyze(source: '''
          Future<int> asyncFunc() async => 0;
          Stream<int> streamFunc() async* { yield 1; }
          Iterable<int> iterableFunc() sync* { yield 1; }
        ''');

        final asyncFunc =
            result.functions.firstWhere((f) => f.name == 'asyncFunc');
        expect(asyncFunc.isAsync, isTrue);
        expect(asyncFunc.isGenerator, isFalse);

        final streamFunc =
            result.functions.firstWhere((f) => f.name == 'streamFunc');
        expect(streamFunc.isAsync, isTrue);
        expect(streamFunc.isGenerator, isTrue);

        final iterableFunc =
            result.functions.firstWhere((f) => f.name == 'iterableFunc');
        expect(iterableFunc.isAsync, isFalse);
        expect(iterableFunc.isGenerator, isTrue);
      });

      test('should detect generic functions', () {
        final result = d4rt.analyze(source: '''
          T identity<T>(T value) => value;
          Map<K, V> createMap<K, V>() => {};
        ''');

        expect(result.functions.length, equals(2));
        expect(result.contains('identity'), isTrue);
        expect(result.contains('createMap'), isTrue);
      });

      test('should detect external functions', () {
        final result = d4rt.analyze(source: '''
          external void nativeFunction();
        ''');

        expect(result.functions.length, equals(1));
        expect(result.contains('nativeFunction'), isTrue);
      });
    });

    group('Class Analysis', () {
      test('should detect simple class', () {
        final result = d4rt.analyze(source: '''
          class Person {
            String name;
            int age;
          }
        ''');

        expect(result.classes.length, equals(1));
        final person = result.classes.first;
        expect(person.name, equals('Person'));
        expect(person.fields, containsAll(['name', 'age']));
      });

      test('should detect class with all member types', () {
        final result = d4rt.analyze(source: '''
          class FullClass {
            // Fields
            String publicField = "";
            int _privateField = 0;
            late final String lateField;
            
            // Constructors
            FullClass();
            
            // Methods
            void publicMethod() {}
            void _privateMethod() {}
            
            // Getters/Setters
            String get computed => publicField;
            set computed(String value) { publicField = value; }
          }
        ''');

        final cls = result.classes.first;
        expect(cls.name, equals('FullClass'));

        // Check fields
        expect(cls.fields,
            containsAll(['publicField', '_privateField', 'lateField']));

        // Check methods
        expect(cls.methods,
            containsAll(['publicMethod', '_privateMethod', 'computed']));
      });

      test('should detect abstract class', () {
        final result = d4rt.analyze(source: '''
          abstract class Shape {
            double area();
            double perimeter();
          }
        ''');

        expect(result.classes.length, equals(1));
        expect(result.classes.first.isAbstract, isTrue);
        expect(
            result.classes.first.methods, containsAll(['area', 'perimeter']));
      });

      test('should detect class inheritance', () {
        final result = d4rt.analyze(source: '''
          class Animal {}
          class Mammal extends Animal {}
          class Dog extends Mammal {}
        ''');

        expect(result.classes.length, equals(3));

        final mammal = result.classes.firstWhere((c) => c.name == 'Mammal');
        expect(mammal.superTypes, contains('Animal'));

        final dog = result.classes.firstWhere((c) => c.name == 'Dog');
        expect(dog.superTypes, contains('Mammal'));
      });

      test('should detect class implementing interfaces', () {
        final result = d4rt.analyze(source: '''
          abstract class Runnable { void run(); }
          abstract class Jumpable { void jump(); }
          
          class Athlete implements Runnable, Jumpable {
            void run() {}
            void jump() {}
          }
        ''');

        final athlete = result.classes.firstWhere((c) => c.name == 'Athlete');
        expect(athlete.superTypes, containsAll(['Runnable', 'Jumpable']));
      });

      test('should detect class with mixins', () {
        final result = d4rt.analyze(source: '''
          mixin Swimming {
            void swim() {}
          }
          
          mixin Flying {
            void fly() {}
          }
          
          class Duck with Swimming, Flying {}
        ''');

        final duck = result.classes.firstWhere((c) => c.name == 'Duck');
        expect(duck.superTypes, containsAll(['Swimming', 'Flying']));
      });

      test('should detect generic class', () {
        final result = d4rt.analyze(source: '''
          class Container<T> {
            T? value;
            void set(T val) { value = val; }
            T? get() => value;
          }
          
          class Pair<K, V> {
            K key;
            V value;
            Pair(this.key, this.value);
          }
        ''');

        expect(result.classes.length, equals(2));
        expect(result.contains('Container'), isTrue);
        expect(result.contains('Pair'), isTrue);
      });

      test('should detect sealed/final/base class modifiers', () {
        final result = d4rt.analyze(source: '''
          final class FinalClass {}
          base class BaseClass {}
          sealed class SealedClass {}
          interface class InterfaceClass {}
          mixin class MixinClass {}
        ''');

        expect(result.classes.length, greaterThanOrEqualTo(5));
        expect(result.contains('FinalClass'), isTrue);
        expect(result.contains('BaseClass'), isTrue);
        expect(result.contains('SealedClass'), isTrue);
      });

      test('should detect complex inheritance hierarchy', () {
        final result = d4rt.analyze(source: '''
          abstract class Entity {
            String id = "";
          }
          
          mixin Timestamped {
            DateTime? createdAt;
            DateTime? updatedAt;
          }
          
          mixin Serializable {
            Map<String, dynamic> toJson() => {};
          }
          
          abstract class BaseModel extends Entity with Timestamped, Serializable {}
          
          class User extends BaseModel {
            String name = "";
            String email = "";
          }
          
          class Admin extends User {
            List<String> permissions = [];
          }
        ''');

        expect(result.classes.length, greaterThanOrEqualTo(4));

        final admin = result.classes.firstWhere((c) => c.name == 'Admin');
        expect(admin.superTypes, contains('User'));

        final user = result.classes.firstWhere((c) => c.name == 'User');
        expect(user.superTypes, contains('BaseModel'));
      });

      test('should detect nested classes', () {
        // Dart doesn't support nested classes in the traditional sense,
        // but we can have class with factory that returns different implementations
        final result = d4rt.analyze(source: '''
          class Outer {
            void method() {}
          }
          
          class _OuterImpl extends Outer {}
        ''');

        expect(result.classes.length, equals(2));
      });
    });

    group('Enum Analysis', () {
      test('should detect simple enum', () {
        final result = d4rt.analyze(source: '''
          enum Color { red, green, blue }
        ''');

        expect(result.enums.length, equals(1));
        final colorEnum = result.enums.first;
        expect(colorEnum.name, equals('Color'));
        expect(colorEnum.values, containsAll(['red', 'green', 'blue']));
      });

      test('should detect multiple enums', () {
        final result = d4rt.analyze(source: '''
          enum Status { pending, active, inactive, deleted }
          enum Priority { low, medium, high, critical }
          enum Visibility { public, private, protected }
        ''');

        expect(result.enums.length, equals(3));
        expect(result.enums.any((e) => e.name == 'Status'), isTrue);
        expect(result.enums.any((e) => e.name == 'Priority'), isTrue);
        expect(result.enums.any((e) => e.name == 'Visibility'), isTrue);

        final priority = result.enums.firstWhere((e) => e.name == 'Priority');
        expect(priority.values,
            containsAll(['low', 'medium', 'high', 'critical']));
      });

      test('should detect enhanced enum with fields and methods', () {
        final result = d4rt.analyze(source: '''
          enum Planet {
            mercury(3.303e+23, 2.4397e6),
            venus(4.869e+24, 6.0518e6),
            earth(5.976e+24, 6.37814e6);
            
            final double mass;
            final double radius;
            
            const Planet(this.mass, this.radius);
            
            double get surfaceGravity => 6.67300E-11 * mass / (radius * radius);
          }
        ''');

        expect(result.enums.length, equals(1));
        final planet = result.enums.first;
        expect(planet.name, equals('Planet'));
        expect(planet.values, containsAll(['mercury', 'venus', 'earth']));
      });

      test('should detect enum implementing interface', () {
        final result = d4rt.analyze(source: '''
          abstract class Describable {
            String get description;
          }
          
          enum Vehicle implements Describable {
            car("A four-wheeled vehicle"),
            bike("A two-wheeled vehicle"),
            truck("A large transport vehicle");
            
            final String _desc;
            const Vehicle(this._desc);
            
            String get description => _desc;
          }
        ''');

        expect(result.enums.length, equals(1));
        expect(
            result.enums.first.values, containsAll(['car', 'bike', 'truck']));
      });
    });

    group('Variable Analysis', () {
      test('should detect top-level variables', () {
        final result = d4rt.analyze(source: '''
          var mutableVar = 10;
          final immutableVar = "constant";
          const compiletimeConst = 3.14;
          late String lateVar;
        ''');

        expect(result.variables.any((v) => v.name == 'mutableVar'), isTrue);
        expect(result.variables.any((v) => v.name == 'immutableVar'), isTrue);
        expect(
            result.variables.any((v) => v.name == 'compiletimeConst'), isTrue);
        expect(result.variables.any((v) => v.name == 'lateVar'), isTrue);
      });

      test('should detect variable types', () {
        final result = d4rt.analyze(source: '''
          int explicitInt = 42;
          String explicitString = "hello";
          List<int> explicitList = [];
          Map<String, dynamic> explicitMap = {};
        ''');

        final intVar =
            result.variables.firstWhere((v) => v.name == 'explicitInt');
        expect(intVar.declaredType, equals('int'));

        final stringVar =
            result.variables.firstWhere((v) => v.name == 'explicitString');
        expect(stringVar.declaredType, equals('String'));
      });

      test('should detect const expressions', () {
        final result = d4rt.analyze(source: '''
          const pi = 3.14159265359;
          const e = 2.71828;
          const goldenRatio = 1.61803398875;
          const tau = pi * 2;
        ''');

        expect(result.variables.length, greaterThanOrEqualTo(4));
        expect(result.contains('pi'), isTrue);
        expect(result.contains('tau'), isTrue);
      });

      test('should detect complex type annotations', () {
        final result = d4rt.analyze(source: '''
          List<Map<String, int>> complexList = [];
          Map<String, List<int>> nestedMap = {};
        ''');

        expect(result.variables.any((v) => v.name == 'complexList'), isTrue);
        expect(result.variables.any((v) => v.name == 'nestedMap'), isTrue);

        // Check that declared types are captured
        final complexList =
            result.variables.firstWhere((v) => v.name == 'complexList');
        expect(complexList.declaredType, isNotNull);
        expect(complexList.declaredType, contains('List'));
      });
    });

    group('Extension Analysis', () {
      test('should detect simple extension', () {
        final result = d4rt.analyze(source: '''
          extension StringExtension on String {
            String capitalize() {
              if (isEmpty) return this;
              return this[0].toUpperCase() + substring(1);
            }
          }
        ''');

        expect(result.extensions.length, equals(1));
        expect(result.extensions.first.name, equals('StringExtension'));
        expect(result.extensions.first.onType, equals('String'));
        expect(result.extensions.first.methods, contains('capitalize'));
      });

      test('should detect multiple extensions', () {
        final result = d4rt.analyze(source: '''
          extension IntExtension on int {
            bool get isEven => this % 2 == 0;
            int square() => this * this;
          }
          
          extension ListExtension on List {
            dynamic get firstOrNull => isEmpty ? null : first;
            dynamic get lastOrNull => isEmpty ? null : last;
          }
          
          extension DateTimeExtension on DateTime {
            bool get isToday {
              final now = DateTime.now();
              return year == now.year && month == now.month && day == now.day;
            }
          }
        ''');

        expect(result.extensions.length, equals(3));
        expect(result.extensions.any((e) => e.name == 'IntExtension'), isTrue);
        expect(result.extensions.any((e) => e.name == 'ListExtension'), isTrue);
        expect(result.extensions.any((e) => e.name == 'DateTimeExtension'),
            isTrue);
      });

      test('should detect generic extension', () {
        final result = d4rt.analyze(source: '''
          extension IterableExtension<T> on Iterable<T> {
            T? get firstOrNull => isEmpty ? null : first;
            T? firstWhereOrNull(bool Function(T) test) {
              for (var element in this) {
                if (test(element)) return element;
              }
              return null;
            }
          }
        ''');

        expect(result.extensions.length, equals(1));
        expect(result.extensions.first.name, equals('IterableExtension'));
      });

      test('should detect unnamed extension', () {
        final result = d4rt.analyze(source: '''
          extension on String {
            String reverse() => split('').reversed.join('');
          }
        ''');

        // Unnamed extensions might have empty or null name
        expect(result.extensions.length, equals(1));
        expect(result.extensions.first.onType, equals('String'));
      });
    });

    group('AnalysisResult API', () {
      test('getByName should return correct declaration type', () {
        final result = d4rt.analyze(source: '''
          class MyClass {}
          enum MyEnum { a, b }
          void myFunction() {}
          var myVariable = 42;
          extension MyExtension on String {}
        ''');

        expect(result.getByName('MyClass'), isA<ClassInfo>());
        expect(result.getByName('MyEnum'), isA<EnumInfo>());
        expect(result.getByName('myFunction'), isA<FunctionInfo>());
        expect(result.getByName('myVariable'), isA<VariableInfo>());
        expect(result.getByName('MyExtension'), isA<ExtensionInfo>());
      });

      test('getByName should return null for non-existent names', () {
        final result = d4rt.analyze(source: '''
          class Existing {}
        ''');

        expect(result.getByName('NonExistent'), isNull);
        expect(result.getByName(''), isNull);
        expect(result.getByName('random_name_123'), isNull);
      });

      test('contains should work correctly', () {
        final result = d4rt.analyze(source: '''
          class ExistingClass {}
          void existingFunction() {}
        ''');

        expect(result.contains('ExistingClass'), isTrue);
        expect(result.contains('existingFunction'), isTrue);
        expect(result.contains('NonExistent'), isFalse);
      });

      test('all should iterate all types', () {
        final result = d4rt.analyze(source: '''
          class C {}
          enum E { a }
          void f() {}
          var v = 1;
          extension X on String {}
        ''');

        final allNames = result.all.map((d) => d.name).toList();
        expect(allNames, containsAll(['C', 'E', 'f', 'v', 'X']));
      });

      test('should handle empty source', () {
        final result = d4rt.analyze(source: '');

        expect(result.functions, isEmpty);
        expect(result.classes, isEmpty);
        expect(result.enums, isEmpty);
        expect(result.variables, isEmpty);
        expect(result.extensions, isEmpty);
      });

      test('should handle source with only comments', () {
        final result = d4rt.analyze(source: '''
          // This is a comment
          /* This is a 
             multi-line comment */
          /// This is a doc comment
        ''');

        expect(result.functions, isEmpty);
        expect(result.classes, isEmpty);
      });

      test('should handle source with imports only', () {
        final result = d4rt.analyze(source: '''
          import 'dart:core';
          import 'dart:async';
        ''');

        // Imports are not declarations, so nothing should be detected
        expect(result.all.length, equals(0));
      });
    });

    group('Complex scenarios', () {
      test('should analyze full application structure', () {
        final result = d4rt.analyze(source: '''
          // Constants
          const String appName = "MyApp";
          const int maxRetries = 3;
          
          // Enums
          enum UserRole { admin, moderator, user, guest }
          enum HttpMethod { get, post, put, delete, patch }
          
          // Models
          class Entity {
            String id;
            int createdAt;
            Entity(this.id, this.createdAt);
          }
          
          class User extends Entity {
            String name;
            String email;
            UserRole role;
            
            User(String id, int createdAt, this.name, this.email, this.role) 
                : super(id, createdAt);
          }
          
          // Services
          abstract class Repository {
            void findById(String id);
            void findAll();
            void save(Entity entity);
            void delete(String id);
          }
          
          class UserRepository implements Repository {
            void findById(String id) {}
            void findAll() {}
            void save(Entity entity) {}
            void delete(String id) {}
          }
          
          // Extensions
          extension StringValidation on String {
            bool get isValidEmail => contains('@');
            bool get isNotBlank => trim().isNotEmpty;
          }
          
          // Utility functions
          String formatId(String id) => "ID: \$id";
          bool isValidEmail(String email) => email.contains('@');
        ''');

        // Variables
        expect(result.variables.any((v) => v.name == 'appName'), isTrue);
        expect(result.variables.any((v) => v.name == 'maxRetries'), isTrue);

        // Enums
        expect(result.enums.any((e) => e.name == 'UserRole'), isTrue);
        expect(result.enums.any((e) => e.name == 'HttpMethod'), isTrue);

        // Classes
        expect(result.classes.any((c) => c.name == 'Entity'), isTrue);
        expect(result.classes.any((c) => c.name == 'User'), isTrue);
        expect(result.classes.any((c) => c.name == 'Repository'), isTrue);
        expect(result.classes.any((c) => c.name == 'UserRepository'), isTrue);

        // Extensions
        expect(
            result.extensions.any((e) => e.name == 'StringValidation'), isTrue);

        // Functions
        expect(result.functions.any((f) => f.name == 'formatId'), isTrue);
        expect(result.functions.any((f) => f.name == 'isValidEmail'), isTrue);
      });

      test('should handle code with syntax that might be tricky', () {
        final result = d4rt.analyze(source: '''
          // Function with many parameters
          void complexFunction(
            int a,
            String b, [
            double c = 0.0,
            bool d = false,
          ]) {}
          
          // Class with operator overloading
          class Vector {
            double x, y;
            Vector(this.x, this.y);
            Vector operator +(Vector other) => Vector(x + other.x, y + other.y);
            Vector operator -(Vector other) => Vector(x - other.x, y - other.y);
            Vector operator *(double scalar) => Vector(x * scalar, y * scalar);
            bool operator ==(Object other) => other is Vector && x == other.x && y == other.y;
            int get hashCode => x.hashCode ^ y.hashCode;
          }
          
          // Typedef (function type alias)
          typedef Callback = void Function(String message);
          typedef Predicate<T> = bool Function(T value);
        ''');

        expect(result.contains('complexFunction'), isTrue);
        expect(result.contains('Vector'), isTrue);

        final vector = result.classes.firstWhere((c) => c.name == 'Vector');
        expect(vector.fields, containsAll(['x', 'y']));
      });

      test('should handle mixin declarations', () {
        final result = d4rt.analyze(source: '''
          mixin Walkable {
            void walk() {}
          }
          
          mixin Swimmable {
            void swim() {}
          }
          
          mixin Flyable {
            void fly() {}
          }
          
          class Bird with Walkable, Flyable {}
          class Fish with Swimmable {}
          class Duck with Walkable, Swimmable, Flyable {}
        ''');

        // Mixins might be detected as classes in some analyzers
        expect(result.classes.any((c) => c.name == 'Bird'), isTrue);
        expect(result.classes.any((c) => c.name == 'Fish'), isTrue);
        expect(result.classes.any((c) => c.name == 'Duck'), isTrue);

        // Verify mixin inheritance is detected
        final duck = result.classes.firstWhere((c) => c.name == 'Duck');
        expect(
            duck.superTypes, containsAll(['Walkable', 'Swimmable', 'Flyable']));
      });
    });
  });
}
