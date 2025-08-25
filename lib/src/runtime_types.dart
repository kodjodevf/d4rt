import 'package:analyzer/dart/ast/ast.dart';
import 'package:d4rt/d4rt.dart';
import 'bridge/bridged_types.dart' as bridge;

/// Represents a class definition at runtime.
class InterpretedClass implements Callable, RuntimeType {
  @override
  final String name;
  InterpretedClass? superclass;
  final Environment classDefinitionEnvironment;
  final List<FieldDeclaration> fieldDeclarations;

  // Separate maps for different member types
  final Map<String, InterpretedFunction> methods;
  final Map<String, InterpretedFunction> getters;
  final Map<String, InterpretedFunction> setters;
  final Map<String, InterpretedFunction> staticMethods;
  final Map<String, InterpretedFunction> staticGetters;
  final Map<String, InterpretedFunction> staticSetters;
  final Map<String, Object?> staticFields;
  final Map<String, InterpretedFunction> constructors;
  // Map for operator methods (e.g., '+', '==', '[]', etc.)
  final Map<String, InterpretedFunction> operators;
  final bool isAbstract;
  List<InterpretedClass> interfaces;
  final bool isMixin;
  List<InterpretedClass> onClauseTypes;
  List<InterpretedClass> mixins;

  // Support for bridged mixins
  List<BridgedClass> bridgedMixins;

  // Add fields for type parameter information (like InterpretedFunction)
  final List<String> typeParameterNames; // e.g., ['T', 'U', 'V']
  final Map<String, RuntimeType?>
      typeParameterBounds; // e.g., {'T': num, 'U': Object}

  // Fields for class modifiers
  final bool isFinal;
  final bool isInterface;
  final bool isBase;
  final bool isSealed;

  // Add field for bridged superclass
  BridgedClass? bridgedSuperclass;

  // Helper methods to extract type parameter information from AST (similar to InterpretedFunction)
  static List<String> extractTypeParameterNames(
      TypeParameterList? typeParameters) {
    if (typeParameters == null) return [];
    return typeParameters.typeParameters
        .map((param) => param.name.lexeme)
        .toList();
  }

  static Map<String, RuntimeType?> extractTypeParameterBounds(
      TypeParameterList? typeParameters, Environment? resolveEnvironment) {
    final bounds = <String, RuntimeType?>{};
    if (typeParameters == null) return bounds;

    for (final typeParam in typeParameters.typeParameters) {
      final paramName = typeParam.name.lexeme;
      RuntimeType? bound;

      if (typeParam.bound != null && resolveEnvironment != null) {
        try {
          Logger.debug(
              "[InterpretedClass._extractTypeParameterBounds] Resolving bound for type parameter '$paramName'");

          bound = resolveTypeAnnotationDynamic(
              typeParam.bound!, resolveEnvironment);

          Logger.debug(
              "[InterpretedClass._extractTypeParameterBounds] Successfully resolved bound for '$paramName' to: ${bound.name}");
        } catch (e) {
          Logger.debug(
              "[InterpretedClass._extractTypeParameterBounds] Failed to resolve bound for '$paramName': $e");
          rethrow;
        }
      }

      bounds[paramName] = bound;
    }

    return bounds;
  }

  // Helper method for dynamic type resolution
  static RuntimeType resolveTypeAnnotationDynamic(
      TypeAnnotation typeNode, Environment env) {
    if (typeNode is NamedType) {
      final typeName = typeNode.name2.lexeme;

      Logger.debug(
          "[InterpretedClass._resolveTypeAnnotationDynamic] Resolving NamedType: $typeName");

      final resolved = env.get(typeName);
      if (resolved is RuntimeType) {
        Logger.debug(
            "[InterpretedClass._resolveTypeAnnotationDynamic] Resolved from environment to RuntimeType: ${resolved.name}");
        return resolved;
      } else {
        throw RuntimeError(
            "Symbol '$typeName' resolved to non-type value: $resolved");
      }
    } else {
      throw RuntimeError(
          "Unsupported type annotation for constraint: ${typeNode.runtimeType}");
    }
  }

  // Corrected constructor signature and initialization
  InterpretedClass(
    this.name,
    this.superclass,
    this.classDefinitionEnvironment,
    this.fieldDeclarations,
    // Ensure all maps are passed and assigned
    this.methods,
    this.getters,
    this.setters,
    this.staticMethods,
    this.staticGetters,
    this.staticSetters,
    this.staticFields,
    this.constructors,
    this.operators, {
    this.isAbstract = false,
    List<InterpretedClass>? interfaces,
    this.isMixin = false,
    List<InterpretedClass>? onClauseTypes,
    List<InterpretedClass>? mixins,
    List<BridgedClass>? bridgedMixins,
    // Initialize class modifiers (default to false)
    this.isFinal = false,
    this.isInterface = false,
    this.isBase = false,
    this.isSealed = false,
    // Initialize bridged superclass
    this.bridgedSuperclass, // Can be null
    // Add type parameter information
    this.typeParameterNames = const [],
    this.typeParameterBounds = const {},
  })  : interfaces = interfaces ?? [],
        onClauseTypes = onClauseTypes ?? [],
        mixins = mixins ?? [],
        bridgedMixins = bridgedMixins ?? [];

  @override
  String toString() {
    return '<class $name>';
  }

  // Finders for different member types
  InterpretedFunction? findInstanceMethod(String name) {
    if (methods.containsKey(name)) {
      return methods[name];
    }

    // Check applied mixins in reverse order
    for (int i = mixins.length - 1; i >= 0; i--) {
      final mixinMethod =
          mixins[i].findInstanceMethod(name); // Recursive call on mixin
      if (mixinMethod != null) {
        // We found the method in a mixin.
        // Note: Mixins don't change the 'this' binding context,
        // the method returned here will be bound later if needed.
        return mixinMethod;
      }
    }

    if (superclass != null) {
      return superclass!.findInstanceMethod(name);
    }

    // If not found in Dart hierarchy, check bridged superclass
    if (bridgedSuperclass != null) {
      final methodAdapter = bridgedSuperclass!.findInstanceMethodAdapter(name);
      if (methodAdapter != null) {
        // We need to return something callable. Create a synthetic InterpretedFunction
        // that wraps the call to the bridge adapter.
        // This is complex because the adapter expects the native target directly.
        // For now, return null, PropertyAccess visitor will handle it.
        return null; // Placeholder - Requires more complex handling
      }
    }

    return null;
  }

  InterpretedFunction? findInstanceGetter(String name) {
    if (getters.containsKey(name)) {
      return getters[name];
    }

    // Check applied mixins in reverse order
    for (int i = mixins.length - 1; i >= 0; i--) {
      final mixinGetter = mixins[i].findInstanceGetter(name);
      if (mixinGetter != null) {
        return mixinGetter;
      }
    }

    if (superclass != null) {
      return superclass!.findInstanceGetter(name);
    }

    // If not found in Dart hierarchy, check bridged superclass
    if (bridgedSuperclass != null) {
      final getterAdapter = bridgedSuperclass!.findInstanceGetterAdapter(name);
      if (getterAdapter != null) {
        return null;
      }
    }

    return null;
  }

