## 0.2.4
- feat: Enhance enum handling with improved equality checks and add comprehensive switch statement tests
## 0.2.3
- **feat: Dart 3.0+ Pattern Matching, Relational/Logical Patterns, `for-in` & `if-case` Collection Elements**
  - Added support for `RelationalPattern` (`> 0`, `< 100`, `>= 18`, `<= 65`, `== 'admin'`, `!= null`) in switch expressions, switch statements, and `if-case`.
  - Added support for `LogicalAndPattern` (`>= 0 && <= 100`) with cumulative variable binding.
  - Added support for `ParenthesizedPattern` (`(pattern)`), `NullCheckPattern` (`pattern?`), `NullAssertPattern` (`pattern!`), and `CastPattern` (`pattern as Type`).
  - Added `for-in` pattern destructuring loops (`for (final (x, y) in points)` and `await for (final (x, y) in stream)`).
  - Added `for-in` pattern elements (`[for (final (k, v) in map.entries) '$k=$v']`) and `if-case` elements (`[if (user case (var name, var age) when age >= 18) name]`) in List, Set, and Map collection literals.
  - Added guard clauses (`when` clause) in `SwitchPatternCase` for switch statements.
- **feat: Closures, Capability & Stream Subtyping (`dart:isolate`)**
  - Added subtyping bridges across `Capability`, `SendPort` (`sp is Capability`), `ReceivePort` (`rp is Stream`), `Isolate`, `RawReceivePort`, `RemoteError` (`err is Error`), and `TransferableTypedData`.
  - Added support for all callable and closure types (`InterpretedFunction`, `Callable`, native `Function`) in `Isolate.run`, `ReceivePort.listen`, and `RawReceivePort` handlers.
  - Reordered isolate bridge definitions ensuring `SendPort` and `ReceivePort` take precedence over abstract `Capability`.
- **feat: `Flow` Bridge, `ServiceProtocolInfo`, Service Constants & Closures (`dart:developer`)**
  - Added `FlowDeveloper` bridge with `Flow.begin()`, `Flow.step(id)`, `Flow.end(id)`, and `flow.id`.
  - Added `ServiceProtocolInfoDeveloper` bridge exposing `serverUri` and `serverWebSocketUri`.
  - Added `staticGetters` for standard error code constants on `ServiceExtensionResponse` (`invalidParams`, `extensionError`, `extensionErrorMin`, `extensionErrorMax`).
  - Added support for all callable and closure types (`InterpretedFunction`, `Callable`, native `Function`) in `Timeline.timeSync` and `registerExtension`.
- **feat: `HtmlEscapeMode` Static Getters, `JsonUnsupportedObjectError` & Codec Subtyping (`dart:convert`)**
  - Added `staticGetters` on `HtmlEscapeMode` (`attribute`, `element`, `sqAttribute`, `unknown`) and instance mode properties (`escapeQuot`, `escapeApos`, `escapeLtGt`, `escapeSlash`).
  - Added `JsonUnsupportedObjectErrorConvert` bridge with `cause`, `partialResult`, `unsupportedObject`, and `isSubtypeOfFunc`.
  - Added robust closure and `BridgedInstance` unwrapping for `toEncodable` in `JsonCodec.encode`, `JsonEncoder.convert`, and global `jsonEncode`.
  - Added subtyping bridges across `Codec`, `Converter`, `Encoding`, `JsonCodec`, `Utf8Codec`, `AsciiCodec`, `Latin1Codec`, `Base64Codec`, `HtmlEscape`, and `LineSplitter`.
- **feat: `Link` Bridge, `HttpStatus` & `FileSystemEntity` Subtyping (`dart:io`)**
  - Added `LinkIo` bridge in `dart:io` supporting symbolic link management (`create`, `target`, `update`, `resolveSymbolicLinks`, `rename`, `delete`, `exists`, `stat`) with permission checks.
  - Added `HttpStatusIo` bridge in `dart:io` containing all standard HTTP status code constants (`HttpStatus.ok`, `HttpStatus.notFound`, etc.).
  - Added unified `FileSystemEntity` subtyping and optimized bridge lookup ordering for `File`, `Directory`, and `Link`.
- **feat: `dart:async` Reliability, `unawaited` & Subtyping**
  - Fixed argument resolution in `Timer.run` callback invocation.
  - Added global top-level function `unawaited(Future<void> future)` in `dart:async`.
  - Added `isSubtypeOfFunc` subtyping bridges on `Future`, `Stream`, `StreamSubscription`, `StreamTransformer`, `StreamIterator`, `StreamController`, `Timer`, and `TimeoutException`.
