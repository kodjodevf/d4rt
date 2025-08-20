import 'package:d4rt/src/environment.dart';
import 'isolate/capability.dart';
import 'isolate/isolate.dart';

export 'package:d4rt/src/environment.dart';

class IsolateStdlib {
  static void register(Environment environment) {
    // Register Capability bridge
    environment.defineBridge(CapabilityIsolate.definition);

    // Register all Isolate-related bridges
    environment.defineBridge(IsolateSpawnExceptionIsolate.definition);
    environment.defineBridge(IsolateIsolate.definition);
    environment.defineBridge(SendPortIsolate.definition);
    environment.defineBridge(ReceivePortIsolate.definition);
    environment.defineBridge(RawReceivePortIsolate.definition);
    environment.defineBridge(RemoteErrorIsolate.definition);
    environment.defineBridge(TransferableTypedDataIsolate.definition);
  }
}
