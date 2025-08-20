import 'package:d4rt/d4rt.dart';

extension ListExtension<T> on List<T> {
  R? get<R>(int index) {
    try {
      return this[index] as R;
    } on RangeError {
      return null;
    }
  }

  List<dynamic> toNativeList() {
    return map((item) {
      if (item is BridgedInstance) {
        return item.nativeObject;
      }
      return item;
    }).toList();
  }
}
