/// Security and sandboxing system for d4rt interpreter.
///
/// This module provides a comprehensive permission system that allows
/// fine-grained control over what operations interpreted code can perform.
/// By default, potentially dangerous operations are blocked unless explicitly
/// granted through the permission system.
///
/// ## Example usage:
/// ```dart
/// final interpreter = D4rt();
///
/// // Grant filesystem access
/// interpreter.grant(FilesystemPermission.read);
/// interpreter.grant(FilesystemPermission.write('/tmp'));
///
/// // Grant network access
/// interpreter.grant(NetworkPermission.connect('api.example.com'));
///
/// // Grant process execution
/// interpreter.grant(ProcessRunPermission.any);
///
/// // Execute code with restricted permissions
/// final result = interpreter.execute(source: '''
///   // This code can now access filesystem, network, and run processes
///   // within the granted permissions
/// ''');
/// ```
library;

/// Base class for all permissions in the d4rt security system.
abstract class Permission {
  /// The type of permission (e.g., 'filesystem', 'network', 'process').
  String get type;

  /// Human-readable description of what this permission allows.
  String get description;

  /// Checks if this permission allows the given operation.
  bool allows(dynamic operation);

  @override
  String toString() => '$type: $description';
}

/// Filesystem permissions control file and directory operations.
class FilesystemPermission extends Permission {
  @override
  final String type = 'filesystem';

  final String? _path;
  final bool _read;
  final bool _write;
  final bool _execute;

  FilesystemPermission._(this._path, this._read, this._write, this._execute);

  /// Allows reading any file or directory.
  static final FilesystemPermission read =
      FilesystemPermission._(null, true, false, false);

  /// Allows writing to any file or directory.
  static final FilesystemPermission write =
      FilesystemPermission._(null, false, true, false);

  /// Allows executing any file.
  static final FilesystemPermission execute =
      FilesystemPermission._(null, false, false, true);

  /// Allows all filesystem operations on any path.
  static final FilesystemPermission any =
      FilesystemPermission._(null, true, true, true);

  /// Allows reading files/directories under the specified path.
  factory FilesystemPermission.readPath(String path) =>
      FilesystemPermission._(path, true, false, false);

  /// Allows writing files/directories under the specified path.
  factory FilesystemPermission.writePath(String path) =>
      FilesystemPermission._(path, false, true, false);

  /// Allows executing files under the specified path.
  factory FilesystemPermission.executePath(String path) =>
      FilesystemPermission._(path, false, false, true);

  /// Allows all operations under the specified path.
  factory FilesystemPermission.path(String path) =>
      FilesystemPermission._(path, true, true, true);

  @override
  String get description {
    final operations = [];
    if (_read) operations.add('read');
    if (_write) operations.add('write');
    if (_execute) operations.add('execute');

    final ops = operations.join('/');
    final path = _path ?? 'any';
    return '$ops operations on $path';
  }

  @override
  bool allows(dynamic operation) {
    if (operation is! Map<String, dynamic>) return false;

    final opType = operation['type'];
    final opPath = operation['path'];

    if (opType != 'filesystem') return false;

    // Check if the operation is allowed
    final requiredRead = operation['read'] ?? false;
    final requiredWrite = operation['write'] ?? false;
    final requiredExecute = operation['execute'] ?? false;

    if ((requiredRead && !_read) ||
        (requiredWrite && !_write) ||
        (requiredExecute && !_execute)) {
      return false;
    }

    // Check path restrictions
    if (_path != null && opPath != null) {
      // Simple path prefix check (could be made more sophisticated)
      if (!opPath.startsWith(_path)) {
        return false;
      }
    }

    return true;
  }
}

/// Network permissions control network operations.
class NetworkPermission extends Permission {
  @override
  final String type = 'network';

  final String? _host;
  final int? _port;
  final bool _connect;
  final bool _listen;
  final bool _bind;

  NetworkPermission._(
      this._host, this._port, this._connect, this._listen, this._bind);

  /// Allows connecting to any host/port.
  static final NetworkPermission connect =
      NetworkPermission._(null, null, true, false, false);

  /// Allows listening on any port.
  static final NetworkPermission listen =
      NetworkPermission._(null, null, false, true, false);

  /// Allows binding to any address/port.
  static final NetworkPermission bind =
      NetworkPermission._(null, null, false, false, true);

  /// Allows all network operations.
  static final NetworkPermission any =
      NetworkPermission._(null, null, true, true, true);

  /// Allows connecting to the specified host.
  factory NetworkPermission.connectTo(String host) =>
      NetworkPermission._(host, null, true, false, false);

  /// Allows connecting to the specified host and port.
  factory NetworkPermission.connectToPort(String host, int port) =>
      NetworkPermission._(host, port, true, false, false);

  /// Allows listening on the specified port.
  factory NetworkPermission.listenOn(int port) =>
      NetworkPermission._(null, port, false, true, false);

