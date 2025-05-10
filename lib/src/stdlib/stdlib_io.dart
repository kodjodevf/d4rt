import 'dart:io';
import 'package:d4rt/src/interpreter_visitor.dart';
import 'package:d4rt/src/model/method.dart';
import 'package:d4rt/src/stdlib/io.dart';

class StdlibIo {
  static void registerStdIoLibs(Environment environment) {
    registerIoLibs(environment);
  }

  static MethodInterface? get(
      Object? target,
      String name,
      List<Object?> arguments,
      Map<String, Object?> namedArguments,
      InterpreterVisitor visitor,
      List<Object?> typeArguments,
      {String? error}) {
    MethodInterface? value;
    if (target.isType<HttpClient>()) {
      value = HttpClientIo();
    } else if (target.isType<HttpClientRequest>()) {
      value = HttpClientRequestIo();
    } else if (target.isType<HttpServer>()) {
      value = HttpServerIo();
    } else if (target.isType<HttpClientResponse>()) {
      value = HttpClientResponseIo();
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
    }
    return value;
  }
}

extension _ObjectExtension on Object? {
  bool isType<T>() => this is T || toString() == '$T';
}
