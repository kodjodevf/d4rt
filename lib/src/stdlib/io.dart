import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/stdlib/io/directory.dart';
import 'package:d4rt/src/stdlib/io/file_system_entity.dart';
import 'package:d4rt/src/stdlib/io/file.dart';
import 'package:d4rt/src/stdlib/io/stdio.dart';
import 'package:d4rt/src/stdlib/io/http.dart';
import 'package:d4rt/src/stdlib/io/process.dart';
import 'package:d4rt/src/stdlib/io/io_sink.dart';
import 'package:d4rt/src/stdlib/io/string_sink.dart';
import 'package:d4rt/src/stdlib/io/socket.dart';

export 'package:d4rt/src/environment.dart';
export 'package:d4rt/src/stdlib/io/directory.dart';
export 'package:d4rt/src/stdlib/io/file_system_entity.dart';
export 'package:d4rt/src/stdlib/io/file.dart';
export 'package:d4rt/src/stdlib/io/stdio.dart';
export 'package:d4rt/src/stdlib/io/http.dart';
export 'package:d4rt/src/stdlib/io/process.dart';
export 'package:d4rt/src/stdlib/io/io_sink.dart';
export 'package:d4rt/src/stdlib/io/string_sink.dart';
export 'package:d4rt/src/stdlib/io/socket.dart';

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

    // Register Process classes
    environment.defineBridge(ProcessIo.definition);
    environment.defineBridge(ProcessResultIo.definition);
    environment.defineBridge(ProcessSignalIo.definition);
    environment.defineBridge(ProcessStartModeIo.definition);

    // Register IOSink bridge
    environment.defineBridge(IOSinkIo.definition);

    // Register StringSink bridge
    environment.defineBridge(StringSinkIo.definition);

    // Register Socket classes
    environment.defineBridge(SocketIo.definition);
    environment.defineBridge(InternetAddressIo.definition);
    environment.defineBridge(SocketOptionIo.definition);
    environment.defineBridge(InternetAddressTypeIo.definition);
    environment.defineBridge(ServerSocketIo.definition);
  }
}
