# d4rt

[![Pub package](https://img.shields.io/pub/v/d4rt.svg)](https://pub.dev/packages/d4rt)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**d4rt** (pronounced "dart") is an interpreter and runtime for the Dart language, written in Dart.  
It allows you to execute Dart code dynamically, bridge native classes, and build advanced scripting or plugin systems in your Dart/Flutter applications.

---

## Features

- **Dart interpreter**: Run Dart code dynamically at runtime.
- **Full generics support**: Complete support for generic classes, functions, and type constraints with runtime validation.
- **Type bounds checking**: Enforce generic type constraints (e.g., `T extends num`) with dynamic resolution.
- **Bridging system**: Expose your own Dart/Flutter classes, enums, and methods to interpreted code.
- **Async/await support**: Handle asynchronous code and Futures.
- **Class, enum, and extension support**: Use most Dart language features, including classes, inheritance, mixins, enums, and extensions.
- **Pattern matching**: Support for Dart's pattern matching in switch/case and assignments.
- **Runtime type validation**: Validate generic type arguments and method parameters at runtime.
- **Security sandboxing**: Permission-based security system to restrict dangerous operations and prevent malicious code execution.
- **Custom logging**: Integrated, configurable logger for debugging interpreted code.
- **Function argument passing**: Pass positional and named arguments directly to functions via `execute()`.
- **Code introspection**: Analyze Dart code structure with the `analyze()` method to extract metadata.
- **Dynamic code evaluation**: Execute code dynamically with `eval()` while preserving execution state.
- **Extensible**: Add your own bridges for custom types and native APIs.

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  d4rt: # latest version
```

Then run:

```sh
dart pub get
```

---

## Usage Example

```dart
import 'package:d4rt/d4rt.dart';

void main() {
  final code = '''
    int fib(int n) {
      if (n <= 1) return n;
      return fib(n - 1) + fib(n - 2);
    }
    main() {
      return fib(6);
    }
  ''';

  final interpreter = D4rt();
  final result = interpreter.execute(source: code);
  print('Result: $result'); // Result: 8
}
```
## Advanced Features

### Function Argument Passing

Pass positional and named arguments directly to functions:

```dart
final interpreter = D4rt();

final result = interpreter.execute(
  source: '''
    String greet(String name, {String greeting = "Hello"}) {
      return "\$greeting, \$name!";
    }
  ''',
  name: 'greet',
  positionalArgs: ['Alice'],
  namedArgs: {'greeting': 'Hi'},
);
print(result); // Hi, Alice!
```

### Code Introspection

Analyze Dart code structure without execution:

```dart
final interpreter = D4rt();

final analysis = interpreter.analyze('''
  class User {
    String name;
    int age;
    User(this.name, this.age);
  }
  
  int getAge(User user) => user.age;
''');

// Access metadata about functions, classes, variables, etc.
print(analysis.functions['getAge']?.parameters);
print(analysis.classes['User']?.constructors);
```

### Dynamic Code Evaluation

Execute code dynamically while preserving execution state:

```dart
final interpreter = D4rt();

interpreter.execute(source: 'int x = 10;');
final result = interpreter.eval('x + 5'); // Returns 15
```
## Security Sandboxing

d4rt includes a comprehensive permission-based security system to prevent malicious code execution. By default, access to dangerous modules like `dart:io` and `dart:isolate` is blocked unless explicitly granted.

### Granting Permissions

```dart
import 'package:d4rt/d4rt.dart';

void main() {
  final interpreter = D4rt();

  // Grant filesystem access
  interpreter.grant(FilesystemPermission.any);

  // Grant network access
  interpreter.grant(NetworkPermission.any);

  // Grant process execution
  interpreter.grant(ProcessRunPermission.any);

  // Grant isolate operations
  interpreter.grant(IsolatePermission.any);

  // Now execute code that uses dangerous operations
  final result = interpreter.execute(source: '''
    import 'dart:io';
    import 'dart:isolate';

    void main() {
      // This code can now access filesystem, network, etc.
      print('Secure execution with granted permissions');
    }
  ''');
}
```

### Permission Types

- **`FilesystemPermission`**: Controls file and directory operations
  - `FilesystemPermission.any` - Allow all filesystem operations
  - `FilesystemPermission.read` - Allow read-only operations
  - `FilesystemPermission.write` - Allow write operations
  - `FilesystemPermission.path('/specific/path')` - Allow operations on specific paths

- **`NetworkPermission`**: Controls network operations
  - `NetworkPermission.any` - Allow all network operations
  - `NetworkPermission.connect('host:port')` - Allow connections to specific hosts

- **`ProcessRunPermission`**: Controls process execution
  - `ProcessRunPermission.any` - Allow execution of any command
  - `ProcessRunPermission.command('specific-command')` - Allow execution of specific commands

- **`IsolatePermission`**: Controls isolate creation and communication
  - `IsolatePermission.any` - Allow all isolate operations

### Permission Management

```dart
final interpreter = D4rt();

// Grant permissions
interpreter.grant(FilesystemPermission.any);

// Check permissions
if (interpreter.hasPermission(FilesystemPermission.any)) {
  print('Filesystem access granted');
}

// Revoke permissions
interpreter.revoke(FilesystemPermission.any);
```

## Bridging Native Classes & Enums

d4rt provides a powerful bridging system that allows you to automate the process of exposing your Dart and Flutter classes, enums, and functions to the interpreter using `build_runner`.

### Automated Bridge Generation (Recommended)

1. **Add `build_runner` and `d4rt` dev dependencies:**

   ```yaml
   dev_dependencies:
     build_runner: ^2.4.0
   ```

2. **Annotate your classes or enums with `@D4rtBridge()`:**

   ```dart
   import 'package:d4rt/d4rt.dart';
   part 'color.g.dart';
   @D4rtBridge(libraryUri: 'package:app/color.dart')
   class Color {
     final int value;
     const Color(this.value);
     
     static const Color black = Color(0xFF000000);
     
     int get red => (value >> 16) & 0xFF;
   }
   ```

3. **Run the code generator:**

   ```sh
   dart run build_runner build
   ```

   This will generate a `.g.dart` file containing the bridge definitions and an automatic registration function.

4. **Register the bridges with the interpreter:**

   ```dart
   import 'package:d4rt/d4rt.dart';
   import 'color.dart'; // Import the generated file

   void main() {
     final interpreter = D4rt();
     
     // Register all bridges in the file with a single line:
     registerColorBridges(interpreter);
     
     // Now 'Color' is available in the interpreter under 'package:app/color.dart'
   }
   ```

### Manual Bridge Definition

If you prefer to define bridges manually (without code generation), you can use the `BridgedClass` and `BridgedEnumDefinition` classes:

#### Bridge a Dart Class (Manual)

```dart
import 'package:d4rt/d4rt.dart';

class MyClass {
  int value;
  MyClass(this.value);
  int doubleValue() => value * 2;
}

final myClassBridge = BridgedClass(
  nativeType: MyClass,
  name: 'MyClass',
  constructors: {
    '': (InterpreterVisitor visitor, List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
      if (positionalArgs.length == 1 && positionalArgs[0] is int) {
        return MyClass(positionalArgs[0] as int);
      }
      throw ArgumentError('MyClass constructor expects one integer argument.');
    },
  },
  methods: {
    'doubleValue': (InterpreterVisitor visitor, Object target, List<Object?> positionalArgs, Map<String, Object?> namedArgs) {
      if (target is MyClass) {
        return target.doubleValue();
      }
      throw TypeError();
    },
  },
  getters: {
    'value': (InterpreterVisitor? visitor, Object target) {
      if (target is MyClass) {
        return target.value;
      }
      throw TypeError();
    },
  },
);

void main() {
  final interpreter = D4rt();
  interpreter.registerBridgedClass(myClassBridge, 'package:example/my_class_library.dart');

  final code = '''
    import 'package:example/my_class_library.dart';

    main() {
      var obj = MyClass(21);
      return obj.doubleValue();
    }
  ''';

  final result = interpreter.execute(source: code);
  print(result); // 42
}
```

#### Bridge a Dart Enum (Manual)

```dart
import 'package:d4rt/d4rt.dart';

enum Color { red, green, blue }

final colorEnumBridge = BridgedEnumDefinition<Color>(
  name: 'Color',
  values: Color.values,
);

void main() {
  final interpreter = D4rt();
  interpreter.registerBridgedEnum(colorEnumBridge, 'package:example/my_enum_library.dart');

  final code = '''
    import 'package:example/my_enum_library.dart';

    main() {
      var favoriteColor = Color.green;
      print('My favorite color is \${favoriteColor.name}');
      return favoriteColor.index;
    }
  ''';

  final result = interpreter.execute(source: code);
  print(result); // 1
}
```

### Advanced Annotation Options

The `@D4rtBridge` annotation provides several configuration parameters:

- `libraryUri`: The namespace where the class will be registered (e.g., `'package:app/color.dart'`).
- `includePrivate`: Whether to generate bridges for private members (default: `false`).
- `bridgeName`: A custom variable name for the generated bridge (useful for avoiding name collisions).

Example:
```dart
@D4rtBridge(
  libraryUri: 'package:app/models.dart',
  includePrivate: true,
  bridgeName: 'customUserBridge',
)
class User { ... }
```

---

## Supported Features

| Feature                        | Status / Notes                                                                 |
|--------------------------------|-------------------------------------------------------------------------------|
| Classes & Inheritance          | ✅ Full support (abstract, inheritance, mixins, interfaces, sealed, base, final) |
| Enums                          | ✅ Full support (fields, methods, static, named values, index, name)           |
| Mixins                         | ✅ Supported (declaration, application, on clause, constraints)                |
| Extensions                     | ✅ Supported (methods, getters, setters, operators)                            |
| Async/await                    | ✅ Supported (async functions, await, Futures)                                 |
| Pattern matching               | ✅ Supported (switch/case, if-case, destructuring, list/map/record patterns)   |
| Collections (List, Map, Set)   | ✅ Supported (literals, spread, if/for, nested, null-aware, records)           |
| Top-level functions            | ✅ Supported (named, anonymous, closures, nested)                              |
| Getters/Setters                | ✅ Supported (instance, static, extension, bridge)                             |
| Static members                 | ✅ Supported (fields, methods, getters/setters, bridge)                        |
| Switch/case                    | ✅ Supported (classic, pattern, default, fallthrough, exhaustive checks)       |
| Try/catch/finally              | ✅ Supported (multiple catch, on/type, rethrow, stacktrace)                    |
| Imports                        | ✅ Supported (URIs, show/hide clauses for libraries defined in `sources`)      |
| Generics                       | ✅ Full support (generic classes/functions, type constraints, runtime validation) |
| Operator overloading           | ✅ Full support                    |
| FFI                            | 🚫 Not supported                                                               |
| Isolates                       | ✅ Full support                                                               |
| Reflection/Mirrors             | 🚫 Not supported                                                               |
| Records                        | ✅ Supported (positional, named, pattern matching)                             |
| String interpolation           | ✅ Supported                                                                   |
| Cascade notation (`..`)        | ✅ Supported                                                                   |
| Null safety                    | ✅ Supported (null-aware ops, checks, patterns)                                |
| Type tests (`is`, `as`)        | ✅ Supported                                                                   |
| Exception handling             | ✅ Supported (throw, rethrow, custom errors)                                   |

See the [documentation](#documentation) for details and limitations.

---

## Limitations

- Operator overloading is partially supported (via extensions, not via class operator methods).
- Some advanced Dart features (FFI, mirrors) are not available.
- The interpreter is not a full Dart VM: some language features may behave differently.

---

## Documentation

- [API Reference](https://pub.dev/documentation/d4rt/latest/)
- [Bridging Guide](BRIDGING_GUIDE.md)
- [Supported Features](#supported-features)
- [Examples](example/)

---

## Contributing

Contributions are welcome!  
Feel free to open issues, suggest features, or submit pull requests.

---

## License

MIT License. See [LICENSE](LICENSE).

---

## About the Name

**d4rt** is a play on the word "dart", using "4" as a stylized "A".  
It is pronounced exactly like "dart". 