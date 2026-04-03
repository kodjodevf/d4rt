import 'package:analyzer/dart/ast/ast.dart';
import 'package:d4rt/d4rt.dart';

RuntimeType resolveRuntimeTypeAnnotation(
  TypeAnnotation? typeNode,
  Environment env, {
  bool isAsync = false,
}) {
  if (typeNode == null) {
    return const NamedRuntimeType('dynamic');
  }

  if (typeNode is NamedType) {
    if (isAsync && typeNode.name.lexeme == 'Future') {
      final futureTypeArguments = typeNode.typeArguments?.arguments;
      if (futureTypeArguments != null && futureTypeArguments.isNotEmpty) {
        return resolveRuntimeTypeAnnotation(futureTypeArguments.first, env);
      }
      return const NamedRuntimeType('dynamic');
    }

    final typeName = typeNode.name.lexeme;
    if (typeName == 'void') {
      return const NamedRuntimeType('void');
    }
    if (typeName == 'Never') {
      return const NamedRuntimeType('Never');
    }
    if (typeName == 'dynamic') {
      return const NamedRuntimeType('dynamic');
    }
    if (typeName == 'Function') {
      return FunctionRuntimeType.untyped();
    }
    if (typeName == 'Record') {
      return RecordRuntimeType(const [], const {});
    }

    final resolved = env.get(typeName);
    if (resolved is! RuntimeType) {
      throw RuntimeError(
          "Symbol '$typeName' resolved to non-type value: $resolved");
    }

    if (typeNode.typeArguments != null &&
        typeNode.typeArguments!.arguments.isNotEmpty) {
      final resolvedTypeArguments = typeNode.typeArguments!.arguments
          .map((argument) => resolveRuntimeTypeAnnotation(argument, env))
          .toList();
      return AppliedRuntimeType(resolved, resolvedTypeArguments);
    }

    return resolved;
  }

  if (typeNode is GenericFunctionType) {
    final positionalTypes = <RuntimeType>[];
    final namedTypes = <String, RuntimeType>{};
    final requiredNamedParameters = <String>{};
    int requiredPositionalCount = 0;

    for (final parameter in typeNode.parameters.parameters) {
      final parameterType = _resolveFormalParameterType(parameter, env);
      final parameterName = _resolveFormalParameterName(parameter);

      if (parameter.isNamed) {
        if (parameterName != null) {
          namedTypes[parameterName] = parameterType;
          if (parameter.isRequiredNamed) {
            requiredNamedParameters.add(parameterName);
          }
        }
      } else {
        positionalTypes.add(parameterType);
        if (parameter.isRequiredPositional) {
          requiredPositionalCount++;
        }
      }
    }

    return FunctionRuntimeType(
      returnType: resolveRuntimeTypeAnnotation(typeNode.returnType, env),
      positionalParameterTypes: positionalTypes,
      requiredPositionalParameterCount: requiredPositionalCount,
      namedParameterTypes: namedTypes,
      requiredNamedParameters: requiredNamedParameters,
      typeParameterCount: typeNode.typeParameters?.typeParameters.length ?? 0,
    );
  }

  if (typeNode is RecordTypeAnnotation) {
    final positionalTypes = typeNode.positionalFields
        .map((field) => resolveRuntimeTypeAnnotation(field.type, env))
        .toList();
    final namedTypes = <String, RuntimeType>{};
    final namedFields = typeNode.namedFields;

    if (namedFields != null) {
      for (final field in namedFields.fields) {
        namedTypes[field.name.lexeme] =
            resolveRuntimeTypeAnnotation(field.type, env);
      }
    }

    return RecordRuntimeType(positionalTypes, namedTypes);
  }

  throw RuntimeError(
      'Unsupported type annotation for constraint: ${typeNode.runtimeType}');
}

RuntimeType _resolveFormalParameterType(
    FormalParameter parameter, Environment env) {
  FormalParameter actualParameter = parameter;
  if (parameter is DefaultFormalParameter) {
    actualParameter = parameter.parameter;
  }

  if (actualParameter is SimpleFormalParameter) {
    return resolveRuntimeTypeAnnotation(actualParameter.type, env);
  }

  if (actualParameter is FieldFormalParameter) {
    return resolveRuntimeTypeAnnotation(actualParameter.type, env);
  }

  if (actualParameter is FunctionTypedFormalParameter) {
    return FunctionRuntimeType.untyped();
  }

  return const NamedRuntimeType('dynamic');
}

String? _resolveFormalParameterName(FormalParameter parameter) {
  FormalParameter actualParameter = parameter;
  if (parameter is DefaultFormalParameter) {
    actualParameter = parameter.parameter;
  }

  if (actualParameter is SimpleFormalParameter) {
    return actualParameter.name?.lexeme;
  }

  if (actualParameter is FieldFormalParameter) {
    return actualParameter.name.lexeme;
  }

  if (actualParameter is FunctionTypedFormalParameter) {
    return actualParameter.name.lexeme;
  }

  return null;
}
