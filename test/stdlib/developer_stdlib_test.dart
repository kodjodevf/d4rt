import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('dart:developer stdlib tests', () {
    test('log, inspect, and debugger functions', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:developer';

        main() {
          log('Test log message', name: 'd4rt.test');
          final obj = {'key': 'value'};
          final inspected = inspect(obj);
          final debugResult = debugger(when: false);
          return [inspected != null, debugResult];
        }
      ''');

      expect(result, equals([true, false]));
    });

    test('Timeline and TimelineTask', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:developer';

        main() {
          Timeline.startSync('mySyncTask');
          final now = Timeline.now;
          Timeline.finishSync();

          final syncVal = Timeline.timeSync('myTimeSync', () {
            return 42;
          });

          final task = TimelineTask();
          task.start('step1');
          task.instant('checkpoint');
          task.finish();

          return [now > 0, syncVal];
        }
      ''');

      expect(result, equals([true, 42]));
    });

    test('UserTag', () {
      final d4rt = D4rt();
      final result = d4rt.execute(source: '''
        import 'dart:developer';

        main() {
          final tag = UserTag('worker');
          final prevTag = tag.makeCurrent();
          final defaultTag = UserTag.defaultTag;
          return [tag.label, defaultTag.label];
        }
      ''');

      expect(result, equals(['worker', 'Default']));
    });

    test('ServiceExtensionResponse and Service.getInfo', () async {
      final d4rt = D4rt();
      final result = await d4rt.execute(source: '''
        import 'dart:developer';

        main() async {
          final successResp = ServiceExtensionResponse.result('{"ok": true}');
          final errorResp = ServiceExtensionResponse.error(-32000, 'Internal error');
          final serviceInfo = await Service.getInfo();
          return [successResp.result, errorResp.errorCode, errorResp.errorDetail, serviceInfo != null];
        }
      ''');

      expect(result, equals(['{"ok": true}', -32000, 'Internal error', true]));
    });
  });
}
