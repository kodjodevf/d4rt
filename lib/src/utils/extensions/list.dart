extension ListExtension<T> on List<T> {
  R? get<R>(int index) {
    try {
      return this[index] as R;
    } on RangeError {
      return null;
    }
  }
}
