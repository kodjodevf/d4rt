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

class IoStdlib {
  static void register(Environment environment) {
    // Register FileSystemEntity classes (converted)
    environment.defineBridge(FileSystemEntityIo.definition);
    environment.defineBridge(FileStatIo.definition);
    environment.defineBridge(FileSystemEntityTypeIo.definition);
    environment.defineBridge(FileSystemEventIo.definition);
    environment.defineBridge(DirectoryIo.definition);
    environment.defineBridge(FileIo.definition);

    // Register Stdio classes (converted)
    IoStdioStdlib.register(environment);

    // Register HTTP classes (converted)
    IoHttpStdlib.register(environment);
  }
}
