import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

void main() {
  group('invokeInterpretedFunction tests', () {
    late D4rt d4rt;

    setUp(() {
      d4rt = D4rt();
    });

    test('Constant function', () {
      final source = """
        main() => () => 5;
        """;
      final InterpretedFunction fn = d4rt.execute(source: source);
      final result = d4rt.invokeInterpretedFunction(fn, []);

      expect(result, equals(5));
    });

    test('One argument function', () {
      final source = """
        main() => (int p) => p+5;
        """;
      final InterpretedFunction fn = d4rt.execute(source: source);
      final result = d4rt.invokeInterpretedFunction(fn, [3]);

      expect(result, equals(8));
    });

    test('Constant closure', () {
      final source = """
        final a = 3;
        main() => (int p) => a+p;
        """;
      final InterpretedFunction fn = d4rt.execute(source: source);
      final result = d4rt.invokeInterpretedFunction(fn, [3]);

      expect(result, equals(6));
    });

    test('Side effect', () {
      final source = """
        int a = 3;
        main() => (int p){
          int ret = a;
          a = p;
          return ret;
        };
        """;
      final InterpretedFunction fn = d4rt.execute(source: source);
      d4rt.invokeInterpretedFunction(fn, [2]);
      final result = d4rt.invokeInterpretedFunction(fn, [3]);

      expect(result, equals(2));
    });

    test('Function that returns a function', () {
      final source = """
        int a = 3;
        main() => () => (int p){
          int ret = a;
          a = p;
          return ret;
        };
        """;
      final InterpretedFunction fn1 = d4rt.execute(source: source);
      final InterpretedFunction fn2 = d4rt.invokeInterpretedFunction(fn1, []);
      final result1 = d4rt.invokeInterpretedFunction(fn2, [4]);
      expect(result1, equals(3));
      final result2 = d4rt.invokeInterpretedFunction(fn2, [5]);
      expect(result2, equals(4));
    });

    test('Function generator', () {
      final source = """
        Iterable<int> range(int start, int end) sync* {
          for (var i = start; i < end; i++) {
            yield i;
          }
        }
          
        main() => range;
        """;
      final InterpretedFunction gen = d4rt.execute(source: source);
      final iterable = d4rt.invokeInterpretedFunction(gen, [0, 3]);
      final list = iterable.toList();
      expect(list, equals([0, 1, 2]));
    });

    test('Function that receives a function', () {
      final source = """
      double squared(double x) => x * x;

      T applyTwice<T>(T arg, T Function(T) fn) => fn(fn(arg));

      main() => (squared,applyTwice);
      """;
      final InterpretedRecord tuple = d4rt.execute(source: source);
      final InterpretedFunction squared =
          tuple.positionalFields[0] as InterpretedFunction;
      final InterpretedFunction applyTwice =
          tuple.positionalFields[1] as InterpretedFunction;

      final result = d4rt.invokeInterpretedFunction(applyTwice, [2, squared]);

      expect(result, equals(16));
    });

    test('Function that receives a host function', () {
      double squared(double x) => x * x;

      final source = """
      T applyTwice<T>(T arg, T Function(T) fn) => fn(fn(arg));

      main() => applyTwice;
      """;
      final InterpretedFunction applyTwice = d4rt.execute(source: source);

      final result = d4rt.invokeInterpretedFunction(applyTwice, [2, squared]); // result is squared function, not expected

      expect(result, equals(16));
    }, skip: true);
  });
}
