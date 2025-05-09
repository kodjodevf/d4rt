import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/stdlib/io/directory.dart';
import 'package:d4rt/src/stdlib/io/file_system_entity.dart';
import 'package:d4rt/src/stdlib/io/file.dart';
import 'package:d4rt/src/stdlib/io/stdio.dart';
import 'package:d4rt/src/stdlib/io/http.dart';

export 'package:d4rt/src/environment.dart';
export 'package:d4rt/src/stdlib/io/directory.dart';
export 'package:d4rt/src/stdlib/io/file_system_entity.dart';
export 'package:d4rt/src/stdlib/io/file.dart';
export 'package:d4rt/src/stdlib/io/stdio.dart';
export 'package:d4rt/src/stdlib/io/http.dart';

void registerIoLibs(Environment environment) {
  DirectoryIo().setEnvironment(environment);
  FileSystemEntityIo().setEnvironment(environment);
  FileIo().setEnvironment(environment);
  StdinIo().setEnvironment(environment);
  StdoutIo().setEnvironment(environment);
  StdioTypeIo().setEnvironment(environment);
  HttpClientIo().setEnvironment(environment);
  HttpServerIo().setEnvironment(environment);
  HttpClientRequestIo().setEnvironment(environment);
  HttpClientResponseIo().setEnvironment(environment);
}