  InterpretedFunction? findInstanceSetter(String name) {
    if (setters.containsKey(name)) {
      return setters[name];
    }

    // Check applied mixins in reverse order
    for (int i = mixins.length - 1; i >= 0; i--) {
      final mixinSetter = mixins[i].findInstanceSetter(name);
      if (mixinSetter != null) {
        return mixinSetter;
      }
    }

    if (superclass != null) {
      return superclass!.findInstanceSetter(name);
    }

    // If not found in Dart hierarchy, check bridged superclass
    if (bridgedSuperclass != null) {
      final setterAdapter = bridgedSuperclass!.findInstanceSetterAdapter(name);
      if (setterAdapter != null) {
        return null;
      }
    }

    return null;
  }

  InterpretedFunction? findStaticMethod(String name) => staticMethods[name];
  InterpretedFunction? findStaticGetter(String name) => staticGetters[name];
  InterpretedFunction? findStaticSetter(String name) => staticSetters[name];

  // Find operator methods (supports inheritance)
  InterpretedFunction? findOperator(String operatorSymbol) {
    if (operators.containsKey(operatorSymbol)) {
      return operators[operatorSymbol];
    }

    // Check applied mixins in reverse order
    for (int i = mixins.length - 1; i >= 0; i--) {
      final mixinOperator = mixins[i].findOperator(operatorSymbol);
      if (mixinOperator != null) {
        return mixinOperator;
      }
    }

    if (superclass != null) {
      return superclass!.findOperator(operatorSymbol);
    }

    return null;
  }

  InterpretedFunction? findConstructor(String name) {
    // Constructors are defined directly on the class, not inherited
    // from standard superclasses. Check bridged superclass ONLY if no constructor
    // is found locally.
    if (constructors.containsKey(name)) {
      return constructors[name];
    }

    return null;
  }

  // Get/Set static field values (no change needed here)
  Object? getStaticField(String name) {
    if (staticFields.containsKey(name)) {
      final fieldValue = staticFields[name];
      if (fieldValue is LateVariable) {
        // Return the value of the late variable (will initialize if needed)
        return fieldValue.value;
      }
      return fieldValue;
    }
    throw RuntimeError("Undefined static field '$name' on class '$this.name'.");
  }

  void setStaticField(String name, Object? value) {
    if (staticFields.containsKey(name)) {
      final fieldValue = staticFields[name];
      if (fieldValue is LateVariable) {
        // Assign to the late variable
        fieldValue.assign(value);
        return;
      }
    }
    // Check if field exists? Dart allows adding fields implicitly usually,
    // but for static maybe we should be stricter? For now, allow setting.
    staticFields[name] = value;
  }

  /// Check if a type argument satisfies a bound constraint
  bool _checkTypeSatisfiesBound(RuntimeType typeArg, RuntimeType bound) {
    // If the type argument is the same as the bound, it satisfies the constraint
    if (typeArg == bound || typeArg.name == bound.name) {
      return true;
    }

    // Special handling for common native types
    if (bound.name == 'num') {
      // Check if typeArg is a numeric type
      if (typeArg is BridgedClass) {
        return typeArg.nativeType == int ||
            typeArg.nativeType == double ||
            typeArg.nativeType == num;
      }
      // For other types, check the name
      return typeArg.name == 'int' ||
          typeArg.name == 'double' ||
          typeArg.name == 'num';
    }

    if (bound.name == 'Object') {
      // Everything extends Object (except possibly void/dynamic)
      return typeArg.name != 'void';
    }

    if (bound.name == 'String') {
      // Check if the type is String
      if (typeArg is BridgedClass) {
        return typeArg.nativeType == String;
      }
      return typeArg.name == 'String';
    }

    if (bound.name == 'Comparable') {
      // Check if the type implements Comparable
      if (typeArg is BridgedClass) {
        try {
          // Basic check for common comparable types
          return typeArg.nativeType == String ||
              typeArg.nativeType == int ||
              typeArg.nativeType == double ||
              typeArg.nativeType == DateTime;
        } catch (e) {
          return false;
        }
      }
      return typeArg.name == 'String' ||
          typeArg.name == 'int' ||
          typeArg.name == 'double';
    }

    // Check if the type argument is a subtype of the bound
    try {
      return typeArg.isSubtypeOf(bound);
    } catch (e) {
      Logger.debug(
          "[InterpretedClass._checkTypeSatisfiesBound] Error checking subtype relationship: $e");
      // If we can't determine the relationship, default to false for strict validation
      return false;
    }
  }

  List<RuntimeType> _getValidatedTypeArguments(
      List<RuntimeType>? providedTypeArguments) {
    List<RuntimeType> effective;
    if (providedTypeArguments == null || providedTypeArguments.isEmpty) {
      effective = List.generate(typeParameterNames.length,
          (_) => BridgedClass(nativeType: Object, name: 'dynamic'));
    } else if (providedTypeArguments.length != typeParameterNames.length) {
      throw RuntimeError(
          "Class '$name' requires ${typeParameterNames.length} type argument(s), but ${providedTypeArguments.length} were provided.");
    } else {
      effective = providedTypeArguments;
    }

    // Validate bounds
    for (int i = 0; i < effective.length; i++) {
      final typeArg = effective[i];
      final paramName = typeParameterNames[i];
      final bound = typeParameterBounds[paramName];
      if (bound != null) {
        bool satisfiesBound = _checkTypeSatisfiesBound(typeArg, bound);
        if (!satisfiesBound) {
          throw RuntimeError(
              "Type argument '${typeArg.name}' for type parameter '$paramName' does not satisfy bound '${bound.name}' in class '$name'");
        }
      }
    }
    return effective;
  }

