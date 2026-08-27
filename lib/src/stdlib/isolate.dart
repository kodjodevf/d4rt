import 'package:d4rt/src/environment.dart';
import 'isolate/capability.dart';
import 'isolate/isolate.dart';

export 'package:d4rt/src/environment.dart';

class IsolateStdlib {
  static void register(Environment environment) {
    // Register all Isolate-related bridges (concrete first, base last)
    environment.defineBridge(SendPortIsolate.definition);
    environment.defineBridge(ReceivePortIsolate.definition);
    environment.defineBridge(RawReceivePortIsolate.definition);
    environment.defineBridge(IsolateIsolate.definition);
    environment.defineBridge(IsolateSpawnExceptionIsolate.definition);
    environment.defineBridge(RemoteErrorIsolate.definition);
    environment.defineBridge(TransferableTypedDataIsolate.definition);
    environment.defineBridge(CapabilityIsolate.definition);
  }
}
