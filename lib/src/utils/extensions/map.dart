extension MapExtension<K, V> on Map<K, V> {
  R? get<R>(K key) {
    return this[key] as R;
  }
}
