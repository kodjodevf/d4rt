import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('Developer Features, Flow, Service Constants and Subtyping Tests', () {
    late D4rt d4rt;

    setUp(() {
      d4rt = D4rt();
    });

    test('Flow bridge and operations', () {
      final result = d4rt.execute(source: '''
        import 'dart:developer';

        main() {
          final flow = Flow.begin();
          final id = flow.id;
          final stepFlow = Flow.step(id);
          final endFlow = Flow.end(id);

          final isFlow = flow is Flow;
          final isStepFlow = stepFlow is Flow;

          return [
            id,
            isFlow,
            isStepFlow,
            stepFlow.id,
            endFlow.id,
          ];
        }
      ''') as List;

      expect(result[0], isA<int>());
      expect(result[1], isTrue);
      expect(result[2], isTrue);
      expect(result[3], equals(result[0]));
      expect(result[4], equals(result[0]));
    });

    test('ServiceExtensionResponse constants and constructors', () {
      final result = d4rt.execute(source: '''
        import 'dart:developer';

        main() {
          final invParams = ServiceExtensionResponse.invalidParams;
          final extErr = ServiceExtensionResponse.extensionError;
          final extMin = ServiceExtensionResponse.extensionErrorMin;
          final extMax = ServiceExtensionResponse.extensionErrorMax;

          final resp = ServiceExtensionResponse.result('{"status":"ok"}');
          final isResp = resp is ServiceExtensionResponse;

          final errResp = ServiceExtensionResponse.error(
            ServiceExtensionResponse.invalidParams,
            'Missing parameter',
          );

          return [
            invParams,
            extErr,
            extMin,
            extMax,
            isResp,
            resp.result,
            errResp.errorCode,
            errResp.errorDetail,
          ];
        }
      ''') as List;

      expect(result[0], equals(-32602));
      expect(result[1], equals(-32000));
      expect(result[2], equals(-32016));
      expect(result[3], equals(-32000));
      expect(result[4], isTrue);
      expect(result[5], equals('{"status":"ok"}'));
      expect(result[6], equals(-32602));
      expect(result[7], equals('Missing parameter'));
    });

    test('Timeline.timeSync with closure callback', () {
      final result = d4rt.execute(source: '''
        import 'dart:developer';

        main() {
          int count = 0;
          final syncResult = Timeline.timeSync('my_sync_task', () {
            count += 42;
            return count * 2;
          });

          final tag = UserTag('custom_tag');
          final isTag = tag is UserTag;
          final tagLabel = tag.label;

          return [
            syncResult,
            count,
            isTag,
            tagLabel,
          ];
        }
      ''') as List;

      expect(result[0], equals(84));
      expect(result[1], equals(42));
      expect(result[2], isTrue);
      expect(result[3], equals('custom_tag'));
    });
  });
}