  // Helper to create instance and run field initializers
  InterpretedInstance createAndInitializeInstance(
      InterpreterVisitor visitor, List<RuntimeType>? typeArguments) {
    // Prevent direct instantiation of abstract classes
    if (isAbstract) {
      throw RuntimeError("Cannot instantiate abstract class '$name'.");
    }

    // Get validated effective type arguments
    final effectiveTypeArgs = _getValidatedTypeArguments(typeArguments);

    // 1. Create the instance with a link to the class
    final instance = InterpretedInstance(this,
        typeArguments: effectiveTypeArgs); // Pass only the class

    // Use the environment where the class was defined as the outer scope
    // for evaluating initializers. We need to traverse the hierarchy.
    final originalVisitorEnv = visitor.environment;

    // Traverse the class hierarchy from top (Object/superclass) down to this class
    List<InterpretedClass> hierarchy = [];
    InterpretedClass? current = this;
    while (current != null) {
      hierarchy.insert(0, current); // Insert at beginning to get top-down order
      current = current.superclass;
    }

    // Initialize fields for each class in the hierarchy
    for (final klassInHierarchy in hierarchy) {
      // Create a temporary environment for this specific class's initializers,
      // enclosing the environment where *that* class was defined.
      final fieldInitEnv =
          Environment(enclosing: klassInHierarchy.classDefinitionEnvironment);
      fieldInitEnv.define('this', instance); // Define 'this' for initializers

      try {
        visitor.environment =
            fieldInitEnv; // Set visitor env for this class's initializers

        // Initialize fields declared IN THIS CLASS
        for (final fieldDecl in klassInHierarchy.fieldDeclarations) {
          if (!fieldDecl.isStatic) {
            for (final variable in fieldDecl.fields.variables) {
              final fieldName = variable.name.lexeme;
              final isLate = fieldDecl.fields.lateKeyword != null;
              final isFinal = fieldDecl.fields.keyword?.lexeme == 'final';

              if (isLate) {
                // Handle late instance field
                if (variable.initializer != null) {
                  // Late instance field with lazy initializer
                  final lateVar = LateVariable(fieldName, () {
                    // Create a closure that will evaluate the initializer when accessed
                    final savedEnv = visitor.environment;
                    try {
                      visitor.environment = fieldInitEnv;
                      return variable.initializer!.accept<Object?>(visitor);
                    } finally {
                      visitor.environment = savedEnv;
                    }
                  }, isFinal: isFinal);
                  instance._fields[fieldName] = lateVar;
                  Logger.debug(
                      "[Instance Init] Defined late instance field '$fieldName' with lazy initializer.");
                } else {
                  // Late instance field without initializer
                  final lateVar =
                      LateVariable(fieldName, null, isFinal: isFinal);
                  instance._fields[fieldName] = lateVar;
                  Logger.debug(
                      "[Instance Init] Defined late instance field '$fieldName' without initializer.");
                }
              } else {
                // Regular field handling
                if (variable.initializer != null) {
                  final value = variable.initializer!.accept<Object?>(visitor);
                  // Directly set the field on the instance map
                  instance._fields[fieldName] = value;
                } else {
                  // Ensure field exists even without initializer (Dart default is null)
                  instance._fields.putIfAbsent(fieldName, () => null);
                }
              }
            }
          }
        }

        // Initialize fields from MIXINS applied to this class
        // Iterate in application order (0 to n-1) so later mixins overwrite earlier ones
        for (final mixin in klassInHierarchy.mixins) {
          // Each mixin's field initializers run in the mixin's definition environment
          // with 'this' bound to the instance being created.
          final mixinFieldInitEnv =
              Environment(enclosing: mixin.classDefinitionEnvironment);
          mixinFieldInitEnv.define('this', instance);

          // Temporarily set visitor environment for this mixin's initializers
          final originalEnvBeforeMixin = visitor.environment;
          try {
            visitor.environment = mixinFieldInitEnv;
            for (final fieldDecl in mixin.fieldDeclarations) {
              if (!fieldDecl.isStatic) {
                for (final variable in fieldDecl.fields.variables) {
                  final fieldName = variable.name.lexeme;
                  if (variable.initializer != null) {
                    final value =
                        variable.initializer!.accept<Object?>(visitor);
                    // Set (or overwrite) the field on the instance
                    instance._fields[fieldName] = value;
                    Logger.debug(
                        "[Instance Init] Initialized mixin field '${klassInHierarchy.name}.$fieldName' from mixin '${mixin.name}' with value: $value");
                  } else {
                    // Ensure field exists even if not initialized (Dart default is null)
                    // Only set null if field wasn't already set by class or previous mixin
                    instance._fields.putIfAbsent(fieldName, () {
                      Logger.debug(
                          "[Instance Init] Initialized mixin field '${klassInHierarchy.name}.$fieldName' from mixin '${mixin.name}' to null (default)");
                      return null;
                    });
                  }
                }
              }
            }
          } finally {
            // Restore visitor environment after this mixin's initializers
            visitor.environment = originalEnvBeforeMixin;
          }
        }
      } finally {
        // Restore visitor environment after this class's initializers
        visitor.environment = originalVisitorEnv;
      }
    }

    // Instance fields from class hierarchy AND mixins should now be initialized.
    Logger.debug(
        "[Instance Init] Finished instance initialization for '$name'. Fields: ${instance._fields}");

    return instance;
  }

  @override
  Object? call(InterpreterVisitor visitor, List<Object?> positionalArguments,
      [Map<String, Object?> namedArguments = const {},
      List<RuntimeType>? typeArguments]) {
    // 1. Create and initialize instance using the new helper
    final instance = createAndInitializeInstance(visitor, typeArguments);

    // 2. Find the UNNAMED constructor
    final constructor = findConstructor(''); // Look for the default constructor

    // 3. Call constructor if found, binding 'this' (which is the instance)
    if (constructor != null) {
      try {
        // The constructor function already has the class closure.
        // Binding it adds 'this' to a new environment enclosing the class closure.
        // Parameter evaluation and body execution will happen in environments
        // enclosing this bound environment.
        final boundConstructor = constructor.bind(instance);
        // Pass initializers to call?
        boundConstructor.call(
            visitor, positionalArguments, namedArguments, typeArguments);
      } on RuntimeError catch (e) {
        throw RuntimeError(
            "Error during constructor execution for class '$name': ${e.message}");
      }
    } else {
      // No explicit constructor found. Check arity for default constructor.
      if (positionalArguments.isNotEmpty || (namedArguments.isNotEmpty)) {
        throw RuntimeError(
            "Class '$name' does not have an unnamed constructor that accepts arguments.");
      }
      // If no constructor and no args passed, it's okay (implicit default constructor).
    }

    // Field initializers from constructor list (e.g., : this.x = y) need separate handling.
    // This should happen *after* field initializers above but *before* constructor body.
    // This logic needs to be added to InterpretedFunction.call for constructors.

    // 4. Return the initialized instance
    return instance;
  }

  @override
  int get arity {
    // Arity of the default (unnamed) constructor
    final constructor = findConstructor('');
    return constructor?.arity ??
        0; // Default constructor has arity 0 if not defined
  }

  /// Returns a map of all abstract members (methods, getters, setters)
  /// inherited from superclasses.
  /// The key is the member name, the value is the abstract InterpretedFunction.
  Map<String, InterpretedFunction> getAbstractInheritedMembers() {
    final abstractMembers = <String, InterpretedFunction>{};
    InterpretedClass? current = superclass;
    while (current != null) {
      // Add abstract members from the current superclass, potentially overwriting
      // less specific ones from further up the chain (though Dart disallows this scenario statically).
      current.methods.forEach((name, func) {
        if (func.isAbstract) {
          abstractMembers.putIfAbsent(name, () => func);
        }
      });
      current.getters.forEach((name, func) {
        if (func.isAbstract) {
          abstractMembers.putIfAbsent(name, () => func);
        }
      });
      current.setters.forEach((name, func) {
        if (func.isAbstract) {
          abstractMembers.putIfAbsent(name, () => func);
        }
      });
      current = current.superclass;
    }
    return abstractMembers;
  }

