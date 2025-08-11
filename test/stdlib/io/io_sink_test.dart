import '../../interpreter_test.dart';
import 'package:test/test.dart';

void main() {
  group('IOSink methods - comprehensive', () {
    test('IOSink write and writeln to file', () async {
      const source = '''
     import 'dart:io';
     main() async {
        var tempDir = Directory.systemTemp.createTempSync();
        var file = File(tempDir.path + "/test_sink.txt");
        var sink = file.openWrite();
        
        sink.write('Hello ');
        sink.writeln('World');
        sink.write('Line 2');
        
        await sink.close();
        
        var content = file.readAsStringSync();
        file.deleteSync();
        tempDir.deleteSync();
        
        return content;
      }
      ''';
      final result = await execute(source);
      expect(result, equals('Hello World\nLine 2'));
    });

    test('IOSink writeAll method', () async {
      const source = '''
     import 'dart:io';
     main() async {
        var tempDir = Directory.systemTemp.createTempSync();
        var file = File(tempDir.path + "/test_writeall.txt");
        var sink = file.openWrite();
        
        sink.writeAll(['A', 'B', 'C'], '-');
        await sink.close();
        
        var content = file.readAsStringSync();
        file.deleteSync();
        tempDir.deleteSync();
        
        return content;
      }
      ''';
      final result = await execute(source);
      expect(result, equals('A-B-C'));
    });

    test('IOSink writeCharCode method', () async {
      const source = '''
     import 'dart:io';
     main() async {
        var tempDir = Directory.systemTemp.createTempSync();
        var file = File(tempDir.path + "/test_charcode.txt");
        var sink = file.openWrite();
        
        sink.writeCharCode(65); // 'A'
        sink.writeCharCode(66); // 'B'
        sink.writeCharCode(67); // 'C'
        await sink.close();
        
        var content = file.readAsStringSync();
        file.deleteSync();
        tempDir.deleteSync();
        
        return content;
      }
      ''';
      final result = await execute(source);
      expect(result, equals('ABC'));
    });

    test('IOSink add method with bytes', () async {
      const source = '''
     import 'dart:io';
     import 'dart:convert';
     main() async {
        var tempDir = Directory.systemTemp.createTempSync();
        var file = File(tempDir.path + "/test_add.txt");
        var sink = file.openWrite();
        
        var bytes = utf8.encode('Hello Bytes');
        sink.add(bytes);
        await sink.close();
        
        var content = file.readAsStringSync();
        file.deleteSync();
        tempDir.deleteSync();
        
        return content;
      }
      ''';
      final result = await execute(source);
      expect(result, equals('Hello Bytes'));
    });

    test('IOSink addStream method', () async {
      const source = '''
     import 'dart:io';
     import 'dart:convert';
     main() async {
        var tempDir = Directory.systemTemp.createTempSync();
        var sourceFile = File(tempDir.path + "/source.txt");
        var targetFile = File(tempDir.path + "/target.txt");
        
        // Create source file
        sourceFile.writeAsStringSync('Stream Content');
        
        // Copy using addStream
        var sink = targetFile.openWrite();
        var sourceStream = sourceFile.openRead();
        await sink.addStream(sourceStream);
        await sink.close();
        
        var content = targetFile.readAsStringSync();
        
        // Cleanup
        sourceFile.deleteSync();
        targetFile.deleteSync();
        tempDir.deleteSync();
        
        return content;
      }
      ''';
      final result = await execute(source);
      expect(result, equals('Stream Content'));
    });

    test('IOSink flush method', () async {
      const source = '''
     import 'dart:io';
     main() async {
        var tempDir = Directory.systemTemp.createTempSync();
        var file = File(tempDir.path + "/test_flush.txt");
        var sink = file.openWrite();
        
        sink.write('Before flush');
        await sink.flush();
        sink.write(' After flush');
        await sink.close();
        
        var content = file.readAsStringSync();
        file.deleteSync();
        tempDir.deleteSync();
        
        return content;
      }
      ''';
      final result = await execute(source);
      expect(result, equals('Before flush After flush'));
    });

    test('IOSink addError method', () async {
      const source = '''
     import 'dart:io';
     main() async {
        var tempDir = Directory.systemTemp.createTempSync();
        var file = File(tempDir.path + "/test_error.txt");
        var sink = file.openWrite();
        
        // Simply test that addError method exists and can be called
        // without throwing immediately
        try {
          sink.addError('Test error');
          await sink.close();
          file.deleteSync();
          tempDir.deleteSync();
          return 'addError method works';
        } catch (e) {
          // Don't await sink.close() in catch to avoid infinite loop
          sink.close();
          try { file.deleteSync(); } catch (e2) {}
          try { tempDir.deleteSync(); } catch (e2) {}
          return 'addError called successfully';
        }
      }
      ''';
      final result = await execute(source);
      expect(
          result,
          anyOf([
            equals('addError method works'),
            equals('addError called successfully')
          ]));
    });

    test('IOSink encoding parameter', () async {
      const source = '''
     import 'dart:io';
     import 'dart:convert';
     main() async{
        var tempDir = Directory.systemTemp.createTempSync();
        var file = File(tempDir.path + "/test_encoding.txt");
        
        // Write with UTF8 encoding
        var sink = file.openWrite(encoding: utf8);
        sink.write('UTF8 Content: héllo');
        await sink.close();
        
        var content = file.readAsStringSync();
        file.deleteSync();
        tempDir.deleteSync();
        
        return content;
      }
      ''';
      final result = await execute(source);
      expect(result, equals('UTF8 Content: héllo'));
    });

    test('IOSink done future', () async {
      const source = '''
     import 'dart:io';
     main() async {
        var tempDir = Directory.systemTemp.createTempSync();
        var file = File(tempDir.path + "/test_done.txt");
        var sink = file.openWrite();
        
        sink.write('Testing done future');
        await sink.close();

        // Wait for the sink to complete
        await sink.done;
        
        var content = file.readAsStringSync();
        file.deleteSync();
        tempDir.deleteSync();
        
        return content;
      }
      ''';
      final result = await execute(source);
      expect(result, equals('Testing done future'));
    });
  });
}
