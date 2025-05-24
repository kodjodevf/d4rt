import 'package:d4rt/d4rt.dart';

extension InterpreterVisitorExtension on InterpreterVisitor {
  (BridgedInstance?, bool) toBridgedInstance(Object? nativeObject,
      {String? methodName}) {
    //adjustment for the extension method
    if (methodName != null) {
      final extensionCallable =
          environment.findExtensionMember(nativeObject, methodName);
      if (extensionCallable is InterpretedExtensionMethod) {
        return (null, false);
      }
    }
    if (nativeObject == null) {
      return (null, false);
    }
    if (nativeObject is BridgedInstance) {
      return (nativeObject, true);
    }
    try {
      return (globalEnvironment.toBridgedInstance(nativeObject), true);
    } catch (e) {
      return (null, false);
    }
  }
}
