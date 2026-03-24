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

String basePathEntryFilePath(String basePath,
    {String entryFile = 'main.dart'}) {
  return p.normalize(p.absolute(basePath, entryFile));
}

Uri basePathDirectoryUri(String basePath) {
  return Directory(basePath).absolute.uri;
}