  /// Returns a map of all concrete instance members (methods, getters, setters)
  /// defined directly in this class.
  /// The key is the member name, the value is the concrete InterpretedFunction.
  Map<String, InterpretedFunction> getConcreteMembers() {
    final concreteMembers = <String, InterpretedFunction>{};
    methods.forEach((name, func) {
      if (!func.isAbstract) {
        concreteMembers[name] = func;
      }
    });
    getters.forEach((name, func) {
      if (!func.isAbstract) {
        concreteMembers[name] = func;
      }
    });
    setters.forEach((name, func) {
      if (!func.isAbstract) {
        concreteMembers[name] = func;
      }
    });
    return concreteMembers;
  }

  /// Returns a map representing all members required by the interfaces implemented
  /// by this class and its superclasses, including those from super-interfaces.
  /// Key: member name, Value: String indicating type ('method', 'getter', 'setter')
  Map<String, String> getAllInterfaceMembers() {
    final requiredMembers = <String, String>{};
    final Set<InterpretedClass> visited = {}; // To avoid cycles/redundancy
    final List<InterpretedClass> queue = [];

    // Start with directly implemented interfaces
    queue.addAll(interfaces);
    // Also consider interfaces/abstract members from superclasses
    var currentSuper = superclass;
    while (currentSuper != null) {
      queue.add(
          currentSuper); // Add superclass to check its interfaces/abstract members
      currentSuper = currentSuper.superclass;
    }

    while (queue.isNotEmpty) {
      final currentClass = queue.removeAt(0);

      if (!visited.add(currentClass)) {
        continue; // Already processed this class/interface
      }

      // Add members defined directly in this interface/class
      // We only care about the *signature* required, not the implementation.
      // Note: Static members are NOT part of the interface contract.
      currentClass.methods.forEach((name, func) {
        // Abstract methods from superclasses also count as required signatures
        requiredMembers.putIfAbsent(
            name, () => func.isAbstract ? 'method' : 'method');
      });
      currentClass.getters.forEach((name, func) {
        requiredMembers.putIfAbsent(
            name, () => func.isAbstract ? 'getter' : 'getter');
      });
      currentClass.setters.forEach((name, func) {
        requiredMembers.putIfAbsent(
            name, () => func.isAbstract ? 'setter' : 'setter');
      });

      // Add interfaces implemented by this class to the queue
      queue.addAll(currentClass.interfaces);
      // Also add its superclass to the queue (if not already visited)
      if (currentClass.superclass != null &&
          !visited.contains(currentClass.superclass)) {
        // No, superclass was added initially. We traverse the interface graph here.
        // We need to get members from the superclass chain separately potentially.
        // Let's reconsider. The check needs *all* members required by interfaces
        // AND *all* abstract members from superclasses.
      }
    }

    // Re-think: The above mixes inherited abstract members and interface members.
    // Let's separate concerns.
    // 1. Get all members required ONLY by interfaces.
    // 2. Get all abstract members inherited via `extends` (already done).
    // 3. The class needs to satisfy BOTH.

    final requiredInterfaceMembers = <String, String>{};
    final Set<InterpretedClass> visitedInterfaces = {};
    final List<InterpretedClass> interfaceQueue = [];
    interfaceQueue.addAll(interfaces);

    // Add interfaces from superclasses as well
    currentSuper = superclass;
    while (currentSuper != null) {
      interfaceQueue.addAll(currentSuper.interfaces);
      currentSuper = currentSuper.superclass;
    }

    while (interfaceQueue.isNotEmpty) {
      final currentInterface = interfaceQueue.removeAt(0);
      if (!visitedInterfaces.add(currentInterface)) {
        continue;
      }

      // Add members from the current interface
      currentInterface.methods.forEach((name, func) {
        requiredInterfaceMembers.putIfAbsent(name, () => 'method');
      });
      currentInterface.getters.forEach((name, func) {
        requiredInterfaceMembers.putIfAbsent(name, () => 'getter');
      });
      currentInterface.setters.forEach((name, func) {
        requiredInterfaceMembers.putIfAbsent(name, () => 'setter');
      });

      // Add its super-interfaces to the queue
      interfaceQueue.addAll(currentInterface.interfaces);
      // IMPORTANT: Also add the interface's OWN superclass to the queue,
      // as the implementing class must satisfy members from the entire hierarchy.
      if (currentInterface.superclass != null) {
        interfaceQueue.add(currentInterface.superclass!); // Non-null asserted
      }
    }

    return requiredInterfaceMembers;
  }

  /// Returns a map of all concrete instance members (methods, getters, setters)
  /// available on this class, including those inherited via the `extends` chain.
  /// Key: member name, Value: the concrete InterpretedFunction.
  Map<String, InterpretedFunction> getAllConcreteMembers() {
    final concreteMembers = <String, InterpretedFunction>{};
    InterpretedClass? current = this;
    while (current != null) {
      // Add concrete members from the current class, avoiding overwrites from subclasses
      current.methods.forEach((name, func) {
        if (!func.isAbstract) {
          concreteMembers.putIfAbsent(name, () => func);
        }
      });
      current.getters.forEach((name, func) {
        if (!func.isAbstract) {
          concreteMembers.putIfAbsent(name, () => func);
        }
      });
      current.setters.forEach((name, func) {
        if (!func.isAbstract) {
          concreteMembers.putIfAbsent(name, () => func);
        }
      });
      current = current.superclass;
    }
    return concreteMembers;
  }

  /// Checks if this class is a subtype of the [other] class.
  /// This considers inheritance (extends), mixin application (with),
  /// and interface implementation (implements).
  @override
  bool isSubtypeOf(RuntimeType other, {Object? value}) {
    if (other is InterpretedClass) {
      // Check for identity (reflexive)
      if (this == other) return true;

      // Check direct inheritance (superclass chain)
      InterpretedClass? current = superclass;
      while (current != null) {
        if (current == other) return true;
        current = current.superclass;
      }

      // Check applied mixins (recursively)
      for (final mixin in mixins) {
        if (mixin.isSubtypeOf(other)) return true;
      }

      // Check implemented interfaces (recursively)
      for (final interface in interfaces) {
        if (interface.isSubtypeOf(other)) return true;
      }

      // Check superclass's mixins and interfaces (transitive)
      if (superclass != null) {
        if (superclass!.isSubtypeOf(other)) return true;
      }

      // Check mixins' superclasses, mixins, and interfaces (transitive)
      // This requires iterating through the mixin application chain implicitly handled above

      // Check interfaces' superclasses, mixins, and interfaces (transitive)
      // This requires iterating through the interface implementation chain implicitly handled above

      // Default case: not a subtype
      return false;
    }
    return false;
  }
}

