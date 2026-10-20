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