  @override
  String get description {
    final operations = [];
    if (_connect) operations.add('connect');
    if (_listen) operations.add('listen');
    if (_bind) operations.add('bind');

    final ops = operations.join('/');
    if (_host != null && _port != null) {
      return '$ops to $_host:$_port';
    } else if (_host != null) {
      return '$ops to $_host';
    } else if (_port != null) {
      return '$ops on port $_port';
    } else {
      return '$ops on any host/port';
    }
  }

  @override
  bool allows(dynamic operation) {
    if (operation is! Map<String, dynamic>) return false;

    final opType = operation['type'];
    final opHost = operation['host'];
    final opPort = operation['port'];

    if (opType != 'network') return false;

    // Check if the operation is allowed
    final requiredConnect = operation['connect'] ?? false;
    final requiredListen = operation['listen'] ?? false;
    final requiredBind = operation['bind'] ?? false;

    if ((requiredConnect && !_connect) ||
        (requiredListen && !_listen) ||
        (requiredBind && !_bind)) {
      return false;
    }

    // Check host/port restrictions
    if (_host != null && opHost != null && opHost != _host) {
      return false;
    }
    if (_port != null && opPort != null && opPort != _port) {
      return false;
    }

    return true;
  }
}

/// Process permissions control process execution.
class ProcessRunPermission extends Permission {
  @override
  final String type = 'process';

  final String? _command;
  final List<String>? _allowedArgs;

  ProcessRunPermission._(this._command, this._allowedArgs);

  /// Allows running any command with any arguments.
  static final ProcessRunPermission any = ProcessRunPermission._(null, null);

  /// Allows running the specified command.
  factory ProcessRunPermission.command(String command) =>
      ProcessRunPermission._(command, null);

  /// Allows running the specified command with specific arguments.
  factory ProcessRunPermission.commandWithArgs(
          String command, List<String> args) =>
      ProcessRunPermission._(command, args);

  @override
  String get description {
    if (_command == null) {
      return 'run any command';
    } else if (_allowedArgs == null) {
      return 'run command: $_command';
    } else {
      return 'run command: $_command with args: ${_allowedArgs.join(', ')}';
    }
  }

  @override
  bool allows(dynamic operation) {
    if (operation is! Map<String, dynamic>) return false;

    final opType = operation['type'];
    final opCommand = operation['command'];
    final opArgs = operation['args'];

    if (opType != 'process') return false;

    // Check command restrictions
    if (_command != null && opCommand != _command) {
      return false;
    }

    // Check argument restrictions
    if (_allowedArgs != null && opArgs != null) {
      final args = opArgs as List<String>;
      if (args.length != _allowedArgs.length) return false;

      for (int i = 0; i < args.length; i++) {
        if (args[i] != _allowedArgs[i]) return false;
      }
    }

    return true;
  }
}

/// Isolate permissions control isolate creation and communication.
class IsolatePermission extends Permission {
  @override
  final String type = 'isolate';

  final bool _spawn;
  final bool _communicate;

  IsolatePermission._(this._spawn, this._communicate);

  /// Allows spawning new isolates.
  static final IsolatePermission spawn = IsolatePermission._(true, false);

  /// Allows communicating with isolates (send/receive messages).
  static final IsolatePermission communicate = IsolatePermission._(false, true);

  /// Allows all isolate operations.
  static final IsolatePermission any = IsolatePermission._(true, true);

  @override
  String get description {
    final operations = [];
    if (_spawn) operations.add('spawn');
    if (_communicate) operations.add('communicate');
    return '${operations.join('/')} isolates';
  }

  @override
  bool allows(dynamic operation) {
    if (operation is! Map<String, dynamic>) return false;

    final opType = operation['type'];
    if (opType != 'isolate') return false;

    final requiredSpawn = operation['spawn'] ?? false;
    final requiredCommunicate = operation['communicate'] ?? false;

    if ((requiredSpawn && !_spawn) || (requiredCommunicate && !_communicate)) {
      return false;
    }

    return true;
  }
}

/// Dangerous permissions that should be granted with extreme caution.
class DangerousPermission extends Permission {
  @override
  final String type = 'dangerous';

  final String _operation;

  DangerousPermission._(this._operation);

  /// Allows evaluation of arbitrary code strings (eval-like functionality).
  static final DangerousPermission codeEvaluation =
      DangerousPermission._('code evaluation');

  /// Allows loading and executing native plugins/libraries.
  static final DangerousPermission nativePlugins =
      DangerousPermission._('native plugins');

  /// Allows all dangerous operations.
  static final DangerousPermission any =
      DangerousPermission._('any dangerous operation');

  @override
  String get description => 'dangerous operation: $_operation';

  @override
  bool allows(dynamic operation) {
    if (operation is! Map<String, dynamic>) return false;

    final opType = operation['type'];
    final opOperation = operation['operation'];

    if (opType != 'dangerous') return false;

    return _operation == 'any dangerous operation' || opOperation == _operation;
  }
}
