import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('Isolate Features, Subtyping and Closures Tests', () {
    late D4rt d4rt;

    setUp(() {
      d4rt = D4rt()..grant(IsolatePermission.any);
    });

    test('Capability, SendPort, ReceivePort and RemoteError subtyping', () {
      final result = d4rt.execute(source: '''
        import 'dart:async';
        import 'dart:isolate';

        main() {
          final cap = Capability();
          final isCap = cap is Capability;

          final rp = ReceivePort();
          final sp = rp.sendPort;

          final isReceivePort = rp is ReceivePort;
          final isStream = rp is Stream;
          final isSendPort = sp is SendPort;
          final isSendPortCap = sp is Capability;

          final remoteErr = RemoteError('remote failure', 'stack');
          final isRemoteErr = remoteErr is RemoteError;
          final isError = remoteErr is Error;

          rp.close();

          return [
            isCap,
            isReceivePort,
            isStream,
            isSendPort,
            isSendPortCap,
            isRemoteErr,
            isError,
          ];
        }
      ''') as List;

      expect(result[0], isTrue);
      expect(result[1], isTrue);
      expect(result[2], isTrue);
      expect(result[3], isTrue);
      expect(result[4], isTrue);
      expect(result[5], isTrue);
      expect(result[6], isTrue);
    });

    test('ReceivePort communication and closure listeners', () async {
      final result = await d4rt.execute(source: '''
        import 'dart:async';
        import 'dart:isolate';

        Future<List> main() async {
          final rp = ReceivePort();
          final completer = Completer<int>();

          rp.listen((message) {
            completer.complete(message as int);
            rp.close();
          });

          rp.sendPort.send(12345);

          final received = await completer.future;
          return [received];
        }
      ''') as List;

      expect(result[0], equals(12345));
    });
  });
}
