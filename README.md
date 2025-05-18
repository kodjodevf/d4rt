# d4rt

**d4rt** (pronounced "dart") is an interpreter and runtime for the Dart language, written in Dart.  
It allows you to execute Dart code dynamically, bridge native classes, and build advanced scripting or plugin systems in your Dart/Flutter applications.

---

## Features

- **Dart interpreter**: Run Dart code dynamically at runtime.
- **Bridging system**: Expose your own Dart/Flutter classes, enums, and methods to interpreted code.
- **Async/await support**: Handle asynchronous code and Futures.
- **Class, enum, and extension support**: Use most Dart language features, including classes, inheritance, mixins, enums, and extensions.
- **Pattern matching**: Support for Dart's pattern matching in switch/case and assignments.
- **Custom logging**: Integrated, configurable logger for debugging interpreted code.
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

## Bridging Native Classes & Enums

You can expose your own Dart classes and enums to the interpreter using the bridge system. Here are minimal examples:

### Bridge a Dart Class (Minimal)

```dart
import 'package:d4rt/d4rt.dart';

class MyClass {
  int value;
  MyClass(this.value);
  int doubleValue() => value * 2;
}

final myClassBridge = BridgedClassDefinition(
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

### Bridge a Dart Enum (Minimal)

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
| Generics                       | ⚠️ Partial (basic generic classes/functions, no runtime type checks)           |
| Operator overloading           | ⚠️ Partial (via extensions, not via class operator methods)                    |
| FFI                            | 🚫 Not supported                                                               |
| Isolates                       | 🚫 Not supported                                                               |
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

- Generics and operator overloading are partially supported.
- Some advanced Dart features (isolates, FFI, mirrors) are not available.
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