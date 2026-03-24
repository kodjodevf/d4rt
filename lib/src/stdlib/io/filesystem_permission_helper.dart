import 'dart:io';

import 'package:d4rt/d4rt.dart';

void checkFilesystemReadPermission(InterpreterVisitor visitor, String path,
    {String operation = 'read'}) {
  _checkFilesystemPermission(visitor, path,
      operation: operation, read: true, write: false, execute: false);
}

void checkFilesystemWritePermission(InterpreterVisitor visitor, String path,
    {String operation = 'write'}) {
  _checkFilesystemPermission(visitor, path,
      operation: operation, read: false, write: true, execute: false);
}

void checkFilesystemExecutePermission(InterpreterVisitor visitor, String path,
    {String operation = 'execute'}) {
  _checkFilesystemPermission(visitor, path,
      operation: operation, read: false, write: false, execute: true);
}

void _checkFilesystemPermission(
  InterpreterVisitor visitor,
  String path, {
  required String operation,
  required bool read,
  required bool write,
  required bool execute,
}) {
  final d4rt = visitor.moduleLoader.d4rt;
  if (d4rt == null) return;

  final normalizedPath = File(path).absolute.path;
  final allowed = d4rt.checkPermission({
    'type': 'filesystem',
    'path': normalizedPath,
    'read': read,
    'write': write,
    'execute': execute,
  });

  if (allowed) return;

  throw RuntimeError('Filesystem permission denied for $operation on "$path". '
      'Grant an appropriate FilesystemPermission for this path.');
}
