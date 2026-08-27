import 'dart:io';
import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('IO Features & Bridges Stdlib Tests', () {
    late D4rt d4rt;
    late Directory tempDir;

    setUp(() {
      d4rt = D4rt()..grant(FilesystemPermission.any);
      tempDir = Directory.systemTemp.createTempSync('d4rt_link_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('HttpStatus constants are accessible', () {
      final result = d4rt.execute(source: '''
        import 'dart:io';

        main() {
          return [
            HttpStatus.ok,
            HttpStatus.created,
            HttpStatus.badRequest,
            HttpStatus.unauthorized,
            HttpStatus.forbidden,
            HttpStatus.notFound,
            HttpStatus.internalServerError,
          ];
        }
      ''') as List;

      expect(result[0], equals(200));
      expect(result[1], equals(201));
      expect(result[2], equals(400));
      expect(result[3], equals(401));
      expect(result[4], equals(403));
      expect(result[5], equals(404));
      expect(result[6], equals(500));
    });

    test('Link creation, existence, target, and subtyping', () {
      final targetFile = File('${tempDir.path}/target.txt');
      targetFile.writeAsStringSync('Hello Link');
      final linkPath = '${tempDir.path}/test_link.lnk';

      final result = d4rt.execute(source: '''
        import 'dart:io';

        main() {
          final link = Link('$linkPath');
          final existsBefore = link.existsSync();
          link.createSync('${targetFile.path}');
          final existsAfter = link.existsSync();
          final target = link.targetSync();
          final isLink = link is Link;
          final isEntity = link is FileSystemEntity;

          link.deleteSync();
          final existsDeleted = link.existsSync();

          return [
            existsBefore,
            existsAfter,
            target,
            isLink,
            isEntity,
            existsDeleted,
          ];
        }
      ''') as List;

      expect(result[0], isFalse);
      expect(result[1], isTrue);
      expect(result[2], equals(targetFile.path));
      expect(result[3], isTrue);
      expect(result[4], isTrue);
      expect(result[5], isFalse);
    });
  });
}