/// Represents an instance of an InterpretedClass at runtime.
class InterpretedInstance implements RuntimeValue {
  final InterpretedClass klass;
  // Fields are stored here, mapping name to value
  final Map<String, Object?> _fields = {};

  // Store the native object created by a bridged superclass constructor
  Object? bridgedSuperObject;

  // Store generic type arguments for this instance (e.g., for List<String>, this would be [StringType])
  final List<RuntimeType>? typeArguments;

  InterpretedInstance(this.klass, {this.typeArguments});

  /// Get the generic type arguments for this instance
  List<RuntimeType>? getTypeArguments() => typeArguments;

  /// Check if a value is compatible with the expected generic type at the given index
  bool isValueCompatibleWithTypeArgument(Object? value, int typeArgumentIndex) {
    if (typeArguments == null || typeArgumentIndex >= typeArguments!.length) {
      // No type constraints, allow any value
      return true;
    }

    final expectedType = typeArguments![typeArgumentIndex];
    return _isValueCompatibleWithType(value, expectedType);
  }

  /// Check if a value is compatible with a specific type
  bool _isValueCompatibleWithType(Object? value, RuntimeType expectedType) {
    if (value == null) {
      // null is compatible with any nullable type
      // For now, we'll allow null values (later we can add nullable/non-nullable distinction)
      return true;
    }

    // Check for exact type matches first
    if (expectedType is BridgedClass) {
      // For BridgedClass, check if the value's runtime type matches or is a subtype
      return value.runtimeType == expectedType.nativeType ||
          expectedType.nativeType == Object ||
          expectedType.nativeType == dynamic;
    }

    if (expectedType is InterpretedClass) {
      if (value is InterpretedInstance) {
        return _isClassSubtypeOf(value.klass, expectedType);
      }
      return false;
    }

    if (expectedType is bridge.TypeParameter) {
      // Type parameters accept any value for now
      // Later we can implement bounds checking
      return true;
    }

    // Default: allow the value (permissive for now)
    return true;
  }

  /// Check if a class is a subtype of another class (including inheritance)
  bool _isClassSubtypeOf(
      InterpretedClass subClass, InterpretedClass superClass) {
    if (subClass == superClass) {
      return true;
    }

    // Check superclass chain
    InterpretedClass? current = subClass.superclass;
    while (current != null) {
      if (current == superClass) {
        return true;
      }
      current = current.superclass;
    }

    // Check interfaces
    for (final interface in subClass.interfaces) {
      if (_isClassSubtypeOf(interface, superClass)) {
        return true;
      }
    }

    // Check mixins
    for (final mixin in subClass.mixins) {
      if (_isClassSubtypeOf(mixin, superClass)) {
        return true;
      }
    }

    return false;
  }

  /// Validate that a value can be assigned to a field with a specific generic type constraint
  void validateFieldAssignment(
      String fieldName, Object? value, RuntimeType? expectedType) {
    if (expectedType == null) {
      return; // No type constraint
    }

    if (!_isValueCompatibleWithType(value, expectedType)) {
      throw RuntimeError(
          "Type error: Cannot assign value of type '${_getValueTypeName(value)}' to field '$fieldName' expecting type '${expectedType.name}' in class '${klass.name}'");
    }
  }

  /// Get a human-readable type name for a value
  String _getValueTypeName(Object? value) {
    if (value == null) return 'null';
    if (value is InterpretedInstance) return value.klass.name;
    if (value is String) return 'String';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    if (value is List) return 'List';
    if (value is Map) return 'Map';
    return value.runtimeType.toString();
  }

  /// Validate field assignment for generic classes (e.g., List&lt;T&gt;, Map&lt;K,V&gt;)
  void _validateFieldAssignmentGeneric(String fieldName, Object? value) {
    if (typeArguments == null || typeArguments!.isEmpty) {
      return; // No generic constraints to validate
    }

    // For common generic collection types, perform validation
    if (klass.name == 'List' && typeArguments!.isNotEmpty) {
      _validateListElementType(fieldName, value, typeArguments![0]);
    } else if (klass.name == 'Map' && typeArguments!.length >= 2) {
      _validateMapTypes(fieldName, value, typeArguments![0], typeArguments![1]);
    } else if (klass.name == 'Set' && typeArguments!.isNotEmpty) {
      _validateSetElementType(fieldName, value, typeArguments![0]);
    }
    // For custom generic classes, we could add more specific validation here
  }

  /// Validate that a value being added to a List&lt;T&gt; matches type T
  void _validateListElementType(
      String fieldName, Object? value, RuntimeType elementType) {
    if (fieldName == 'add' || fieldName == 'insert' || fieldName == 'addAll') {
      // These operations should validate the element type
      if (fieldName == 'addAll' && value is List) {
        // Validate all elements in the list
        for (int i = 0; i < value.length; i++) {
          if (!_isValueCompatibleWithType(value[i], elementType)) {
            throw RuntimeError(
                "Type error: Cannot add element of type '${_getValueTypeName(value[i])}' at index $i to List<${elementType.name}>");
          }
        }
      } else if (fieldName == 'add' || fieldName == 'insert') {
        // Validate single element
        if (!_isValueCompatibleWithType(value, elementType)) {
          throw RuntimeError(
              "Type error: Cannot add element of type '${_getValueTypeName(value)}' to List<${elementType.name}>");
        }
      }
    }
  }

  /// Validate Map&lt;K,V&gt; key and value types
  void _validateMapTypes(String fieldName, Object? value, RuntimeType keyType,
      RuntimeType valueType) {
    if (fieldName == 'putIfAbsent' || fieldName == 'addAll') {
      if (value is Map) {
        for (final entry in value.entries) {
          if (!_isValueCompatibleWithType(entry.key, keyType)) {
            throw RuntimeError(
                "Type error: Cannot add key of type '${_getValueTypeName(entry.key)}' to Map<${keyType.name}, ${valueType.name}>");
          }
          if (!_isValueCompatibleWithType(entry.value, valueType)) {
            throw RuntimeError(
                "Type error: Cannot add value of type '${_getValueTypeName(entry.value)}' to Map<${keyType.name}, ${valueType.name}>");
          }
        }
      }
    }
  }

  /// Validate Set&lt;T&gt; element type
  void _validateSetElementType(
      String fieldName, Object? value, RuntimeType elementType) {
    if (fieldName == 'add' || fieldName == 'addAll') {
      if (fieldName == 'addAll' && value is Iterable) {
        for (final element in value) {
          if (!_isValueCompatibleWithType(element, elementType)) {
            throw RuntimeError(
                "Type error: Cannot add element of type '${_getValueTypeName(element)}' to Set<${elementType.name}>");
          }
        }
      } else if (fieldName == 'add') {
        if (!_isValueCompatibleWithType(value, elementType)) {
          throw RuntimeError(
              "Type error: Cannot add element of type '${_getValueTypeName(value)}' to Set<${elementType.name}>");
        }
      }
    }
  }

