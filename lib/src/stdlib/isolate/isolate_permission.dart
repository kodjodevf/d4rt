import 'package:d4rt/d4rt.dart';

/// Requires [IsolatePermission.spawn] before creating, controlling or
/// terminating an isolate.
void checkIsolateSpawnPermission(InterpreterVisitor visitor) {
  _checkIsolatePermission(visitor, spawn: true);
}

/// Requires [IsolatePermission.communicate] before receiving or sending
/// messages across isolates.
void checkIsolateCommunicationPermission(InterpreterVisitor visitor) {
  _checkIsolatePermission(visitor, communicate: true);
}

/// Requires [IsolatePermission.spawn] and [DangerousPermission.codeEvaluation]
/// before loading native Dart code with `Isolate.spawnUri`.
///
/// Unlike `Isolate.run`, `spawnUri` starts a real Dart isolate from a file or
/// package URI. That code runs outside the interpreter and is not subject to
/// D4rt filesystem or network permissions.
void checkIsolateSpawnUriPermission(InterpreterVisitor visitor) {
  checkIsolateSpawnPermission(visitor);

  final d4rt = visitor.moduleLoader.d4rt;
  if (d4rt == null) return;

  if (!d4rt.checkPermission({
    'type': 'dangerous',
    'operation': 'code evaluation',
  })) {
    throw RuntimeError(
      'Isolate.spawnUri executes native Dart code and requires '
      'DangerousPermission.codeEvaluation. '
      'Grant it explicitly to allow spawning code from a URI.',
    );
  }
}

void _checkIsolatePermission(
  InterpreterVisitor visitor, {
  bool spawn = false,
  bool communicate = false,
}) {
  final d4rt = visitor.moduleLoader.d4rt;
  if (d4rt == null) return;

  final operation = <String, dynamic>{'type': 'isolate'};
  if (spawn) operation['spawn'] = true;
  if (communicate) operation['communicate'] = true;

  if (!d4rt.checkPermission(operation)) {
    final capability = spawn ? 'spawn' : 'communicate';
    throw RuntimeError(
      'Isolate $capability operation denied. '
      'Grant IsolatePermission.$capability or IsolatePermission.any.',
    );
  }
}