- **feat: `HasNextIterator`, Queue `.of()` Constructors & Subtyping (`dart:collection`)**
  - Added `HasNextIteratorCollection` bridge supporting `HasNextIterator(iterator)`, `hasNext` getter, and `next()` method.
  - Added `.of(elements)` factory constructors to `QueueCollection`, `ListQueueCollection`, and `DoubleLinkedQueueCollection`.
  - Added `DoubleLinkedQueueEntryCollection` bridge with `append`, `prepend`, `remove`, `previousEntry`, and `nextEntry`.
  - Added `isSubtypeOfFunc` subtyping bridges across `Queue`, `ListQueue`, `DoubleLinkedQueue`, `HashMap`, `LinkedHashMap`, `SplayTreeMap`, `HashSet`, `LinkedHashSet`, `SplayTreeSet`, `LinkedList`, `LinkedListEntry`, `UnmodifiableListView`, `UnmodifiableMapView`, and `UnmodifiableSetView`.
  - Added `LinkedHashSetCollection` bridge in `dart:collection` with `LinkedHashSet()`, `LinkedHashSet.from()`, `LinkedHashSet.of()`, and `LinkedHashSet.identity()`.
  - Added built-in `Set` type check support in `visitIsExpression` for both native and bridged sets (`set is Set`).
- **feat: Geometry & Operators Bridge (`Rectangle.fromPoints`, `Point` operators in `dart:math`)**
  - Added `Rectangle.fromPoints(Point a, Point b)` in `dart:math`.
  - Added binary operator dispatch (`+`, `-`, `*`, etc.) for bridged instances in expressions.
  - Added robust unwrapping and `isSubtypeOfFunc` on `Point`, `Rectangle`, and `MutableRectangle`.
- **feat: `TypedData` Supertype Bridge & Polymorphism (`dart:typed_data`)**
  - Added `TypedDataBaseTypedData` bridge in `dart:typed_data` enabling `data is TypedData` type checks and direct property access (`buffer`, `lengthInBytes`, `offsetInBytes`, `elementSizeInBytes`).
  - Improved `isSubtypeOf` resolution across all bridged classes when unwrapping `BridgedInstance` values.
- **feat: Advanced JSON Support & Automatic `toJson()` Serialization (`dart:convert`)**
  - Added `JsonEncoder.withIndent(indent, [toEncodable])` for pretty-printing JSON in interpreted code.
  - Added automatic serialization of interpreted class instances defining `toJson()` in `jsonEncode(...)` and `JsonEncoder`.
  - Added full closure compatibility for `toEncodable` and `reviver` callbacks.
- **feat: Record Supertype Bridge (`Record`)**
  - Added `RecordCore` bridge in `dart:core` allowing `rec is Record` type checks and record inspection.
- **feat: Collection View Bridge (`MapView`)**
  - Added `MapViewCollection` in `dart:collection` for wrapping and delegating map operations.
- **feat: Hashing Utilities (`Object.hash`, `Object.hashAll`, `Object.hashAllUnordered`)**
  - Added modern Dart hashing utilities in `dart:core` for custom object hashing and composite key creation.
- **feat: Microtask Scheduling & Zones (`scheduleMicrotask` & `Zone`)**
  - Added `scheduleMicrotask(void Function() callback)` in `dart:async`.
  - Added full bridge for `Zone` (`Zone.current`, `Zone.root`, `zone.run(...)`, `zone.runGuarded(...)`, `zone.inSameErrorZone(...)`, `zone[key]`).
- **feat: Enhanced CLI Tooling (`bin/d4rt.dart`)**
  - Added `--eval` / `-e "<code>"` flag to evaluate inline Dart scripts directly from the CLI.
  - Added `--introspection` / `-i <file>` and `--json-introspection <file>` to inspect declaration metadata via CLI.
- **feat: Output Redirection & Print Interception (`onPrint`)**
  - Added `onPrint: void Function(String)?` callback to `D4rt(...)`, `d4rt.execute(...)`, `d4rt.eval(...)`, and `d4rt.executeCompiled(...)` for capturing/redirecting script output.
- **feat: `dart:async` Zones & Error Boundaries (`runZoned` & `runZonedGuarded`)**
  - Added global `runZoned` and `runZonedGuarded` in `dart:async` standard library.