  @override
  String toString() {
    if (typeArguments != null && typeArguments!.isNotEmpty) {
      final typeArgsStr = typeArguments!.map((t) => t.name).join(', ');
      return '<instance of ${klass.name}<$typeArgsStr>>';
    }
    return '<instance of ${klass.name}>';
  }

  // Get: Field -> Getter -> Method (now includes inheritance)
  @override
  Object? get(String name, {InterpreterVisitor? visitor}) {
    Logger.debug(
        "[Instance.get] Looking for '$name' on instance $hashCode of '${klass.name}'. Fields: ${_fields.keys}");

    // Check fields in the current instance first
    if (_fields.containsKey(name)) {
      final fieldValue = _fields[name];
      if (fieldValue is LateVariable) {
        // Return the value of the late variable (will initialize if needed)
        Logger.debug(
            "[Instance.get] Found late field '$name', accessing value...");
        return fieldValue.value;
      }
      Logger.debug(
          "[Instance.get] Found field '$name' with value: $fieldValue");
      return fieldValue;
    }

    Logger.debug(
        "[Instance.get] Field '$name' not found in instance fields. Checking getters/methods...");

    // Check instance members (getter/method) in the current class and superclasses
    InterpretedClass? currentClass = klass;
    while (currentClass != null) {
      final getter = currentClass.findInstanceGetter(name);
      if (getter != null) {
        if (visitor != null) {
          return getter.bind(this).call(visitor, [], {});
        } else {
          return getter.bind(this); // Bind to the *original* instance ('this')
        }
      }

      try {
        final staticField = currentClass.getStaticField(name);
        if (staticField != null) {
          return staticField;
        }
      } catch (_) {}

      final staticGetter = currentClass.findStaticGetter(name);
      if (staticGetter != null) {
        if (visitor != null) {
          return staticGetter.bind(this).call(visitor, [], {});
        } else {
          return staticGetter
              .bind(this); // Bind to the *original* instance ('this')
        }
      }

      final staticMethod = currentClass.findStaticMethod(name);
      if (staticMethod != null) {
        return staticMethod.bind(this);
      }

      final method = currentClass.findInstanceMethod(name);
      if (method != null) {
        return method.bind(this); // Bind to the *original* instance ('this')
      }
      // Move up to the superclass
      currentClass = currentClass.superclass;
    }

    // Check mixins (both interpreted and bridged) - reverse order for correct precedence
    // (Last applied mixin wins in case of conflicts)

    // Check interpreted mixins (in reverse order)
    for (int i = klass.mixins.length - 1; i >= 0; i--) {
      final mixin = klass.mixins[i];

      final getter = mixin.findInstanceGetter(name);
      if (getter != null) {
        if (visitor != null) {
          return getter.bind(this).call(visitor, [], {});
        } else {
          return getter.bind(this);
        }
      }

      final method = mixin.findInstanceMethod(name);
      if (method != null) {
        return method.bind(this);
      }
    }

    // Check bridged mixins (in reverse order)
    for (int i = klass.bridgedMixins.length - 1; i >= 0; i--) {
      final bridgedMixin = klass.bridgedMixins[i];

      // Try getter first
      final getterAdapter = bridgedMixin.findInstanceGetterAdapter(name);
      if (getterAdapter != null) {
        Logger.debug(
            "[Instance.get] Found getter '$name' in bridged mixin '${bridgedMixin.name}'. Calling adapter directly.");
        try {
          // For bridged mixins, call the getter directly and return the value
          return getterAdapter(visitor, this);
        } catch (e, s) {
          Logger.error(
              "Native exception during bridged mixin getter '$name': $e\n$s");
          throw RuntimeError(
              "Native error in bridged mixin getter '$name': $e");
        }
      }

      // Try method next
      final methodAdapter = bridgedMixin.findInstanceMethodAdapter(name);
      if (methodAdapter != null) {
        Logger.debug(
            "[Instance.get] Found method '$name' in bridged mixin '${bridgedMixin.name}'. Creating bound callable.");
        // Return a callable that binds the method to this instance
        return BridgedMixinMethodCallable(
            this, methodAdapter, name, bridgedMixin.name);
      }
    }

    if (klass.bridgedSuperclass != null && bridgedSuperObject != null) {
      final bridgedSuper = klass.bridgedSuperclass!;
      final nativeTarget = bridgedSuperObject!;

      // Try getter first
      final getterAdapter = bridgedSuper.findInstanceGetterAdapter(name);
      if (getterAdapter != null) {
        Logger.debug(
            " [Instance.get] Found getter '$name' in bridged superclass '${bridgedSuper.name}'. Calling adapter.");
        try {
          // Adapter needs visitor (null ok?), target object, name
          // Assuming getter adapter doesn't need visitor?
          // Adapters MUST handle potential exceptions from native code.
          final result = getterAdapter(null, nativeTarget);

          // Check if result is a native enum that has been bridged
          if (result != null && visitor != null) {
            final bridgedEnumValue =
                visitor.environment.getBridgedEnumValue(result);
            if (bridgedEnumValue != null) {
              return bridgedEnumValue;
            }
          }

          return result;
        } catch (e, s) {
          Logger.error(
              "Native exception during bridged superclass getter '$name': $e\n$s");
          throw RuntimeError(
              "Native error in bridged superclass getter '$name': $e");
        }
      }

      // Try method next
      final methodAdapter = bridgedSuper.findInstanceMethodAdapter(name);
      if (methodAdapter != null) {
        Logger.debug(
            " [Instance.get] Found method '$name' in bridged superclass '${bridgedSuper.name}'. Returning bound callable.");
        // Return a callable wrapper that knows the target object and the adapter
        return BridgedSuperMethodCallable(
            nativeTarget, methodAdapter, name, bridgedSuper.name);
      }
    }

    // If not found anywhere in the hierarchy or bridge
    throw RuntimeError("Undefined property '$name' on ${klass.name}.");
  }

  // Find operator method on this instance (supports inheritance and mixins)
  InterpretedFunction? findOperator(String operatorSymbol) {
    // Check instance operators in the current class and superclasses
    InterpretedClass? currentClass = klass;
    while (currentClass != null) {
      final operator = currentClass.findOperator(operatorSymbol);
      if (operator != null) {
        return operator;
      }
      // Move up to the superclass
      currentClass = currentClass.superclass;
    }

    // Check interpreted mixins (in reverse order for correct precedence)
    for (int i = klass.mixins.length - 1; i >= 0; i--) {
      final mixin = klass.mixins[i];
      final operator = mixin.findOperator(operatorSymbol);
      if (operator != null) {
        return operator;
      }
    }

    // No operator found
    return null;
  }

