import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('BridgedClass subtype relationships', () {
    test('int and double are subtypes of num', () {
      final intType = BridgedClass(nativeType: int, name: 'int');
      final doubleType = BridgedClass(nativeType: double, name: 'double');
      final numType = BridgedClass(nativeType: num, name: 'num');

      expect(intType.isSubtypeOf(numType), isTrue);
      expect(doubleType.isSubtypeOf(numType), isTrue);
    });

    test('num is not a subtype of int or double', () {
      final intType = BridgedClass(nativeType: int, name: 'int');
      final doubleType = BridgedClass(nativeType: double, name: 'double');
      final numType = BridgedClass(nativeType: num, name: 'num');

      expect(numType.isSubtypeOf(intType), isFalse);
      expect(numType.isSubtypeOf(doubleType), isFalse);
    });

    test('bounded type parameters defer to their bound', () {
      final numType = BridgedClass(nativeType: num, name: 'num');
      final stringType = BridgedClass(nativeType: String, name: 'String');
      final typeParameter = TypeParameter('T', bound: numType);

      expect(typeParameter.isSubtypeOf(numType), isTrue);
      expect(typeParameter.isSubtypeOf(stringType), isFalse);
    });

    test('unbounded type parameters are only top-type compatible', () {
      final objectType = BridgedClass(nativeType: Object, name: 'Object');
      final dynamicType = BridgedClass(nativeType: Object, name: 'dynamic');
      final stringType = BridgedClass(nativeType: String, name: 'String');
      final typeParameter = TypeParameter('T');

      expect(typeParameter.isSubtypeOf(objectType), isTrue);
      expect(typeParameter.isSubtypeOf(dynamicType), isTrue);
      expect(typeParameter.isSubtypeOf(stringType), isFalse);
    });
  });
}
