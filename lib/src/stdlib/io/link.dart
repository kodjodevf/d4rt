import 'dart:io';
import 'dart:typed_data';
import 'package:d4rt/d4rt.dart';
import 'package:path/path.dart' as p;

import 'filesystem_permission_helper.dart';
import 'secure_file_opener.dart';

class LinkIo {
  static BridgedClass get definition => BridgedClass(
    nativeType: Link,
    name: 'Link',
    typeParameterCount: 0,
    isSubtypeOfFunc: (value) => value is Link,
    constructors: {
      '': (visitor, positionalArgs, namedArgs) {
        if (positionalArgs.isEmpty || positionalArgs[0] is! String) {
          throw RuntimeError(
            'Link constructor requires one String argument (path).',
          );
        }
        return Link(positionalArgs[0] as String);
      },
    },
    staticMethods: {
      'fromRawPath': (visitor, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! Uint8List) {
          throw RuntimeError(
            'Link.fromRawPath requires one Uint8List argument.',
          );
        }
        return Link.fromRawPath(positionalArgs[0] as Uint8List);
      },
      'fromUri': (visitor, positionalArgs, namedArgs) {
        if (positionalArgs.length != 1 || positionalArgs[0] is! Uri) {
          throw RuntimeError('Link.fromUri requires one Uri argument.');
        }
        return Link.fromUri(positionalArgs[0] as Uri);
      },
    },
    methods: {
      'exists': (visitor, target, positionalArgs, namedArgs) {
        final link = target as Link;
        checkFilesystemReadPermission(
          visitor,
          link.path,
          operation: 'check link existence',
        );
        return link.exists();
      },
      'existsSync': (visitor, target, positionalArgs, namedArgs) {
        final link = target as Link;
        checkFilesystemReadPermission(
          visitor,
          link.path,
          operation: 'check link existence',
        );
        return link.existsSync();
      },
      'create': (visitor, target, positionalArgs, namedArgs) {
        if (positionalArgs.isEmpty || positionalArgs[0] is! String) {
          throw RuntimeError(
            'Link.create requires target path String argument.',
          );
        }
        final link = target as Link;
        final targetPath = positionalArgs[0] as String;
        final recursive = namedArgs['recursive'] as bool? ?? false;
        final linkTarget = checkFilesystemNamespaceWritePermission(
          visitor,
          link.path,
          operation: 'create link',
        );
        _checkLinkTargetPermission(
          visitor,
          link,
          targetPath,
          operation: 'create link target',
        );
        if (SecureFileOpener.isSupported) {
          SecureFileOpener.createLink(
            p.join(linkTarget.parent, linkTarget.name),
            targetPath,
            recursive: recursive,
          );
          return Future<Link>.value(link);
        }
        return link.create(targetPath, recursive: recursive);
      },
      'createSync': (visitor, target, positionalArgs, namedArgs) {
        if (positionalArgs.isEmpty || positionalArgs[0] is! String) {
          throw RuntimeError(
            'Link.createSync requires target path String argument.',
          );
        }
        final link = target as Link;
        final targetPath = positionalArgs[0] as String;
        final recursive = namedArgs['recursive'] as bool? ?? false;
        final linkTarget = checkFilesystemNamespaceWritePermission(
          visitor,
          link.path,
          operation: 'create link',
        );
        _checkLinkTargetPermission(
          visitor,
          link,
          targetPath,
          operation: 'create link target',
        );
        if (SecureFileOpener.isSupported) {
          SecureFileOpener.createLink(
            p.join(linkTarget.parent, linkTarget.name),
            targetPath,
            recursive: recursive,
          );
          return null;
        }
        link.createSync(targetPath, recursive: recursive);
        return null;
      },
      'update': (visitor, target, positionalArgs, namedArgs) {
        if (positionalArgs.isEmpty || positionalArgs[0] is! String) {
          throw RuntimeError(
            'Link.update requires target path String argument.',
          );
        }
        final link = target as Link;
        final targetPath = positionalArgs[0] as String;
        final linkTarget = checkFilesystemNamespaceWritePermission(
          visitor,
          link.path,
          operation: 'update link',
        );
        _checkLinkTargetPermission(
          visitor,
          link,
          targetPath,
          operation: 'update link target',
        );
        if (SecureFileOpener.isSupported) {
          SecureFileOpener.updateLink(
            p.join(linkTarget.parent, linkTarget.name),
            targetPath,
          );
          return Future<Link>.value(link);
        }
        return link.update(targetPath);
      },
      'updateSync': (visitor, target, positionalArgs, namedArgs) {
        if (positionalArgs.isEmpty || positionalArgs[0] is! String) {
          throw RuntimeError(
            'Link.updateSync requires target path String argument.',
          );
        }
        final link = target as Link;
        final targetPath = positionalArgs[0] as String;
        final linkTarget = checkFilesystemNamespaceWritePermission(
          visitor,
          link.path,
          operation: 'update link',
        );
        _checkLinkTargetPermission(
          visitor,
          link,
          targetPath,
          operation: 'update link target',
        );
        if (SecureFileOpener.isSupported) {
          SecureFileOpener.updateLink(
            p.join(linkTarget.parent, linkTarget.name),
            targetPath,
          );
          return null;
        }
        link.updateSync(targetPath);
        return null;
      },
      'target': (visitor, target, positionalArgs, namedArgs) {
        final link = target as Link;
        checkFilesystemReadPermission(
          visitor,
          link.path,
          operation: 'read link target',
        );
        return link.target();
      },
      'targetSync': (visitor, target, positionalArgs, namedArgs) {
        final link = target as Link;
        checkFilesystemReadPermission(
          visitor,
          link.path,
          operation: 'read link target',
        );
        return link.targetSync();
      },
      'resolveSymbolicLinks': (visitor, target, positionalArgs, namedArgs) {
        final link = target as Link;
        checkFilesystemReadPermission(
          visitor,
          link.path,
          operation: 'resolve symbolic links',
        );
        return link.resolveSymbolicLinks();
      },
      'resolveSymbolicLinksSync': (visitor, target, positionalArgs, namedArgs) {
        final link = target as Link;
        checkFilesystemReadPermission(
          visitor,
          link.path,
          operation: 'resolve symbolic links',
        );
        return link.resolveSymbolicLinksSync();
      },
      'rename': (visitor, target, positionalArgs, namedArgs) {
        if (positionalArgs.isEmpty || positionalArgs[0] is! String) {
          throw RuntimeError('Link.rename requires newPath String argument.');
        }
        final link = target as Link;
        final newPath = positionalArgs[0] as String;
        final oldTarget = checkFilesystemNamespaceWritePermission(
          visitor,
          link.path,
          operation: 'rename link',
        );
        final newTarget = checkFilesystemNamespaceWritePermission(
          visitor,
          newPath,
          operation: 'rename link',
        );
        if (SecureFileOpener.isSupported) {
          SecureFileOpener.renamePath(
            p.join(oldTarget.parent, oldTarget.name),
            p.join(newTarget.parent, newTarget.name),
          );
          return Future<Link>.value(Link(newPath));
        }
        return link.rename(newPath);
      },
      'renameSync': (visitor, target, positionalArgs, namedArgs) {
        if (positionalArgs.isEmpty || positionalArgs[0] is! String) {
          throw RuntimeError(
            'Link.renameSync requires newPath String argument.',
          );
        }
        final link = target as Link;
        final newPath = positionalArgs[0] as String;
        final oldTarget = checkFilesystemNamespaceWritePermission(
          visitor,
          link.path,
          operation: 'rename link',
        );
        final newTarget = checkFilesystemNamespaceWritePermission(
          visitor,
          newPath,
          operation: 'rename link',
        );
        if (SecureFileOpener.isSupported) {
          SecureFileOpener.renamePath(
            p.join(oldTarget.parent, oldTarget.name),
            p.join(newTarget.parent, newTarget.name),
          );
          return null;
        }
        return link.renameSync(newPath);
      },
      'delete': (visitor, target, positionalArgs, namedArgs) {
        final link = target as Link;
        final linkTarget = checkFilesystemNamespaceWritePermission(
          visitor,
          link.path,
          operation: 'delete link',
        );
        if (SecureFileOpener.isSupported) {
          SecureFileOpener.deleteLink(
            p.join(linkTarget.parent, linkTarget.name),
          );
          return Future<Link>.value(link);
        }
        return link.delete(recursive: namedArgs['recursive'] as bool? ?? false);
      },
      'deleteSync': (visitor, target, positionalArgs, namedArgs) {
        final link = target as Link;
        final linkTarget = checkFilesystemNamespaceWritePermission(
          visitor,
          link.path,
          operation: 'delete link',
        );
        if (SecureFileOpener.isSupported) {
          SecureFileOpener.deleteLink(
            p.join(linkTarget.parent, linkTarget.name),
          );
          return null;
        }
        link.deleteSync(recursive: namedArgs['recursive'] as bool? ?? false);
        return null;
      },
      'stat': (visitor, target, positionalArgs, namedArgs) {
        final link = target as Link;
        checkFilesystemReadPermission(
          visitor,
          link.path,
          operation: 'stat link',
        );
        return link.stat();
      },
      'statSync': (visitor, target, positionalArgs, namedArgs) {
        final link = target as Link;
        checkFilesystemReadPermission(
          visitor,
          link.path,
          operation: 'stat link',
        );
        return link.statSync();
      },
      'toString': (visitor, target, positionalArgs, namedArgs) {
        return (target as Link).toString();
      },
    },
    getters: {
      'path': (visitor, target) => (target as Link).path,
      'uri': (visitor, target) => (target as Link).uri,
      'parent': (visitor, target) => (target as Link).parent,
      'isAbsolute': (visitor, target) => (target as Link).isAbsolute,
      'absolute': (visitor, target) => (target as Link).absolute,
      'hashCode': (visitor, target) => (target as Link).hashCode,
      'runtimeType': (visitor, target) => (target as Link).runtimeType,
    },
  );
}

/// Prevents a scoped write from planting a symlink that points outside the
/// writable area.
void _checkLinkTargetPermission(
  InterpreterVisitor visitor,
  Link link,
  String targetPath, {
  required String operation,
}) {
  final resolvedTarget = p.isAbsolute(targetPath)
      ? targetPath
      : p.join(p.dirname(link.path), targetPath);
  checkFilesystemWritePermission(visitor, resolvedTarget, operation: operation);
}
