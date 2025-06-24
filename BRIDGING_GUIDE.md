# d4rt Bridging Guide

This guide provides a comprehensive overview of how to bridge your native Dart classes and enums for use within the d4rt interpreter. Bridging allows interpreted code to interact seamlessly with your application's existing Dart logic.

## Table of Contents

- [Introduction to Bridging](#introduction-to-bridging)
- [Bridging Enums](#bridging-enums)
  - [Basic Enum Bridging](#basic-enum-bridging)
  - [Advanced Enum Bridging (with Getters and Methods)](#advanced-enum-bridging)
- [Bridging Classes](#bridging-classes)
  - [Core Concepts: `BridgedClassDefinition`](#core-concepts-bridgedclassdefinition)
  - [Registering Bridged Classes](#registering-bridged-classes)
  - [Bridging Constructors](#bridging-constructors)
    - [Default Constructor](#default-constructor)
    - [Named Constructors](#named-constructors)
    - [Argument Handling and Validation](#argument-handling-and-validation)
  - [Bridging Static Members](#bridging-static-members)
    - [Static Getters](#static-getters)
    - [Static Setters](#static-setters)
    - [Static Methods](#static-methods)
  - [Bridging Instance Members](#bridging-instance-members)
    - [Instance Getters](#instance-getters)
    - [Instance Setters](#instance-setters)
    - [Instance Methods](#instance-methods)
  - [Bridging Asynchronous Methods](#bridging-asynchronous-methods)
  - [Advanced Scenarios](#advanced-scenarios)
    - [Passing Bridged Instances as Arguments](#passing-bridged-instances-as-arguments)
    - [Returning Bridged Instances from Methods](#returning-bridged-instances-from-methods)
    - [State Management and Native Errors](#state-management-and-native-errors)
- [Interactions with Interpreted Code](#interactions-with-interpreted-code)
  - [Extending Bridged Classes](#extending-bridged-classes)
  - [Accessing the Native Object](#accessing-the-native-object)
  - [Using `interpreter.invoke()`](#using-interpreterinvoke)
- [Advanced Feature: Native Names Mapping](#advanced-feature-native-names-mapping)
  - [Understanding `nativeNames`](#understanding-nativenames)
  - [The Problem](#the-problem)
  - [The Solution: `nativeNames`](#the-solution-nativenames)
  - [How It Works](#how-it-works)
  - [When to Use `nativeNames`](#when-to-use-nativenames)
  - [Real-World Examples](#real-world-examples)
  - [Best Practices for `nativeNames`](#best-practices-for-nativenames)
- [Best Practices](#best-practices)

---

## Introduction to Bridging

Bridging in d4rt is the mechanism that exposes your application's native Dart code (classes, enums, functions) to the d4rt interpreter. This allows scripts running within the interpreter to create instances of your classes, call their methods, access their properties, and use your enums as if they were defined directly in the script.

This is essential for:
-   Providing a controlled API to scripted parts of your application.
-   Allowing scripts to manipulate native application state.
-   Building powerful plugin systems or dynamic logic execution.

---

## Bridging Enums

Enums are a common way to represent a fixed number of constant values. d4rt allows you to bridge your native Dart enums so they can be used in interpreted scripts.

### Basic Enum Bridging

To bridge a simple Dart enum, you use `BridgedEnumDefinition`.

**Native Dart Enum:**
```dart
// Native Dart code
enum NativeColor { red, green, blue }
```

**Bridge Definition and Registration:**
```dart
// Bridge setup code
import 'package:d4rt/d4rt.dart';
// Assume NativeColor is defined in the same scope or imported

// 1. Define the bridge
final colorDefinition = BridgedEnumDefinition<NativeColor>(
  name: 'BridgedColor', // How the enum will be known in the script
  values: NativeColor.values, // Provide the native enum's values
);

// 2. Register with the interpreter
// The library URI is used for import statements in the script.
interpreter.registerBridgedEnum(colorDefinition, 'package:myapp/custom_types.dart');
```

**Usage in d4rt Script:**
```dart
// d4rt script
import 'package:myapp/custom_types.dart'; // Import the library where BridgedColor was registered

main() {
  var myColor = BridgedColor.green;
  print(myColor.name);   // Accesses the 'name' property (e.g., "green")
  print(myColor.index);  // Accesses the 'index' property (e.g., 1)
  print(myColor);        // Calls toString(), e.g., "BridgedColor.green"

  if (myColor == BridgedColor.green) {
    print('It is green!');
  }
  return myColor.name;
}
```
Running this script would output "green".

### Advanced Enum Bridging (with Getters and Methods)

Dart enums can have fields, getters, and methods. You can expose these to the interpreter by providing adapters in the `BridgedEnumDefinition`.

**Native Dart Enum with Members:**
```dart
// Native Dart code
enum ComplexEnum {
  itemA('Data A', 10),
  itemB('Data B', 20);

  final String data;
  final int number;
  const ComplexEnum(this.data, this.number);

  String get info => '$data-$number (native)';
  int multiply(int factor) => number * factor;
  bool isItemA() => this == ComplexEnum.itemA;

  @override
  String toString() => "NativeComplexEnum.$name"; // Native toString
}
```

**Bridge Definition and Registration:**
```dart
// Bridge setup code
final complexEnumDefinition = BridgedEnumDefinition<ComplexEnum>(
  name: 'MyComplexEnum',
  values: ComplexEnum.values,
  getters: {
    'data': (visitor, target) => (target as ComplexEnum).data,
    'number': (visitor, target) => (target as ComplexEnum).number,
    'info': (visitor, target) => (target as ComplexEnum).info, // Bridge the native getter
  },
  methods: {
    'multiply': (visitor, target, positionalArgs, namedArgs) {
      if (target is ComplexEnum && positionalArgs.length == 1 && positionalArgs[0] is int) {
        return target.multiply(positionalArgs[0] as int);
      }
      throw ArgumentError('Invalid arguments for multiply');
    },
    'isItemA': (visitor, target, positionalArgs, namedArgs) {
      if (target is ComplexEnum && positionalArgs.isEmpty && namedArgs.isEmpty) {
        return target.isItemA();
      }
      throw ArgumentError('Invalid arguments for isItemA');
    },
    // Optionally, override toString behavior for the bridged enum value
    'toString': (visitor, target, positionalArgs, namedArgs) {
      if (target is ComplexEnum) {
        return 'MyComplexEnum.${target.name} (bridged)';
      }
      throw ArgumentError('Invalid target for toString');
    },
  },
);

interpreter.registerBridgedEnum(complexEnumDefinition, 'package:myapp/complex_types.dart');
```

**Usage in d4rt Script:**
```dart
// d4rt script
import 'package:myapp/complex_types.dart';

main() {
  var item = MyComplexEnum.itemA;
  print(item.data);        // "Data A"
  print(item.number);      // 10
  print(item.info);        // "Data A-10 (native)"
  print(item.multiply(3)); // 30
  print(item.isItemA());   // true
  print(item);             // "MyComplexEnum.itemA (bridged)"
  return item.info;
}
```

---

## Bridging Classes

Bridging classes allows your interpreted scripts to instantiate and interact with your native Dart objects.

### Core Concepts: `BridgedClassDefinition`

The `BridgedClassDefinition` is the cornerstone for bridging classes. It describes how a native Dart class should be exposed to the interpreter, including its constructors, static members, and instance members.

Key properties of `BridgedClassDefinition`:
-   `nativeType`: The `Type` object of the native Dart class (e.g., `MyNativeClass`).
-   `name`: The name by which the class will be known in the d4rt script (e.g., `'MyBridgedClass'`).
-   `constructors`: A map of constructor adapters.
-   `staticGetters`, `staticSetters`, `staticMethods`: Maps for static member adapters.
-   `getters`, `setters`, `methods`: Maps for instance member adapters.

### Registering Bridged Classes

Similar to enums, bridged classes are registered with an interpreter instance, typically associated with a library URI for script imports.

```dart
// Bridge setup code
// Assume NativeCounter class is defined
final counterDefinition = BridgedClassDefinition(
  nativeType: NativeCounter,
  name: 'Counter',
  // ... constructor and member definitions ...
);

interpreter.registerBridgedClass(counterDefinition, 'package:myapp/native_utils.dart');
```

**Usage in d4rt Script:**
```dart
// d4rt script
import 'package:myapp/native_utils.dart';

main() {
  var myCounter = Counter(10); // Using a bridged constructor
  myCounter.increment();
  return myCounter.value;
}
```

### Bridging Constructors

You can expose one or more constructors of your native class.

#### Default Constructor
The default (unnamed) constructor is bridged using an empty string `''` as the key in the `constructors` map.

```dart
// Native Class
class NativeLogger {
  String prefix;
  NativeLogger(this.prefix);
  void log(String message) => print('$prefix: $message');
}

// Bridge Definition
final loggerDefinition = BridgedClassDefinition(
  nativeType: NativeLogger,
  name: 'Logger',
  constructors: {
    '': (visitor, positionalArgs, namedArgs) {
      if (positionalArgs.length == 1 && positionalArgs[0] is String) {
        return NativeLogger(positionalArgs[0] as String);
      }
      throw ArgumentError('Logger constructor expects one string argument (prefix).');
    },
  },
  // ... methods ...
);
```

**Script Usage:**
```dart
var logger = Logger('MyScript'); // Calls the bridged default constructor
```

#### Named Constructors
Named constructors are bridged using their name as the key.

```dart
// Native Class
class User {
  String name;
  int age;
  User(this.name, this.age);
  User.guest() : name = 'Guest', age = 0;
}

// Bridge Definition
final userDefinition = BridgedClassDefinition(
  nativeType: User,
  name: 'User',
  constructors: {
    '': (visitor, positionalArgs, namedArgs) { /* ... default constructor ... */ },
    'guest': (visitor, positionalArgs, namedArgs) {
      if (positionalArgs.isEmpty && namedArgs.isEmpty) {
        return User.guest();
      }
      throw ArgumentError('User.guest constructor expects no arguments.');
    },
  },
  // ... members ...
);
```

**Script Usage:**
```dart
var guestUser = User.guest();
```

#### Argument Handling and Validation
Constructor adapters receive:
-   `InterpreterVisitor visitor`: Provides context if needed for complex argument evaluation (rarely used directly in simple adapters).
-   `List<Object?> positionalArgs`: A list of evaluated positional arguments from the script.
-   `Map<String, Object?> namedArgs`: A map of evaluated named arguments from the script.

It's crucial to validate the number and types of arguments within your adapter and throw `ArgumentError` or similar if they don't match expectations.

```dart
// Example from NativeCounter constructor in tests:
// Counter.withId(id, initialValue: 0)
'withId': (visitor, positionalArgs, namedArgs) {
  if (positionalArgs.length != 1 || positionalArgs[0] is! String) {
    throw ArgumentError('Named constructor \'withId\' expects 1 String positional arg (id)');
  }
  final id = positionalArgs[0] as String;

  int initialValue = 0;
  if (namedArgs.containsKey('initialValue')) {
    if (namedArgs['initialValue'] is! int?) { // Allows int or null
      throw ArgumentError('Named arg \'initialValue\' must be an int?');
    }
    initialValue = namedArgs['initialValue'] as int? ?? 0; // Handle null
  }
  return NativeCounter.withId(id, initialValue: initialValue);
}
```

### Bridging Static Members

Static members belong to the class itself, not instances.

#### Static Getters
```dart
// Native: static int NativeCounter.staticValue;
staticGetters: {
  'staticValue': (visitor) => NativeCounter.staticValue,
}
// Script: var val = Counter.staticValue;
```

#### Static Setters
```dart
// Native: static set NativeCounter.staticValue(int v);
staticSetters: {
  'staticValue': (visitor, value) {
    if (value is! int) throw ArgumentError('staticValue requires an int');
    NativeCounter.staticValue = value;
  },
}
// Script: Counter.staticValue = 100;
```

#### Static Methods
```dart
// Native: static String NativeCounter.staticMethod(String prefix);
staticMethods: {
  'staticMethod': (visitor, positionalArgs, namedArgs) {
    if (positionalArgs.length == 1 && positionalArgs[0] is String) {
      return NativeCounter.staticMethod(positionalArgs[0] as String);
    }
    throw ArgumentError('staticMethod expects 1 string argument');
  },
}
// Script: var result = Counter.staticMethod('INFO');
```

### Bridging Instance Members

Instance members operate on an instance of the class. Adapters for instance members receive the `target` object (the native instance).

#### Instance Getters
The `visitor` argument in instance getter/setter adapters is often optional (`InterpreterVisitor? visitor`) if not directly used.
```dart
// Native: int NativeCounter.value; (getter)
getters: {
  'value': (visitor, target) {
    if (target is NativeCounter) return target.value;
    throw TypeError(); // Or a more specific error
  },
}
// Script: var count = myCounter.value;
```

#### Instance Setters
```dart
// Native: set NativeCounter.value(int v);
setters: {
  'value': (visitor, target, value) {
    if (target is NativeCounter && value is int) {
      target.value = value;
    } else {
      throw ArgumentError('Setter expects NativeCounter target and int value');
    }
  },
}
// Script: myCounter.value = 50;
```

#### Instance Methods
```dart
// Native: void NativeCounter.increment([int amount = 1]);
methods: {
  'increment': (visitor, target, positionalArgs, namedArgs) {
    if (target is NativeCounter) {
      if (positionalArgs.isEmpty) {
        target.increment();
      } else if (positionalArgs.length == 1 && positionalArgs[0] is int) {
        target.increment(positionalArgs[0] as int);
      } else {
        throw ArgumentError('increment expects 0 or 1 int argument');
      }
      return null; // For void methods
    }
    throw TypeError();
  },
}
// Script: myCounter.increment(); myCounter.increment(5);
```

**Special Method Names for Operators:**
Index operators `[]` and `[]=` are bridged as instance methods with special names:
-   `operator[]`: Bridge as a method named `'[]'`.
    ```dart
    // For Uint8List[]
    '[]': (visitor, target, positionalArgs, namedArgs) {
       if (target is Uint8List && positionalArgs.length == 1 && positionalArgs[0] is int) {
        return target[positionalArgs[0] as int];
      }
      throw ArgumentError("Invalid arguments for Uint8List[index]");
    }
    ```
-   `operator[] =`: Bridge as a method named `'[]='`.
    ```dart
    // For Uint8List[]=
    '[]=': (visitor, target, positionalArgs, namedArgs) {
      if (target is Uint8List && positionalArgs.length == 2 && 
          positionalArgs[0] is int && positionalArgs[1] is int) {
        final index = positionalArgs[0] as int;
        final value = positionalArgs[1] as int;
        target[index] = value;
        return value; // Dart's []= operator returns the assigned value.
      }
      throw ArgumentError("Invalid arguments for Uint8List[index] = value.");
    }
    ```

### Bridging Asynchronous Methods

If your native methods return a `Future`, d4rt can handle them correctly, allowing you to use `await` in your scripts. The bridge adapter simply returns the `Future` instance.

```dart
// Native Class
class AsyncService {
  Future<String> fetchData(String id) async {
    await Future.delayed(Duration(milliseconds: 100));
    return "Data for $id";
  }
  Future<void> performAction() async { /* ... */ }
  Future<NativeCounter> createCounterAsync(int val) async { /* ... */ return NativeCounter(val); }
}

// Bridge Definition (partial)
final asyncServiceDefinition = BridgedClassDefinition(
  nativeType: AsyncService,
  name: 'AsyncService',
  constructors: { /* ... */ },
  methods: {
    'fetchData': (visitor, target, positionalArgs, namedArgs) {
      if (target is AsyncService && positionalArgs.length == 1 && positionalArgs[0] is String) {
        return target.fetchData(positionalArgs[0] as String); // Return Future<String>
      }
      throw ArgumentError('Invalid args for fetchData');
    },
    'performAction': (visitor, target, positionalArgs, namedArgs) {
      if (target is AsyncService && positionalArgs.isEmpty) {
        return target.performAction(); // Return Future<void>
      }
      throw ArgumentError('Invalid args for performAction');
    },
    'createCounterAsync': (visitor, target, positionalArgs, namedArgs) {
      if (target is AsyncService && positionalArgs.length == 1 && positionalArgs[0] is int) {
        return target.createCounterAsync(positionalArgs[0] as int); // Return Future<NativeCounter>
      }
      throw ArgumentError('Invalid args for createCounterAsync');
    }
  }
);
```

**Script Usage:**
```dart
// d4rt script
import 'package:myapp/services.dart'; // Assuming AsyncService is registered here

main() async {
  var service = AsyncService(); // Assuming a bridged constructor
  
  var data = await service.fetchData('user123');
  print(data); // "Data for user123"
  
  await service.performAction();
  print('Action performed');

  var counter = await service.createCounterAsync(50); // counter will be a bridged Counter instance
  counter.increment();
  print(counter.value); // 51
  
  try {
    // await service.methodThatFails(); // If it returns a Future.error
  } catch (e) {
    print('Caught error: \$e');
  }
  return data;
}
```
If a bridged async method returns a `Future` that completes with an error (e.g., `Future.error(...)` or an exception is thrown within the async native method), the error will be propagated to the d4rt script and can be caught using a `try-catch` block.

### Advanced Scenarios

#### Passing Bridged Instances as Arguments
You can pass instances of bridged classes (obtained in the script) as arguments to other bridged methods. The adapter will receive the argument. It might be a `BridgedInstance` wrapper or, in some cases, the unwrapped native object. Your adapter should be prepared to handle this, often by checking the type or attempting to access `nativeObject` if it's a `BridgedInstance`.

```dart
// Native: bool NativeCounter.isSame(NativeCounter other);
// Bridge Adapter for 'isSame':
'isSame': (visitor, target, positionalArgs, namedArgs) {
  if (target is NativeCounter && positionalArgs.length == 1) {
    final arg = positionalArgs[0];
    NativeCounter? otherNative;

    if (arg is BridgedInstance && arg.nativeObject is NativeCounter) {
      otherNative = arg.nativeObject as NativeCounter;
    } else if (arg is NativeCounter) { // If already unwrapped
      otherNative = arg;
    }

    if (otherNative != null) {
      return target.isSame(otherNative);
    }
    throw ArgumentError('Invalid argument for isSame: Expected Counter, got \${arg?.runtimeType}');
  }
  throw ArgumentError('Invalid arguments for isSame');
}

// Script:
// var c1 = Counter(10);
// var c2 = Counter(10);
// print(c1.isSame(c2)); // true
```

#### Returning Bridged Instances from Methods
If a native bridged method (synchronous or asynchronous) returns an instance of another (or the same) bridged type, d4rt will automatically attempt to wrap the returned native object into a `BridgedInstance` that can be used in the script.

```dart
// Native: NativeCounter AsyncProcessor.createCounterSync(int val, String id);
// Adapter:
'createCounterSync': (visitor, target, positionalArgs, namedArgs) {
  if (target is AsyncProcessor && positionalArgs.length == 2 && 
      positionalArgs[0] is int && positionalArgs[1] is String) {
    return target.createCounterSync(positionalArgs[0] as int, positionalArgs[1] as String); 
    // Returns NativeCounter, d4rt wraps it.
  }
  throw ArgumentError('Invalid args');
}

// Script:
// var processor = AsyncProcessor();
// var counter = processor.createCounterSync(100, 'sync-id'); // counter is a usable bridged Counter
// counter.increment();
// print(counter.value); // 101
```

#### State Management and Native Errors
If your native class methods can throw exceptions (e.g., `StateError` if an object is used after being disposed), these exceptions will typically be caught by the d4rt bridge layer and re-thrown as a `RuntimeError` within the script, often containing the original error's message.

```dart
// Native:
// void NativeCounter.dispose() { _isDisposed = true; }
// int get value { if (_isDisposed) throw StateError('Instance disposed'); return _value; }

// Script:
// var c = Counter(1);
// c.dispose();
// try {
//   print(c.value); 
// } catch (e) {
//   print('Error: \$e'); // Error: RuntimeError: Unexpected error: Bad state: Instance disposed
// }
```

---

## Interactions with Interpreted Code

### Extending Bridged Classes
Interpreted Dart code can extend classes that have been bridged from native Dart.

```dart
// d4rt script
import 'package:myapp/native_utils.dart'; // Where 'Counter' is bridged

class ScriptCounter extends Counter {
  String scriptId;

  // Call super constructor (default or named)
  ScriptCounter(int initialValue, String nativeId, this.scriptId) 
    : super(initialValue, nativeId); // Calls Counter(value, id)

  ScriptCounter.special(String nativeId, this.scriptId, {int val = 0})
    : super.withId(nativeId, initialValue: val); // Calls Counter.withId(...)

  // Override a bridged method
  @override
  void increment([int amount = 1]) {
    super.value = super.value + (amount * 2); // Custom logic, using super.value
    print('ScriptCounter incremented!');
  }

  String getInfo() {
    return "ScriptCounter(\$scriptId) with native id \$id and value \$value";
    // Accesses 'id' and 'value' from bridged 'Counter' superclass
  }
}

main() {
  var sc = ScriptCounter(10, 'native-A', 'script-X');
  sc.increment(3); // Calls overridden increment. 10 + (3*2) = 16
  print(sc.value);     // 16
  print(sc.getInfo()); // "ScriptCounter(script-X) with native id native-A and value 16"
  
  var sc2 = ScriptCounter.special('native-B', 'script-Y', val: 5);
  print(sc2.value);    // 5
  return sc.value;
}
```
-   Constructors in the script class can call `super(...)` to invoke bridged constructors of the native superclass.
-   Overridden methods can use `super.methodName(...)` to call the original bridged method or access bridged getters/setters via `super.propertyName`.

### Accessing the Native Object
For an interpreted instance that extends a bridged class, you might sometimes need to access the underlying native object. d4rt provides mechanisms for this, though it's a more advanced use case.
The `bridgedSuperObject` property on an `InterpretedInstance` (if it extends a bridged class) can give access to the native part of the object.

```dart
// (From test/bridge/bridged_class_test.dart)
// NativeCounter nativeCounter = interpretedInstance.bridgedSuperObject as NativeCounter;
// nativeCounter.increment(2); // Calls the *actual* native method, bypassing overrides
```
This is useful for scenarios where you specifically need to interact with the non-overridden native behavior.

### Using `interpreter.invoke()`
The `interpreter.invoke(String methodName, List<Object?> positionalArgs, [Map<String, Object?> namedArgs = const {}])` method allows you to call methods or getters on the *last successfully evaluated expression or returned instance* from an `interpreter.execute()` call that resulted in an instance.

This is particularly useful for:
-   Testing or interacting with an instance when you don't want to write a full script just to call one method.
-   Invoking methods that might be overridden in an interpreted class.

```dart
// Setup
final source = '''
  class MyWidget {
    String _label = "Initial";
    String get label => _label;
    void updateLabel(String newLabel) { _label = newLabel; }
    String format(String prefix) => prefix + ": " + _label;
  }
  main() => MyWidget(); // Script returns an instance
''';
final instance = interpreter.execute(source: source) as InterpretedInstance;

// Invoke getter 'label'
var label = interpreter.invoke('label', []);
print(label); // "Initial"

// Invoke method 'updateLabel'
interpreter.invoke('updateLabel', ['New Value']);

// Invoke getter again to see change
label = interpreter.invoke('label', []);
print(label); // "New Value"

// Invoke method with arguments
var formatted = interpreter.invoke('format', ['INFO']);
print(formatted); // "INFO: New Value"
```

If `interpreter.execute()` returns an instance of an interpreted class that overrides methods from a bridged superclass, `interpreter.invoke()` will call the *overridden* versions.

---

## Advanced Feature: Native Names Mapping

### Understanding `nativeNames`

When working with complex Dart libraries, you may encounter a situation where the interpreter fails to recognize certain native objects with errors like:

```
RuntimeError: No registered bridged class found for native type _MultiStream
```

This happens because many Dart classes have internal implementation classes that are not directly exposed in the public API, but are used internally by the Dart runtime. For example, the `Stream` class has many internal implementations:

- `_MultiStream` (created by `Stream.fromIterable()`)
- `_ControllerStream` (created by `StreamController`)
- `_BroadcastStream` (created by broadcast streams)
- `_AsBroadcastStream` (created by `stream.asBroadcastStream()`)
- And many more...

### The Problem

When your d4rt script creates a Stream using native methods, the actual object returned might be one of these internal implementations. The interpreter tries to bridge this object, but finds no registered bridge for `_MultiStream` - it only knows about `Stream`.

### The Solution: `nativeNames`

The `nativeNames` parameter in `BridgedClassDefinition` solves this by providing a list of alternative class names that should be mapped to the same bridge:

```dart
// Example from Stream bridging
class StreamAsync {
  static BridgedClassDefinition get definition => BridgedClassDefinition(
    nativeType: Stream,
    name: 'Stream',
    // Map all these internal Stream implementations to the same Stream bridge
    nativeNames: [
      '_MultiStream',
      '_ControllerStream', 
      '_BroadcastStream',
      '_AsBroadcastStream',
      '_StreamHandlerTransformer',
      '_BoundSinkStream',
      '_ForwardingStream',
      '_MapStream',
      '_WhereStream',
      '_ExpandStream',
      '_TakeStream',
      '_SkipStream',
      '_DistinctStream',
    ],
    methods: {
      // ... your stream methods
    },
  );
}
```

### How It Works

When the interpreter encounters a native object:

1. **First attempt**: Look for an exact match by `nativeType`
2. **Second attempt**: If no exact match, check if the runtime type name starts with `_` (indicating internal class)
3. **Third attempt**: Search through all registered bridges and check their `nativeNames` lists
4. **Fallback**: If still no match, check for generic type patterns

This is implemented in `Environment.toBridgedClass()`:

### When to Use `nativeNames`

You should consider using `nativeNames` when:

1. **Library Integration**: You're bridging classes from complex Dart libraries (like `dart:async`, `dart:collection`, `dart:io`)

2. **Runtime Errors**: You see "No registered bridged class found" errors for types starting with `_`

3. **Generic Classes**: You're working with generic classes that have multiple internal implementations

4. **Abstract Classes**: You're bridging abstract classes that have concrete implementations

### Real-World Examples

#### Stream Example
```dart
// Without nativeNames: 
// RuntimeError: No registered bridged class found for native type _MultiStream

// With nativeNames:
static BridgedClassDefinition get definition => BridgedClassDefinition(
  nativeType: Stream,
  name: 'Stream',
  nativeNames: ['_MultiStream', '_ControllerStream', /* ... */],
  // Now Stream.fromIterable([1,2,3]).toList() works in scripts!
);
```

### Best Practices for `nativeNames`

1. **Research the Library**: Use `runtimeType.toString()` to discover internal class names when testing

2. **Be Comprehensive**: Include all common internal implementations you encounter

3. **Stay Updated**: Internal class names may change between Dart versions

4. **Document Your Mappings**: Comment why specific `nativeNames` are needed

5. **Test Thoroughly**: Verify that methods work correctly on all mapped types

```dart
// Good example with documentation
static BridgedClassDefinition get definition => BridgedClassDefinition(
  nativeType: Stream,
  name: 'Stream',
  // Internal Stream implementations discovered through testing:
  // _MultiStream: Stream.fromIterable()
  // _ControllerStream: StreamController().stream  
  // _BroadcastStream: broadcast streams
  nativeNames: [
    '_MultiStream',      // fromIterable, fromFuture
    '_ControllerStream', // StreamController
    '_BroadcastStream',  // broadcast streams
    // ... add more as discovered
  ],
  methods: {
    'toList': (visitor, target) => (target as Stream).toList(),
    // This now works for ALL the mapped internal types!
  },
);
```

This feature is essential for creating robust bridges that work with the full ecosystem of Dart's internal implementations, ensuring your interpreted scripts can seamlessly interact with complex native objects.

---

## Best Practices

-   **Clear Naming:** Use distinct and clear names for your bridged types in the `name` property of definitions to avoid confusion in scripts.
-   **Robust Adapters:**
    -   Thoroughly validate argument counts and types in your adapter functions. Throw `ArgumentError` for mismatches.
    -   Handle potential `null` values for arguments carefully.
    -   Ensure your adapters correctly map script types to native types and vice-versa.
-   **Error Handling:** Native methods called by adapters might throw exceptions. While d4rt often wraps these in `RuntimeError`, consider if specific error handling or type conversion is needed within the adapter itself for clarity in the script.
-   **Keep Adapters Lean:** Adapters should primarily focus on the "bridging" aspect (type conversion, argument forwarding). Avoid putting complex business logic directly into adapter functions; keep that in your native classes.
-   **Documentation:** Document your bridged APIs (available methods, properties, constructor arguments) for script writers.
-   **Testing:** Thoroughly test your bridges with various valid and invalid inputs from the script side to ensure they behave as expected.

This guide covers the main aspects of bridging in d4rt. Refer to the example files in the d4rt repository (especially under `test/bridge/`) for more detailed and specific examples of these concepts in action. 