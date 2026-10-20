import 'dart:io';

import 'package:path/path.dart' as p;

bool get localFileSystemSupported => true;

Uri resolveBasePathUri(String basePath, Uri uri) {
  return Directory(basePath).absolute.uri.resolveUri(uri);
}

Uri canonicalizeFileUri(Uri fileUri) {
  final absoluteFile = File.fromUri(fileUri).absolute;
  if (!absoluteFile.existsSync()) {
    return absoluteFile.uri;
  }

  try {
    return File(absoluteFile.resolveSymbolicLinksSync()).absolute.uri;
  } on FileSystemException {
    return absoluteFile.uri;
  }
}

String absolutePathFromFileUri(Uri fileUri) {
  return File.fromUri(fileUri).absolute.path;
}

bool fileUriExistsSync(Uri fileUri) {
  return File.fromUri(fileUri).existsSync();
}

String readFileUriAsStringSync(Uri fileUri) {
  return File.fromUri(fileUri).readAsStringSync();
}

String normalizeFilesystemPath(String path) {
  return p.normalize(p.absolute(path)).replaceAll('\\', '/');
}

/// Resolves symbolic links in [path], including in its existing ancestors.
///
/// A target file may not exist yet (for example before a write). In that case
/// the nearest existing ancestor is resolved and the remaining segments are
/// appended unchanged. This keeps permission checks anchored to the real
/// filesystem location instead of the lexical path supplied by interpreted
/// code.
String canonicalizeFilesystemPath(String path) {
  return _canonicalizeFilesystemPath(
    p.normalize(p.absolute(path)),
    <String>{},
    0,
  );
}

String _canonicalizeFilesystemPath(
  String path,
  Set<String> visitedLinks,
  int depth,
) {
  if (depth > 40) {
    // A symlink chain this deep is either broken or cyclic. Returning the
    // lexical path makes the operation fail naturally instead of escaping.
    return p.normalize(path).replaceAll('\\', '/');
  }

  var current = path;
  final missingSegments = <String>[];
  var currentType = FileSystemEntityType.notFound;

  while (true) {
    currentType = FileSystemEntity.typeSync(current, followLinks: false);
    if (currentType != FileSystemEntityType.notFound) {
      break;
    }

    final parent = p.dirname(current);
    if (parent == current) {
      break;
    }
    missingSegments.add(p.basename(current));
    current = parent;
  }

  String resolved = current;
  try {
    resolved = switch (currentType) {
      FileSystemEntityType.directory => Directory(
        current,
      ).resolveSymbolicLinksSync(),
      FileSystemEntityType.link => Link(current).resolveSymbolicLinksSync(),
      FileSystemEntityType.notFound => current,
      _ => File(current).resolveSymbolicLinksSync(),
    };
  } on FileSystemException {
    if (currentType == FileSystemEntityType.link) {
      // Broken links cannot be resolved by the OS. Resolve their target
      // ourselves so a write through the link cannot escape a scoped path.
      try {
        final target = Link(current).targetSync();
        final targetPath = p.isAbsolute(target)
            ? target
            : p.join(p.dirname(current), target);
        if (visitedLinks.add(current)) {
          resolved = _canonicalizeFilesystemPath(
            p.normalize(targetPath),
            visitedLinks,
            depth + 1,
          );
        }
      } on FileSystemException {
        // Keep the lexical path; the native operation will fail as well.
      }
    }
  }

  for (final segment in missingSegments.reversed) {
    resolved = p.join(resolved, segment);
  }

  return p.normalize(resolved).replaceAll('\\', '/');
}

String basePathEntryFilePath(
  String basePath, {
  String entryFile = 'main.dart',
}) {
  return p.normalize(p.absolute(basePath, entryFile));
}

Uri basePathDirectoryUri(String basePath) {
  return Directory(basePath).absolute.uri;
}