- **feat: Introspection JSON Serialization (`toMap` & `toJson`)**
  - Added `toMap()` and `toJson()` to `IntrospectionResult`, `DeclarationInfo`, `FunctionInfo`, `ClassInfo`, `EnumInfo`, `VariableInfo`, and `ExtensionInfo`.
- **feat: Extension Type Support**
  - Full support for Dart extension types, representation fields, custom constructors, methods, and getters/setters.
- **feat: Precompiled Scripts & AST Caching (`PrecompiledScript`)**
  - Added `d4rt.compile(source: ...)` to pre-parse and validate scripts without immediate execution.
  - Added `d4rt.executeCompiled(script, ...)` for high-performance repeated execution.
  - Added automatic AST caching support (`D4rt(enableAstCache: true)`).
- **feat: Sandbox Execution Limits & Timeout Protection**
  - Added `timeout: Duration?` and `maxSteps: int?` parameters to `execute()`, `eval()`, and `executeCompiled()`.
  - Added `ExecutionTimeoutException` and `ExecutionLimitException` to guard against infinite loops and CPU runaway.
- **feat: Interactive CLI & REPL Tool**
  - Added command-line executable (`bin/d4rt.dart` & `bin/interpreter.dart`) to run Dart scripts or start an interactive REPL (`dart run d4rt`).
  - Interactive REPL features multiline statement input, environment persistence, and commands (`:help`, `:clear`, `:exit`).
- **feat: Standard Library Enhancements & Completeness**
  - Added `dart:developer` library with `log(...)`, `debugger(...)`, `inspect(...)`, `postEvent(...)`, `registerExtension(...)`, `Timeline`, `TimelineTask`, `UserTag`, `Service`, and `ServiceExtensionResponse`.
  - Added `Expando`, `RuneIterator`, `WeakReference`, `Finalizer`, and `Stopwatch` in `dart:core`.
  - Extended `StackTrace` (`StackTrace.fromString(...)`, `StackTrace.current`, `StackTrace.empty`) in `dart:core`.
  - Added `DateTime.copyWith` in `dart:core`.
  - Added `BytesBuilder`, `Int64List`, `Uint64List`, `Int8List`, `Uint8ClampedList`, `Uint16List`, `Int32List`, `Uint32List`, and `Float64List` in `dart:typed_data`.
  - Added `Completer.sync()` in `dart:async`.
  - Added `LineSplitter.split(...)` and hardened `base64Encode`/`base64UrlEncode` in `dart:convert`.
  - Added `SplayTreeSet`, `DoubleLinkedQueue`, `UnmodifiableMapView`, and `UnmodifiableSetView` in `dart:collection`.
  - Added `MutableRectangle` in `dart:math`.
  - Hardened `Uri` constructors and methods against dynamic collection arguments.
  - Enhanced universal runtime type subtyping (`BridgedClass.isSubtypeOf`).
