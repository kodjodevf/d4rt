import 'package:d4rt/d4rt.dart';
import 'package:d4rt/src/utils/platform/filesystem.dart';
import 'package:path/path.dart' as p;

/// A canonical parent directory and final entry name for a namespace
/// operation (create, delete or rename).
typedef FilesystemNamespaceTarget = ({String parent, String name});

/// Checks write access to the parent directory of [path] and returns a
/// canonical namespace target.
///
/// Namespace operations act on a directory entry, not on a symlink target.
/// Canonicalizing only the parent keeps the operation descriptor-based while
/// preserving Unix `unlink`/`rename` semantics for symlinks.
FilesystemNamespaceTarget checkFilesystemNamespaceWritePermission(
  InterpreterVisitor visitor,
  String path, {
  String operation = 'write',
}) {
  final absolutePath = p.normalize(p.absolute(path));
  final name = p.basename(absolutePath);
  final parent = canonicalizeFilesystemPath(p.dirname(absolutePath));
  final d4rt = visitor.moduleLoader.d4rt;

  if (d4rt != null) {
    final allowedParent = d4rt.checkPermission({
      'type': 'filesystem',
      'path': parent,
      'read': false,
      'write': true,
      'execute': false,
    });
    final allowedEntry = d4rt.checkPermission({
      'type': 'filesystem',
      'path': canonicalizeFilesystemPath(absolutePath),
      'read': false,
      'write': true,
      'execute': false,
    });
    if (!allowedParent && !allowedEntry) {
      throw RuntimeError(
        'Filesystem permission denied for $operation on "$path". '
        'Grant an appropriate FilesystemPermission for this path.',
      );
    }
  }

  return (parent: parent, name: name);
}

/// Checks read access and returns the canonical path that was authorized.
///
/// Callers that perform a descriptor-based operation should use the returned
/// path instead of the original user-supplied path.
String checkFilesystemReadPermission(
  InterpreterVisitor visitor,
  String path, {
  String operation = 'read',
}) {
  return _checkFilesystemPermission(
    visitor,
    path,
    operation: operation,
    read: true,
    write: false,
    execute: false,
  );
}

/// Checks write access and returns the canonical path that was authorized.
String checkFilesystemWritePermission(
  InterpreterVisitor visitor,
  String path, {
  String operation = 'write',
}) {
  return _checkFilesystemPermission(
    visitor,
    path,
    operation: operation,
    read: false,
    write: true,
    execute: false,
  );
}

/// Checks execute access and returns the canonical path that was authorized.
String checkFilesystemExecutePermission(
  InterpreterVisitor visitor,
  String path, {
  String operation = 'execute',
}) {
  return _checkFilesystemPermission(
    visitor,
    path,
    operation: operation,
    read: false,
    write: false,
    execute: true,
  );
}

String _checkFilesystemPermission(
  InterpreterVisitor visitor,
  String path, {
  required String operation,
  required bool read,
  required bool write,
  required bool execute,
}) {
  final normalizedPath = canonicalizeFilesystemPath(path);
  final d4rt = visitor.moduleLoader.d4rt;
  if (d4rt == null) return normalizedPath;

  final allowed = d4rt.checkPermission({
    'type': 'filesystem',
    'path': normalizedPath,
    'read': read,
    'write': write,
    'execute': execute,
  });

  if (allowed) return normalizedPath;

  throw RuntimeError(
    'Filesystem permission denied for $operation on "$path". '
    'Grant an appropriate FilesystemPermission for this path.',
  );
}
