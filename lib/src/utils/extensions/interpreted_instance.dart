import 'package:d4rt/d4rt.dart';

extension InterpretedInstanceExtension on InterpretedInstance {
  T? getNativeObject<T>() {
    return bridgedSuperObject as T?;
  }
}
