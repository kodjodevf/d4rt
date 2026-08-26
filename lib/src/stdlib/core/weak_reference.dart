import 'package:d4rt/d4rt.dart';

class WeakReferenceCore {
  static BridgedClass get definition => BridgedClass(
        nativeType: WeakReference,
        name: 'WeakReference',
        typeParameterCount: 1,
        isSubtypeOfFunc: (value) => value is WeakReference,
        nativeNames: ['_WeakReference'],
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty || positionalArgs[0] == null) {
              throw RuntimeError(
                  "WeakReference constructor expects a non-null target Object.");
            }
            return WeakReference<Object>(positionalArgs[0] as Object);
          },
        },
        getters: {
          'target': (visitor, target) => (target as WeakReference).target,
          'hashCode': (visitor, target) => (target as WeakReference).hashCode,
          'runtimeType': (visitor, target) =>
              (target as WeakReference).runtimeType,
        },
      );
}
