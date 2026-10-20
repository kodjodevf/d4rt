import 'package:d4rt/d4rt.dart';

/// Requires [DangerousPermission.developerTools] before exposing VM-service
/// debugging, inspection and extension capabilities.
void checkDeveloperToolsPermission(InterpreterVisitor visitor) {
  final d4rt = visitor.moduleLoader.d4rt;
  if (d4rt == null) return;

  if (!d4rt.checkPermission({
    'type': 'dangerous',
    'operation': 'developer tools',
  })) {
    throw RuntimeError(
      'Access to dart:developer requires DangerousPermission.developerTools. '
      'Grant it explicitly to allow developer and VM-service APIs.',
    );
  }
}
