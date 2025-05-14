import '../../interpreter_test.dart';
import 'package:test/test.dart';
import 'dart:io';

void main() {
  group('File methods - comprehensive', () {
    test('existsSync', () {
      const source = '''
     import 'dart:io';
     main() {
        File file = File(Directory.systemTemp.path + "/test.txt");
        file.writeAsStringSync("Hello, world!");
        var exists1 = file.existsSync();
        file.deleteSync();
        var exists2 = file.existsSync();
        return [exists1, exists2];
      }
      ''';
      expect(execute(source), equals([true, false]));
    });

    test('writeAsStringSync and readAsStringSync', () {
      const source = '''
     import 'dart:io';
     main() {
        File file = File(Directory.systemTemp.path + "/test.txt");
        file.writeAsStringSync("Hello, world!");
        var content = file.readAsStringSync();
        file.deleteSync();
        return content;
      }
      ''';
      expect(execute(source), equals('Hello, world!'));
    });

    test('deleteSync', () {
      const source = '''
     import 'dart:io';
     main() {
        File file = File(Directory.systemTemp.path + "/test.txt");
        file.writeAsStringSync("Hello, world!");
        file.deleteSync();
        return file.existsSync();
      }
      ''';
      expect(execute(source), isFalse);
    });

    test('renameSync', () {
      const source = '''
     import 'dart:io';
     main() {
        File file = File(Directory.systemTemp.path + "/test.txt");
        file.writeAsStringSync("Hello, world!");
        File renamedFile = file.renameSync(file.path + "_renamed");
        var exists = renamedFile.existsSync();
        renamedFile.deleteSync();
        return exists;
      }
      ''';
      expect(execute(source), isTrue);
    });

    test('copySync', () {
      const source = '''
     import 'dart:io';
     main() {
        File file = File(Directory.systemTemp.path + "/test.txt");
        file.writeAsStringSync("Hello, world!");
        File copiedFile = file.copySync(file.path + "_copy");
        var exists = copiedFile.existsSync();
        file.deleteSync();
        copiedFile.deleteSync();
        return exists;
      }
      ''';
      expect(execute(source), isTrue);
    });

    test('lengthSync', () {
      const source = '''
     import 'dart:io';
     main() {
        File file = File(Directory.systemTemp.path + "/test.txt");
        file.writeAsStringSync("Hello, world!");
        var length = file.lengthSync();
        file.deleteSync();
        return length;
      }
      ''';
      expect(execute(source), equals(13));
    });

    test('lastModifiedSync', () {
      const source = '''
     import 'dart:io';
     main() {
        File file = File(Directory.systemTemp.path + "/test.txt");
        file.writeAsStringSync("Hello, world!");
        var lastModified = file.lastModifiedSync();
        file.deleteSync();
        return lastModified;
      }
      ''';
      expect(execute(source), isA<DateTime>());
    });

    test('resolveSymbolicLinksSync', () {
      const source = '''
     import 'dart:io';
     main() {
        File file = File(Directory.systemTemp.path + "/test.txt");
        file.writeAsStringSync("Hello, world!");
        var path = file.resolveSymbolicLinksSync();
        file.deleteSync();
        return path;
      }
      ''';
      expect(execute(source), isA<String>());
    });

    test('absolute', () {
      const source = '''
     import 'dart:io';
     main() {
        File file = File(Directory.systemTemp.path + "/test.txt");
        file.writeAsStringSync("Hello, world!");
        var path = file.absolute.path;
        file.deleteSync();
        return path;
      }
      ''';
      expect(execute(source), isA<String>());
      expect((execute(source) as String).contains('/test.txt'), isTrue);
    });

    test('parent', () {
      const source = '''
     import 'dart:io';
     main() {
        File file = File(Directory.systemTemp.path + "/test.txt");
        file.writeAsStringSync("Hello, world!");
        var path = file.parent.path;
        file.deleteSync();
        return path;
      }
      ''';
      expect(execute(source), isA<String>());
      expect(execute(source), equals(Directory.systemTemp.path));
    });
  });
}