  // Set: Setter -> Field (now includes inheritance for finding setters)
  @override
  void set(String name, Object? value, [InterpreterVisitor? visitor]) {
    Logger.debug(
        "[Instance.set] called for '${klass.name}.$name' with value: $value on instance $hashCode");
    // Look for a setter in the current class and superclasses
    InterpretedClass? currentClass = klass;
    while (currentClass != null) {
      final setter = currentClass.findInstanceSetter(name);
      if (setter != null) {
        // Found a setter, call it on the original instance ('this')
        setter.bind(this).call(visitor!, [value], {});
        return; // Setter called, assignment done
      }
      // Move up to the superclass
      currentClass = currentClass.superclass;
    }

    if (klass.bridgedSuperclass != null && bridgedSuperObject != null) {
      final bridgedSuper = klass.bridgedSuperclass!;
      final nativeTarget = bridgedSuperObject!;
      final setterAdapter = bridgedSuper.findInstanceSetterAdapter(name);

      if (setterAdapter != null) {
        Logger.debug(
            " [Instance.set] Found setter '$name' in bridged superclass '${bridgedSuper.name}'. Calling adapter.");
        try {
          // Adapter needs visitor (null ok?), target object, value
          // Assuming setter adapter doesn't need visitor?
          setterAdapter(null, nativeTarget, value);
          return; // Setter called, assignment done
        } catch (e, s) {
          Logger.error(
              "Native exception during bridged superclass setter '$name': $e\n$s");
          throw RuntimeError(
              "Native error in bridged superclass setter '$name': $e");
        }
      }
    }

    // No setter found in the hierarchy or bridge, assign directly to the field
    Logger.debug(
        "[Instance.set] No setter found for '$name'. Setting field directly. Instance $hashCode");

    // Check if it's a late variable
    if (_fields.containsKey(name)) {
      final fieldValue = _fields[name];
      if (fieldValue is LateVariable) {
        // Assign to the late variable
        fieldValue.assign(value);
        Logger.debug(
            "[Instance.set] Assigned to late field '$name'. Fields now: ${_fields.keys}");
        return;
      }
    }

    // Perform generic type validation if this instance has type arguments
    _validateFieldAssignmentGeneric(name, value);

    _fields[name] = value;
    Logger.debug(
        "[Instance.set] Field '$name' set. Fields now: ${_fields.keys}");
  }

  // Added to allow explicit field access, bypassing getters/methods for super
  Object? getField(String name) {
    // Check if the field exists directly on this instance
    if (_fields.containsKey(name)) {
      return _fields[name];
    }
    // We throw an error if the field doesn't exist directly.
    // Accessing super.fieldName where fieldName is only defined in the superclass
    // isn't standard Dart behavior (you'd typically use super.getterName).
    // This method is primarily for the `super.` property access visitor to get the value.
    throw RuntimeError(
        "Internal Error: Field '$name' not found for super access on instance of ${klass.name}. This might indicate an issue with super property access implementation.");
  }

  // Implémentation de RuntimeValue.valueType (précédemment runtimeType)
  @override
  RuntimeType get valueType => klass;
}

// which pairs an InterpretedFunction with an InterpretedInstance ('this').

// Represents 'super' bound to an instance and a starting class for lookup
class BoundSuper {
  final InterpretedInstance instance; // The actual 'this' instance
  final InterpretedClass startLookupClass; // The superclass where lookup begins

  BoundSuper(this.instance, this.startLookupClass);
}

/// Represents 'super' bound to an instance when the direct superclass is bridged.
class BoundBridgedSuper {
  final InterpretedInstance instance; // The actual 'this' instance
  final BridgedClass
      startLookupClass; // The bridged superclass where lookup begins

  BoundBridgedSuper(this.instance, this.startLookupClass);
}

/// Represents an interpreted record value.
class InterpretedRecord {
  /// Positional field values in order.
  final List<Object?> positionalFields;

  /// Named field values.
  final Map<String, Object?> namedFields;

  InterpretedRecord(this.positionalFields, this.namedFields);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InterpretedRecord) return false;

    // Basic equality check (deep equality might be needed depending on use case)
    if (positionalFields.length != other.positionalFields.length ||
        namedFields.length != other.namedFields.length) {
      return false;
    }

    // Check positional fields
    for (int i = 0; i < positionalFields.length; i++) {
      if (positionalFields[i] != other.positionalFields[i]) return false;
    }

    // Check named fields (order doesn't matter, check keys and values)
    for (final key in namedFields.keys) {
      if (!other.namedFields.containsKey(key) ||
          namedFields[key] != other.namedFields[key]) {
        return false;
      }
    }

    return true;
  }

  @override
  int get hashCode {
    // Simple hash code calculation
    int result = 17;
    result = 31 * result + Object.hashAll(positionalFields);
    // Combine hash codes of named fields (order independent)
    int namedHash = 0;
    for (var entry in namedFields.entries) {
      namedHash ^= Object.hash(entry.key, entry.value);
    }
    result = 31 * result + namedHash;
    return result;
  }

  @override
  String toString() {
    final posStr = positionalFields.join(', ');
    final namedStr =
        namedFields.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    final parts = [
      if (posStr.isNotEmpty) posStr,
      if (namedStr.isNotEmpty) namedStr
    ];
    return '(${parts.join(', ')})';
  }
}

/// Represents an enum definition at runtime.
class InterpretedEnum implements RuntimeType {
  @override
  final String name;

  /// The environment where the enum was declared.
  final Environment declarationEnvironment;

  /// List of enum value names (in declaration order).
  final List<String> valueNames;

  /// Map of enum value names to their runtime instances (populated in interpretation pass).
  final Map<String, InterpretedEnumValue> values = {};

  /// The list of fully resolved enum value instances for the `values` getter.
  List<InterpretedEnumValue>? _valuesListCache;

  final Map<String, InterpretedFunction> methods = {};
  final Map<String, InterpretedFunction> getters = {};
  final Map<String, InterpretedFunction> setters =
      {}; // Though unlikely for enums?
  final Map<String, InterpretedFunction> staticMethods = {};
  final Map<String, InterpretedFunction> staticGetters = {};
  final Map<String, InterpretedFunction> staticSetters = {};
  final Map<String, Object?> staticFields = {};
  final Map<String, InterpretedFunction> constructors = {};

  final List<FieldDeclaration> fieldDeclarations = [];

  // Constructor used during Interpretation Pass (Populates members)
  InterpretedEnum(this.name, this.declarationEnvironment, this.valueNames);

  // Constructor for Declaration Pass (Placeholder)
  InterpretedEnum.placeholder(
      this.name, this.declarationEnvironment, this.valueNames);

  @override
  String toString() => '<enum $name>';

  /// Returns the list of enum values for the static `values` getter.
  /// Populates the cache on first access during interpretation pass.
  List<InterpretedEnumValue> get valuesList {
    if (_valuesListCache == null) {
      if (values.length != valueNames.length) {
        // This shouldn't happen if interpretation pass is correct, but safeguard.
        throw StateError(
            "Enum '$name' values mismatch between declaration and interpretation.");
      }
      // Ensure the order matches the declaration order
      _valuesListCache = valueNames.map((name) => values[name]!).toList();
    }
    return _valuesListCache!;
  }

