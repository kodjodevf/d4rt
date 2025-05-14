import 'package:d4rt/d4rt.dart';
import 'package:d4rt/src/stdlib/core/double.dart';
import 'package:d4rt/src/stdlib/core/exceptions.dart';
import 'package:d4rt/src/stdlib/core/int.dart';
import 'package:d4rt/src/stdlib/core/iterable.dart';
import 'package:d4rt/src/stdlib/core/list.dart';
import 'package:d4rt/src/stdlib/core/map.dart';
import 'package:d4rt/src/stdlib/core/num.dart';
import 'package:d4rt/src/stdlib/core/patern.dart';
import 'package:d4rt/src/stdlib/core/set.dart';
import 'package:d4rt/src/stdlib/core/sink.dart';
import 'package:d4rt/src/stdlib/core/string.dart';
import 'package:d4rt/src/stdlib/core/string_buffer.dart';
import 'package:d4rt/src/stdlib/core/string_sink.dart';
import 'package:d4rt/src/stdlib/core/bigint.dart';
import 'package:d4rt/src/stdlib/core/bool.dart';
import 'package:d4rt/src/stdlib/core/iterator.dart';
import 'package:d4rt/src/stdlib/core/date_time.dart';
import 'package:d4rt/src/stdlib/core/duration.dart';
import 'package:d4rt/src/stdlib/core/uri.dart';
import 'package:d4rt/src/stdlib/core/stack_trace.dart';
import 'package:d4rt/src/stdlib/core/regexp.dart';
import 'package:d4rt/src/stdlib/core/function.dart';

export 'package:d4rt/src/environment.dart';
export 'package:d4rt/src/stdlib/core/double.dart';
export 'package:d4rt/src/stdlib/core/int.dart';
export 'package:d4rt/src/stdlib/core/iterable.dart';
export 'package:d4rt/src/stdlib/core/list.dart';
export 'package:d4rt/src/stdlib/core/map.dart';
export 'package:d4rt/src/stdlib/core/num.dart';
export 'package:d4rt/src/stdlib/core/patern.dart';
export 'package:d4rt/src/stdlib/core/set.dart';
export 'package:d4rt/src/stdlib/core/sink.dart';
export 'package:d4rt/src/stdlib/core/string.dart';
export 'package:d4rt/src/stdlib/core/string_buffer.dart';
export 'package:d4rt/src/stdlib/core/string_sink.dart';
export 'package:d4rt/src/stdlib/core/bigint.dart';
export 'package:d4rt/src/stdlib/core/bool.dart';
export 'package:d4rt/src/stdlib/core/iterator.dart';
export 'package:d4rt/src/stdlib/core/date_time.dart';
export 'package:d4rt/src/stdlib/core/duration.dart';
export 'package:d4rt/src/stdlib/core/uri.dart';
export 'package:d4rt/src/stdlib/core/stack_trace.dart';
export 'package:d4rt/src/stdlib/core/regexp.dart';
export 'package:d4rt/src/stdlib/core/function.dart';
export 'package:d4rt/src/stdlib/core/exceptions.dart';

void registerCoreLibs(Environment environment) {
  DoubleCore().setEnvironment(environment);
  IntCore().setEnvironment(environment);
  IterableCore().setEnvironment(environment);
  ListCore().setEnvironment(environment);
  MapCore().setEnvironment(environment);
  MapEntryCore().setEnvironment(environment);
  NumCore().setEnvironment(environment);
  PatternCore().setEnvironment(environment);
  MatchCore().setEnvironment(environment);
  SetCore().setEnvironment(environment);
  SinkCore().setEnvironment(environment);
  StringCore().setEnvironment(environment);
  StringBufferCore().setEnvironment(environment);
  StringSinkCore().setEnvironment(environment);
  BigIntCore().setEnvironment(environment);
  BoolCore().setEnvironment(environment);
  IteratorCore().setEnvironment(environment);
  DateTimeCore().setEnvironment(environment);
  DurationCore().setEnvironment(environment);
  UriCore().setEnvironment(environment);
  StackTraceCore().setEnvironment(environment);
  RegExpCore().setEnvironment(environment);
  FunctionCore().setEnvironment(environment);
  FormatExceptionCore().setEnvironment(environment);
  ExceptionCore().setEnvironment(environment);
  environment.define(
      'Object',
      NativeFunction((visitor, arguments, namedArguments, typeArguments) {
        return Object;
      }, arity: 0, name: 'Object'));
  environment.define(
      'Null',
      NativeFunction((visitor, arguments, namedArguments, typeArguments) {
        return Null;
      }, arity: 0, name: 'Null'));
  environment.define(
      'dynamic',
      NativeFunction((visitor, arguments, namedArguments, typeArguments) {
        return dynamic;
      }, arity: 0, name: 'dynamic'));
  environment.define(
      'print',
      NativeFunction((visitor, arguments, namedArguments, typeArguments) {
        print(arguments[0]);
        return null;
      }, arity: 1, name: 'print'));
}
