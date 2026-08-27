import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('onPrint output interception tests', () {
    test('D4rt global onPrint constructor callback', () {
      final logs = <String>[];
      final d4rt = D4rt(onPrint: (msg) => logs.add(msg));

      d4rt.execute(source: '''
        main() {
          print('Hello World');
          print(12345);
          print([1, 2, 3]);
        }
      ''');

      expect(logs, equals(['Hello World', '12345', '[1, 2, 3]']));
    });

    test('d4rt.execute per-execution onPrint override', () {
      final defaultLogs = <String>[];
      final customLogs = <String>[];

      final d4rt = D4rt(onPrint: (msg) => defaultLogs.add(msg));

      d4rt.execute(
        source: '''
          main() {
            print('Custom log line');
          }
        ''',
        onPrint: (msg) => customLogs.add(msg),
      );

      expect(defaultLogs, isEmpty);
      expect(customLogs, equals(['Custom log line']));
    });

    test('d4rt.executeCompiled with onPrint', () {
      final compiledLogs = <String>[];
      final d4rt = D4rt();
      final script = d4rt.compile(source: '''
        main() {
          print('Compiled print: ok');
        }
      ''');

      d4rt.executeCompiled(script, onPrint: (msg) => compiledLogs.add(msg));
      expect(compiledLogs, equals(['Compiled print: ok']));
    });

    test('d4rt.eval with onPrint', () {
      final evalLogs = <String>[];
      final d4rt = D4rt();
      d4rt.execute(source: 'var count = 0; main() {}');
      d4rt.eval('print("Eval print: \${++count}");',
          onPrint: (msg) => evalLogs.add(msg));

      expect(evalLogs, equals(['Eval print: 1']));
    });
  });
}