  // Implement isSubtypeOf
  @override
  bool isSubtypeOf(RuntimeType other, {Object? value}) {
    // An enum is a subtype of itself and Object.
    // For now, we don't handle complex type hierarchies involving enums.
    // We might need to look up 'Object' in the environment later.
    return identical(this, other) || other.name == 'Object';
  }
}

/// Represents a specific value within an enum at runtime.
class InterpretedEnumValue implements RuntimeValue /* Add RuntimeValue */ {
  final InterpretedEnum parentEnum;
  final String name;
  final int index;
  final Map<String, Object?> _fields = {};

  // Constructor now needs the parent Enum definition
  InterpretedEnumValue(this.parentEnum, this.name, this.index);

  @override
  String toString() => '${parentEnum.name}.$name';

  @override
  int get hashCode => Object.hash(parentEnum, index);

  @override
  bool operator ==(Object other) {
    // Enums compare by identity (same enum type and same index)
    return identical(this, other) ||
        (other is InterpretedEnumValue &&
            parentEnum ==
                other.parentEnum && // Check if they belong to the same enum
            index == other.index);
  }

  // RuntimeValue Implementation (get/set/valueType)
  @override
  RuntimeType get valueType =>
      parentEnum; // The type of an enum value is the enum itself

  // Get: Field -> Instance Getter (executed) -> Instance Method (bound)
  @override
  Object? get(String memberName, [InterpreterVisitor? visitor]) {
    // Handle implicit 'name' property
    if (memberName == 'name') {
      Logger.debug(
          " [EnumValue.get] Accessing implicit property 'name'. Returning: $name");
      return name; // Return the stored name of the enum value
    }

    // 1. Check instance fields specific to this enum value
    if (_fields.containsKey(memberName)) {
      final fieldValue = _fields[memberName];
      Logger.debug(
          " [EnumValue.get] Found field '$memberName' with value: $fieldValue");
      return fieldValue;
    }

    // 2. Check instance getters defined on the enum
    final getter = parentEnum.getters[memberName];
    if (getter != null) {
      // We need to call the getter, binding `this` to `this` enum value instance
      // This requires the getter function to be callable with the instance
      if (visitor == null) {
        throw RuntimeError(
            "Internal error: Visitor required to execute enum getter '$memberName'.");
      }
      final boundGetter = getter.bind(this);
      // Call the getter immediately with no arguments
      final getterResult = boundGetter.call(visitor, [], {});
      Logger.debug(
          " [EnumValue.get] Executed getter '$memberName'. Result: $getterResult");
      return getterResult;
    }

    // 3. Check instance methods defined on the enum
    final method = parentEnum.methods[memberName];
    if (method != null) {
      // Return the bound method
      final boundMethod = method.bind(this);
      Logger.debug(
          " [EnumValue.get] Found method '$memberName'. Returning bound method: $boundMethod");
      return boundMethod;
    }

    // Property not found
    throw RuntimeError(
        "Undefined property '$memberName' on enum value '$this'.");
  }

  // Set: Instance Setter -> Field
  @override
  void set(String memberName, Object? value, [InterpreterVisitor? visitor]) {
    Logger.debug(
        "[EnumValue.set] called for '$this.$memberName' with value: $value");
    // 1. Check instance setters defined on the enum
    final setter = parentEnum.setters[memberName];
    if (setter != null) {
      // Call the setter, binding `this`
      setter.bind(this).call(visitor!, [value], {});
      return;
    }

    // 2. Set instance field specific to this enum value
    // Should only allow setting fields declared in the enum? Dart enums usually have final fields.
    // For now, allow setting for flexibility, like InterpretedInstance.
    _fields[memberName] = value;
  }

  // Public method to set fields during initialization
  void setField(String name, Object? value) {
    _fields[name] = value;
  }
}

// Represents a declared extension during interpretation.
class InterpretedExtension {
  final String? name; // Optional name of the extension
  final RuntimeType onType; // The type the extension applies to
  final Map<String, Callable>
      members; // Static methods, instance methods, getters, setters

  InterpretedExtension({
    this.name,
    required this.onType,
    required this.members,
  });

  // Helper to find a member, could be expanded later
  Callable? findMember(String name) {
    return members[name];
  }
}

/// Represents a method call on a bridged superclass object.
/// Stores the specific native super object and the method adapter.
class BridgedSuperMethodCallable implements Callable {
  final Object
      superObject; // The actual native object from the bridged super constructor
  final BridgedMethodAdapter adapter; // The function adapter for the method
  final String methodName;
  final String bridgedClassName;

  BridgedSuperMethodCallable(
      this.superObject, this.adapter, this.methodName, this.bridgedClassName);

  @override
  int get arity => 0; // Arity validation is done by the adapter

  @override
  Object? call(InterpreterVisitor visitor, List<Object?> positionalArguments,
      [Map<String, Object?> namedArguments = const {},
      List<RuntimeType>? typeArguments]) {
    try {
      // Call the adapter, passing the stored native super object as the target
      return adapter(visitor, superObject, positionalArguments, namedArguments);
    } on ArgumentError catch (e) {
      throw RuntimeError(
          "Invalid arguments for bridged superclass method '$bridgedClassName.$methodName': ${e.message}");
    } catch (e, s) {
      Logger.error(
          "Native exception during call to bridged superclass method '$bridgedClassName.$methodName': $e\n$s");
      throw RuntimeError(
          "Native error in bridged superclass method '$bridgedClassName.$methodName': $e");
    }
  }

  @override
  String toString() =>
      '<bridged super method $bridgedClassName.$methodName bound to $superObject>';
}

/// Represents a method call on a bridged mixin applied to an interpreted instance.
class BridgedMixinMethodCallable implements Callable {
  final InterpretedInstance instance;
  final BridgedMethodAdapter adapter;
  final String methodName;
  final String bridgedMixinName;

  BridgedMixinMethodCallable(
      this.instance, this.adapter, this.methodName, this.bridgedMixinName);

  @override
  int get arity => 0; // Arity validation is done by the adapter

  @override
  Object? call(InterpreterVisitor visitor, List<Object?> positionalArguments,
      [Map<String, Object?> namedArguments = const {},
      List<RuntimeType>? typeArguments]) {
    try {
      // For bridged mixins, we need to create a temporary native-like object
      // or handle the call differently since the adapter expects a native object
      // but we have an interpreted instance. For now, we'll pass the instance directly
      // and let the adapter handle the conversion.
      return adapter(visitor, instance, positionalArguments, namedArguments);
    } catch (e, s) {
      Logger.error(
          "[BridgedMixinMethodCallable] Native exception during call to '$bridgedMixinName.$methodName': $e\n$s");
      throw RuntimeError(
          "Native error in bridged mixin method '$bridgedMixinName.$methodName': $e");
    }
  }

  @override
  String toString() {
    return '<bridged mixin method $bridgedMixinName.$methodName>';
  }
}
