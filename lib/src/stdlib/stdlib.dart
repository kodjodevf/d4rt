import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:d4rt/src/callable.dart';
import 'package:d4rt/src/exceptions.dart';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/stdlib/core.dart';
import 'package:d4rt/src/stdlib/convert.dart';
import 'package:d4rt/src/stdlib/math.dart';
import 'package:d4rt/src/stdlib/io.dart';
import 'package:d4rt/src/stdlib/async.dart';

class Stdlib {
  final Environment environment;

  Stdlib(this.environment);

  void register() {
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
    registerCoreLibs(environment);
    registerMathLibs(environment);
    registerConvertLibs(environment);
    registerAsyncLibs(environment);
    registerIoLibs(environment);
  }

  Object? evalMethod(
      Object? target,
      String name,
      List<Object?> arguments,
      Map<String, Object?> namedArguments,
      InterpreterVisitor visitor,
      List<Object?> typeArguments,
      {String? error}) {
    if (target.isType<NativeFunction>()) {
      bool exist = true;
      try {
        environment.get(name);
      } catch (_) {
        exist = false;
      }
      target = (target as NativeFunction)
          .call(visitor, exist ? arguments : [], exist ? namedArguments : {});
    }
    switch (name) {
      case 'toString':
        return target.toString();
      case 'runtimeType':
        return target.runtimeType;
      case 'hashCode':
        return target.hashCode;
      default:
    }
    if (target == null) {
      return null;
    }
    MethodInterface? value;
    if (target.isType<Completer<dynamic>>()) {
      value = CompleterAsync();
    } else if (target.isType<DateTime>()) {
      value = DateTimeCore();
    } else if (target.isType<Stream<dynamic>>()) {
      value = StreamAsync();
    } else if (target.isType<StreamController<dynamic>>()) {
      value = StreamControllerAsync();
    } else if (target.isType<StreamSink<dynamic>>()) {
      value = StreamSinkAsync();
    } else if (target.isType<StreamSubscription<dynamic>>()) {
      value = StreamSubscriptionAsync();
    } else if (target.isType<HttpClient>()) {
      value = HttpClientIo();
    } else if (target.isType<HttpClientRequest>()) {
      value = HttpClientRequestIo();
    } else if (target.isType<HttpServer>()) {
      value = HttpServerIo();
    } else if (target.isType<HttpClientResponse>()) {
      value = HttpClientResponseIo();
    } else if (target.isType<String>()) {
      value = StringCore();
    } else if (target.isType<List<dynamic>>()) {
      value = ListCore();
    } else if (target.isType<Map<dynamic, dynamic>>()) {
      value = MapCore();
    } else if (target.isType<MapEntry<dynamic, dynamic>>()) {
      value = MapEntryCore();
    } else if (target.isType<Set<dynamic>>()) {
      value = SetCore();
    } else if (target.isType<Iterable<dynamic>>()) {
      value = IterableCore();
    } else if (target.isType<int>()) {
      value = IntCore();
    } else if (target.isType<double>()) {
      value = DoubleCore();
    } else if (target.isType<num>()) {
      value = NumCore();
    } else if (target.isType<BigInt>()) {
      value = BigIntCore();
    } else if (target.isType<bool>()) {
      value = BoolCore();
    } else if (target.isType<Iterator<dynamic>>()) {
      value = IteratorCore();
    } else if (target.isType<Duration>()) {
      value = DurationCore();
    } else if (target.isType<Uri>()) {
      value = UriCore();
    } else if (target.isType<StackTrace>()) {
      value = StackTraceCore();
    } else if (target.isType<RegExp>()) {
      value = RegExpCore();
    } else if (target.isType<Function>()) {
      value = FunctionCore();
    } else if (target.isType<Match>()) {
      value = MatchCore();
    } else if (target.isType<Pattern>()) {
      value = PatternCore();
    } else if (target.isType<StringBuffer>()) {
      value = StringBufferCore();
    } else if (target.isType<StringSink>()) {
      value = StringSinkCore();
    } else if (target.isType<Base64Codec>()) {
      value = Base64CodecConvert();
    } else if (target.isType<Base64Encoder>()) {
      value = Base64EncoderConvert();
    } else if (target.isType<Base64Decoder>()) {
      value = Base64DecoderConvert();
    } else if (target.isType<Sink<dynamic>>()) {
      value = SinkCore();
    } else if (target.isType<Codec<dynamic, dynamic>>()) {
      value = CodecConvert();
    } else if (target.isType<Utf8Codec>()) {
      value = Utf8CodecConvert();
    } else if (target.isType<Utf8Encoder>()) {
      value = Utf8EncoderConvert();
    } else if (target.isType<Utf8Decoder>()) {
      value = Utf8DecoderConvert();
    } else if (target.isType<Encoding>()) {
      value = EncodingConvert();
    } else if (target.isType<AsciiCodec>()) {
      value = AsciiCodecConvert();
    } else if (target.isType<AsciiEncoder>()) {
      value = AsciiEncoderConvert();
    } else if (target.isType<AsciiDecoder>()) {
      value = AsciiDecoderConvert();
    } else if (target.isType<Latin1Codec>()) {
      value = Latin1Convert();
    } else if (target.isType<JsonCodec>()) {
      value = JsonCodecConvert();
    } else if (target.isType<JsonEncoder>()) {
      value = JsonEncoderConvert();
    } else if (target.isType<JsonDecoder>()) {
      value = JsonDecoderConvert();
    } else if (target.isType<StreamTransformer<dynamic, dynamic>>()) {
      value = StreamTransformerAsync();
    } else if (target.isType<Point>()) {
      value = PointMath();
    } else if (target.isType<Random>()) {
      value = RandomMath();
    } else if (target.isType<Directory>()) {
      value = DirectoryIo();
    } else if (target.isType<File>()) {
      value = FileIo();
    } else if (target.isType<FileSystemEntity>()) {
      value = FileSystemEntityIo();
    } else if (target.isType<FileStat>()) {
      value = FileStatIo();
    } else if (target.isType<FileSystemEntityType>()) {
      value = FileSystemEntityTypeIo();
    } else if (target.isType<FileSystemEvent>()) {
      value = FileSystemEventIo();
    } else if (target.isType<Stdin>()) {
      value = StdinIo();
    } else if (target.isType<Stdout>()) {
      value = StdoutIo();
    } else if (target.isType<StdioType>()) {
      value = StdioTypeIo();
    } else if (target.isType<Rectangle>()) {
      value = RectangleMath();
    } else if (target.isType<Future<dynamic>>()) {
      value = FutureAsync();
    } else if (target.isType<FormatException>()) {
      value = FormatExceptionCore();
    } else if (target.isType<Exception>()) {
      value = ExceptionCore();
    }

    if (value != null) {
      return value.evalMethod(
        target,
        name,
        arguments,
        namedArguments,
        visitor,
      );
    }

    throw RuntimeError(error ?? "Method $name not found for target $target");
  }
}

extension _ObjectExtension on Object? {
  bool isType<T>() => this is T || toString() == '$T';
}