- **fix: Dart Web Platform Compatibility**
  - Fixed runtime type resolution for `int` return types on Dart Web (#6).
  - Fixed property access and method calls on native JS collections like `JSArray` from `String.split()` (#8).

## 0.2.2
- **feat: Extension Type Support**
- **New additional features & Bug fixes**
## 0.2.1
- **feat: Enum Support Enhancement**
  - Add native-like `values` access for both interpreted and bridged enums.
- **fix: Bridge Generator Improvements**
  - Fix generic collection extraction syntax (remove extra spaces/invalid tags).
  - Prevent instantiation of abstract classes in generated bridges.
  - Remove redundant `?? null` operators from generated code.
  - Fix aggressive type inference for common parameter names like `key`.

## 0.2.0
- **misc**:
  - Update analyzer to version 10.0.2.
  - Refactor deprecated fields.
  - Downgrade analyzer to version to 8.4.0
- **feat: Bridge Code Generation Support**
- **feat: Library Tracking & Deduplication** - Canonical source tracking for bridge deduplication

## 0.1.9
- **feat:positionalArgs and namedArgs** - Pass arguments directly to functions via execute()
  - Add `positionalArgs` parameter to D4rt.execute() for passing positional arguments
  - Add `namedArgs` parameter to D4rt.execute() for passing named arguments
  - Support complex data types (List, Map, nested structures) as arguments
  - Support function callbacks and async functions as arguments
  - Add 33 comprehensive test cases covering all argument passing patterns
  - Add parameter introspection methods: `positionalParameterNames` and `namedParameterNames` getters

- **feat: Introspection API** - Analyze code structure and get metadata at runtime
  - Add `analyze()` method to D4rt for code analysis without execution
  - Create IntrospectionResult with metadata about functions, classes, enums, variables, and extensions
  - Extract function signatures including parameter names, types, and default values
  - Extract class information: inheritance, mixins, interfaces, constructors, methods
  - Extract enum values and variants
  - Extract variable declarations and initializers
  - Extract extension definitions and extended types
  - Use AST-based analysis for accurate metadata extraction
  - Add 38 comprehensive test cases covering all declaration types and complex scenarios

- **feat: eval() method** - Dynamically execute code with current execution state
  - Add `eval()` method to D4rt for dynamic code execution
  - Preserve execution environment across eval calls
  - Support access to previously defined variables and functions
  - Support complex expressions and statements in eval
  - Support async/await in eval expressions
  - Add 39 comprehensive test cases covering expression evaluation and statement execution

- **fix: Environment import handling** - Tolerate duplicate imports with identical values
  - Allow re-importing the same symbol if the value is identical (same reference)
  - Use `identical()` comparison for duplicate detection
  - Support imports via multiple paths without conflict errors

## 0.1.8
- fix: security sandboxing with permission checks for file, process, and network operations; add platform access control

## 0.1.7
- **feat: Security sandboxing system** - Comprehensive permission-based security system to restrict dangerous operations
  - Implement modular permission system with `FilesystemPermission`, `NetworkPermission`, `ProcessRunPermission`, `IsolatePermission`
  - Block access to dangerous modules (`dart:io`, `dart:isolate`) by default unless explicitly granted
  - Add `d4rt.grant()`, `d4rt.revoke()`, `d4rt.hasPermission()` methods for permission management
  - Integrate permission checking into module loading and import directives
  - Support fine-grained permissions (specific paths, commands, network hosts)
  - Add comprehensive security tests to prevent malicious code execution
  - Enable safe execution environment for untrusted code

## 0.1.6
- fix: Nested for-in loops in async contexts now work correctly
- fix: Async nested for-in loops with await for streams works
- feat: enhance async execution state to support nested await-for loops and improve iterator management; add comprehensive tests for complex async scenarios
- **feat: Compound super operators** - Support for compound assignment operators on super properties (+=, -=, *=, /=, ~/=, %=, &=, |=, ^=, <<=, >>=, >>>=)
  - Implement proper lookup and evaluation of super properties in compound assignments
  - Support for both interpreted and bridged superclass properties
  - Add 6 comprehensive test cases covering all operator types and nested inheritance
- **feat: Bridged static methods as values** - Bridged static methods can now be treated as first-class function values
  - Support for accessing bridged static methods as callable values (e.g., `int.parse`)
  - Enable passing bridged static methods to higher-order functions
  - Store bridged static methods in collections and variables
  - Add 5 test cases for static method value usage patterns
- **feat: Complex generic type checking** - Enhanced runtime type checking for generic collections with type parameters
  - Support `is` operator with parameterized types (List<int>, Map<String, int>, etc.)
  - Runtime validation of generic type constraints
  - Proper handling of nested generic types and null safety
  - Add 10 comprehensive test cases for various generic type checking scenarios
- **feat: Complex await assignments** - Advanced await expression support in various contexts
  - Support await in conditional expressions (ternary operator)
  - Support await in list/map literals and collection operations
  - Support await in compound assignments and complex expressions
  - Support await in constructor arguments and method chains
  - Add 10 test cases covering complex async assignment patterns
- **feat: Stream transformers** - Complete implementation of StreamTransformer and stream manipulation
  - Implement `StreamTransformer.fromHandlers` with handleData, handleError, handleDone
  - Support stream transformation with custom logic
  - Implement bidirectional stream transformers
  - Support stream event handling and error propagation
  - Add 10 comprehensive test cases for stream transformation patterns
- **feat: Const expressions complexes** - Enhanced support for const expressions in various contexts
  - Support const List and Map literals with type parameters
  - Support const expressions in field initializers and default parameters
  - Support nested const collections and complex const expressions
  - Proper compile-time evaluation of const expressions
  - Add 15 test cases covering const expression usage patterns
- **feat: Feature #7 - Enhanced enums with mixins** - Enums can now use mixins to add functionality
  - Support `enum Name with Mixin` syntax
  - Mixins can add methods, getters, and properties to enum values
  - Support multiple mixins on a single enum
  - Full integration with enum values (index, name, toString)
  - Add 15 comprehensive test cases for enum-mixin combinations
- **feat: Extensions statiques** - Extensions can now declare static members (methods, getters, setters, fields)
  - Implement static member storage in `InterpretedExtension` class
  - Add static member access via `Extension.member` syntax
  - Support static method calls, property access, and assignments
  - Add support for prefix/postfix increment/decrement operators on static extension fields
  - Add 15 comprehensive test cases covering all static extension member types
- **feat: Enhance compound super assignments for bridged classes** - Full support for compound assignments on properties inherited from bridged superclasses
  - Fix `visitAssignmentExpression` to handle bridged superclass getters/setters in compound `super` assignments
  - Fix `InterpretedInstance.get()` to properly traverse bridged superclass hierarchy at each inheritance level
  - Fix `InterpretedInstance.set()` to properly handle bridged superclass setters at each inheritance level
  - Support nested inheritance chains (Interpreted → Interpreted → Bridged)
  - Add 5 comprehensive test cases for bridged super compound assignments
- **Total test count: 1269 tests passing** - All 8 planned features fully implemented with comprehensive test coverage

## 0.1.5
- feat: implement handling of factory constructors in InterpreterVisitor; add comprehensive tests for factory constructor behavior
- feat: enhance async execution state and interpreter visitor to support break/continue handling; add comprehensive tests for nested async loops
- feat: enhance async execution state and interpreter visitor to support async* generators; add comprehensive tests for generator behavior and control flow

## 0.1.4
- feat: add methods to find and retrieve bridged enum values in Environment and InterpreterVisitor; enhance handling of bridged enums in property access and binary expressions
- feat: enhance documentation across multiple files; add examples and clarify class functionalities in D4rt interpreter
## 0.1.3
- Implement complete `late` variable support with lazy initialization and proper error handling
- Add comprehensive late variable test coverage (33 test cases) including static fields, instance fields, final constraints, and error conditions
- Add LateVariable class with proper uninitialized access detection and assignment validation
- Enhance interpreter visitor to handle late variables in all contexts (local, static, instance)
- Fix nullable variable handling in interpreted class instances
- Add ComparableCore bridge to core standard library for better type comparison support
- Update documentation and project description for better clarity

## 0.1.2+1
- update project description in pubspec.yaml
- docs: minor updates to documentation in README.md

## 0.1.2
- Implement complete Isolate API with Capability, IsolateSpawnException, Isolate, SendPort, ReceivePort, RawReceivePort, RemoteError, and TransferableTypedData classes
- Add comprehensive isolate communication and message passing support
- Enhance async capabilities with Timer functionality and improved error handling
- Add UnawaitedAsync and TimeoutExceptionAsync classes for better async error management
- Implement additional HTTP methods and error handling in HttpClientIo
- Add toString method to DirectoryIo for better debugging
- Enhance FileSystemEntity with parentOf method and FileStat improvements
- Add FileSystemEvent static getters and methods
- Implement RawSocket and additional Socket classes for network programming
- Enhance Stream and Socket classes with additional utility methods
- Add IOSink, ProcessIo, and StringSink classes for improved I/O operations
- Implement Comparable interface for better type comparison support
- Add comprehensive test coverage for isolate, socket, and I/O functionality
- Update core typed data classes (Uint8List, Int16List, Float32List) with enhanced functionality
- Add list extension utilities for better collection manipulation

## 0.1.1
- Implement await for-in loop support for streams in interpreter
- Enhance pattern matching with support for rest elements in lists and maps
- Add support for await expressions in function and constructor arguments
- BREAKING CHANGE: BridgedClassDefinition has been removed and replaced with BridgedClass

## 0.1.0
- Added runtime checks for generic type constraints.
- Added support for compound bitwise assignment operators (&=, |=, etc.).
- Introduced Int16List and Float32List in typed_data.

## 0.0.9
- full support (generic classes/functions, type constraints, runtime validation)
- use BridgedClassDefinition for all Stdlib
- Support adjacent string literals in interpreter
- add operators support for InterpretedClass
- more features

## 0.0.8
- expose visitor getter
- add support for bridged mixins
- enhance async execution state with nested loop support 

## 0.0.7
- fix: support null safety

## 0.0.6
- Update docs

## 0.0.5
- minor fix

## 0.0.4
- Add 'import/export' directive support, support for 'show' and 'hide' combinators 
- Add some dart:collection & dart:typed_data
- Support for ParenthesizedExpression property access in simpleIdentifier in async state

## 0.0.3
- Fix infinite loop when using rethrow in try catch in async state

## 0.0.2
- Support web
- Fix return nativeValue for BridgedEnumValue to BridgedInstance argument

## 0.0.1

- Initial version.
