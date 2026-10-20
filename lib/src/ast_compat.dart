import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';

/// Compatibility helpers for AST APIs that became compositional in recent
/// versions of `package:analyzer`.
///
/// Analyzer 11 removed the deprecated `name`, `typeParameters`, `members` and
/// `constants` getters from declarations. The information is still available
/// through `namePart` and the sealed `body` nodes, but with a different shape.
/// These extensions keep the rest of the interpreter readable while exposing
/// the modern AST representation.
extension ClassDeclarationCompat on ClassDeclaration {
  /// The declared class name.
  Token get name => namePart.typeName;

  /// The declared type parameters, if any.
  TypeParameterList? get typeParameters => namePart.typeParameters;

  /// The class members. Empty classes have no members.
  List<ClassMember> get members => switch (body) {
    BlockClassBody(:final members) => members,
    EmptyClassBody() => const <ClassMember>[],
  };
}

extension EnumDeclarationCompat on EnumDeclaration {
  /// The declared enum name.
  Token get name => namePart.typeName;

  /// The declared type parameters, if any.
  TypeParameterList? get typeParameters => namePart.typeParameters;

  /// The enum constants. Empty enums have no constants.
  List<EnumConstantDeclaration> get constants => switch (body) {
    BlockEnumBody(:final constants) => constants,
    EmptyEnumBody() => const <EnumConstantDeclaration>[],
  };

  /// The enum members. Empty enums have no members.
  List<ClassMember> get members => switch (body) {
    BlockEnumBody(:final members) => members,
    EmptyEnumBody() => const <ClassMember>[],
  };
}

extension ExtensionDeclarationCompat on ExtensionDeclaration {
  /// The extension members. Empty extensions have no members.
  List<ClassMember> get members => switch (body) {
    BlockClassBody(:final members) => members,
    EmptyClassBody() => const <ClassMember>[],
  };
}

extension MixinDeclarationCompat on MixinDeclaration {
  /// The mixin members. Empty mixins have no members.
  List<ClassMember> get members => switch (body) {
    BlockClassBody(:final members) => members,
    EmptyClassBody() => const <ClassMember>[],
  };
}

extension FormalParameterCompat on FormalParameter {
  /// The default value expression attached to this parameter, if any.
  Expression? get defaultValue {
    // The V2 AST is not compatible with the interpreter's V1 visitor.
    // ignore: deprecated_member_use
    return defaultClause?.value;
  }
}

extension NamedArgumentCompat on NamedArgument {
  /// The value expression passed for this named argument.
  Expression get expression {
    // The V2 AST is not compatible with the interpreter's V1 visitor.
    // ignore: deprecated_member_use
    return argumentExpression;
  }
}

extension RecordLiteralNamedFieldCompat on RecordLiteralNamedField {
  /// The value expression of this named record field.
  Expression get expression {
    // The V2 AST is not compatible with the interpreter's V1 visitor.
    // ignore: deprecated_member_use
    return fieldExpression;
  }
}

extension ExtensionTypeDeclarationCompat on ExtensionTypeDeclaration {
  /// The declared extension type name.
  Token get name => namePart.typeName;

  /// The extension type members. Empty extension types have no members.
  List<ClassMember> get members => switch (body) {
    BlockClassBody(:final members) => members,
    EmptyClassBody() => const <ClassMember>[],
  };

  /// The representation field of the extension type, in the same shape as the
  /// removed `RepresentationDeclaration`.
  ({Token fieldName, TypeAnnotation? fieldType}) get representation {
    final part = namePart;
    if (part is! PrimaryConstructorDeclaration ||
        part.formalParameters.parameters.isEmpty) {
      throw StateError('Extension type has no representation field.');
    }
    final parameter = part.formalParameters.parameters.first;
    final name = parameter.name;
    if (name == null) {
      throw StateError('Extension type representation field has no name.');
    }
    return (fieldName: name, fieldType: parameter.type);
  }
}
