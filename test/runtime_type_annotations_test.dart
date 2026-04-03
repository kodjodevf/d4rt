import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

dynamic execute(String source, {List<Object?>? args}) {
  final d4rt = D4rt()..setDebug(false);
  return d4rt.execute(
      library: 'package:test/main.dart',
      positionalArgs: args,
      sources: {'package:test/main.dart': source});
}

void main() {
  group('Runtime Type Annotations', () {
    test('FunctionType supports tear-offs in return types and is checks', () {
      const source = '''
        int addOne(int value) {
          return value + 1;
        }

        int Function(int) pickTransformer() {
          return addOne;
        }

        main() {
          final transformer = pickTransformer();
          return [transformer is int Function(int), transformer(41)];
        }
      ''';

      expect(execute(source), equals([true, 42]));
    });

    test('FunctionType rejects incompatible return values', () {
      const source = '''
        String stringify(int value) {
          return '\$value';
        }

        int Function(int) pickTransformer() {
          return stringify;
        }

        main() {
          return pickTransformer();
        }
      ''';

      expect(
        () => execute(source),
        throwsA(isA<RuntimeError>().having(
          (e) => e.message,
          'message',
          contains("can't be returned"),
        )),
      );
    });

    test('RecordType supports return types and is checks', () {
      const source = '''
        (int, {String label}) buildRecord() {
          return (42, label: 'answer');
        }

        main() {
          final value = buildRecord();
          return [value is (int, {String label}), value.\$1, value.label];
        }
      ''';

      expect(execute(source), equals([true, 42, 'answer']));
    });

    test('RecordType rejects incompatible return shapes', () {
      const source = '''
        (int, String) buildRecord() {
          return ('wrong', 'shape');
        }

        main() {
          return buildRecord();
        }
      ''';

      expect(
        () => execute(source),
        throwsA(isA<RuntimeError>().having(
          (e) => e.message,
          'message',
          contains("can't be returned"),
        )),
      );
    });
  });
}
