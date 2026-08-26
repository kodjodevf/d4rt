import 'dart:developer';
import 'package:d4rt/d4rt.dart';

class UserTagDeveloper {
  static BridgedClass get definition => BridgedClass(
        nativeType: UserTag,
        name: 'UserTag',
        typeParameterCount: 0,
        isSubtypeOfFunc: (value) => value is UserTag,
        constructors: {
          '': (visitor, positionalArgs, namedArgs) {
            if (positionalArgs.isEmpty || positionalArgs[0] is! String) {
              throw RuntimeError("UserTag constructor expects a String label.");
            }
            return UserTag(positionalArgs[0] as String);
          },
        },
        staticGetters: {
          'defaultTag': (visitor) => UserTag.defaultTag,
        },
        staticMethods: {
          'defaultTag': (visitor, positionalArgs, namedArgs) =>
              UserTag.defaultTag,
        },
        methods: {
          'makeCurrent': (visitor, target, positionalArgs, namedArgs) {
            if (target is UserTag) {
              return target.makeCurrent();
            }
            throw RuntimeError("Target is not a UserTag for makeCurrent.");
          },
          'toString': (visitor, target, positionalArgs, namedArgs) {
            return (target as UserTag).toString();
          },
        },
        getters: {
          'label': (visitor, target) {
            if (target is UserTag) {
              return target.label;
            }
            throw RuntimeError("Target is not a UserTag for getter 'label'.");
          },
          'hashCode': (visitor, target) => (target as UserTag).hashCode,
          'runtimeType': (visitor, target) => (target as UserTag).runtimeType,
        },
      );
}
