import 'package:path/path.dart' as p;

bool get localFileSystemSupported => false;

Uri resolveBasePathUri(String basePath, Uri uri) {
  final normalizedBasePath = p.normalize(p.absolute(basePath));
  return Uri.directory(normalizedBasePath).resolveUri(uri);
}

Uri canonicalizeFileUri(Uri fileUri) {
  return Uri.file(p.normalize(fileUri.toFilePath()));
}

String absolutePathFromFileUri(Uri fileUri) {
  return p.normalize(fileUri.toFilePath());
}

bool fileUriExistsSync(Uri fileUri) {
  return false;
}

String readFileUriAsStringSync(Uri fileUri) {
  throw UnsupportedError(
      'Filesystem access is not available on this platform.');
}

String normalizeFilesystemPath(String path) {
  return p.normalize(p.absolute(path)).replaceAll('\\', '/');
}

String basePathEntryFilePath(String basePath,
    {String entryFile = 'main.dart'}) {
  return p.normalize(p.absolute(basePath, entryFile));
}

Uri basePathDirectoryUri(String basePath) {
  return Uri.directory(p.normalize(p.absolute(basePath)));
}
