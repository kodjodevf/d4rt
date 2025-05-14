import '../../interpreter_test.dart';
import 'package:test/test.dart';
import 'dart:io'; // Need dart:io for File, Directory, etc.

void main() {
  group('FileSystemEntity methods - comprehensive', () {
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

    test('statSync', () {
      const source = '''
     import 'dart:io';
     main() {
        File file = File(Directory.systemTemp.path + "/test.txt");
        file.writeAsStringSync("Hello, world!");
        var type = file.statSync().type;
        file.deleteSync();
        return type.toString();
      }
      ''';
      expect(execute(source), equals('file'));
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
  });
}
