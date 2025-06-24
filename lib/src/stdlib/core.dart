import 'package:d4rt/d4rt.dart';
import 'package:d4rt/src/stdlib/core/double.dart';
import 'package:d4rt/src/stdlib/core/exceptions.dart';
import 'package:d4rt/src/stdlib/core/int.dart';
import 'package:d4rt/src/stdlib/core/iterable.dart';
import 'package:d4rt/src/stdlib/core/list.dart';
import 'package:d4rt/src/stdlib/core/map.dart';
import 'package:d4rt/src/stdlib/core/null.dart';
import 'package:d4rt/src/stdlib/core/num.dart';
import 'package:d4rt/src/stdlib/core/object.dart';
import 'package:d4rt/src/stdlib/core/patern.dart';
import 'package:d4rt/src/stdlib/core/set.dart';
import 'package:d4rt/src/stdlib/core/sink.dart';
import 'package:d4rt/src/stdlib/core/string.dart';
import 'package:d4rt/src/stdlib/core/runes.dart';
import 'package:d4rt/src/stdlib/core/string_buffer.dart';
import 'package:d4rt/src/stdlib/core/string_sink.dart';
import 'package:d4rt/src/stdlib/core/bigint.dart';
import 'package:d4rt/src/stdlib/core/bool.dart';
import 'package:d4rt/src/stdlib/core/iterator.dart';
import 'package:d4rt/src/stdlib/core/date_time.dart';
import 'package:d4rt/src/stdlib/core/duration.dart';
import 'package:d4rt/src/stdlib/core/type.dart';
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
export 'package:d4rt/src/stdlib/core/runes.dart';
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

class CoreStdlib {
  static void register(Environment environment) {
    environment.defineBridge(DoubleCore.definition);
    environment.defineBridge(IntCore.definition);
    environment.defineBridge(IterableCore.definition);
    environment.defineBridge(ListCore.definition);
    environment.defineBridge(MapCore.definition);
    environment.defineBridge(MapEntryCore.definition);
    environment.defineBridge(NumCore.definition);
    environment.defineBridge(PatternCore.definition);
    environment.defineBridge(MatchCore.definition);
    environment.defineBridge(SetCore.definition);
    environment.defineBridge(SinkCore.definition);
    environment.defineBridge(StringCore.definition);
    environment.defineBridge(RunesCore.definition);
    environment.defineBridge(StringBufferCore.definition);
    environment.defineBridge(StringSinkCore.definition);
    environment.defineBridge(BigIntCore.definition);
    environment.defineBridge(BoolCore.definition);
    environment.defineBridge(IteratorCore.definition);
    environment.defineBridge(DateTimeCore.definition);
    environment.defineBridge(DurationCore.definition);
    environment.defineBridge(UriCore.definition);
    environment.defineBridge(StackTraceCore.definition);
    environment.defineBridge(RegExpCore.definition);
    environment.defineBridge(RegExpMatchCore.definition);
    environment.defineBridge(FunctionCore.definition);
    environment.defineBridge(FormatExceptionCore.definition);
    environment.defineBridge(ExceptionCore.definition);
    environment.defineBridge(ObjectCore.definition);
    environment.defineBridge(TypeCore.definition);
    environment.defineBridge(NullCore.definition);
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
}
