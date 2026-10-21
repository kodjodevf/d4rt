import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

typedef _MallocNative = Pointer<Void> Function(IntPtr);
typedef _MallocDart = Pointer<Void> Function(int);
typedef _FreeNative = Void Function(Pointer<Void>);
typedef _FreeDart = void Function(Pointer<Void>);
typedef _OpenNative = Int32 Function(Pointer<Uint8>, Int32);
typedef _OpenDart = int Function(Pointer<Uint8>, int);
typedef _OpenAtNative = Int32 Function(Int32, Pointer<Uint8>, Int32, Uint32);
typedef _OpenAtDart = int Function(int, Pointer<Uint8>, int, int);
typedef _CloseNative = Int32 Function(Int32);
typedef _CloseDart = int Function(int);
typedef _FtruncateNative = Int32 Function(Int32, Int64);
typedef _FtruncateDart = int Function(int, int);
typedef _FchmodNative = Int32 Function(Int32, Uint32);
typedef _FchmodDart = int Function(int, int);
typedef _MkdirAtNative = Int32 Function(Int32, Pointer<Uint8>, Uint32);
typedef _MkdirAtDart = int Function(int, Pointer<Uint8>, int);
typedef _UnlinkAtNative = Int32 Function(Int32, Pointer<Uint8>, Int32);
typedef _UnlinkAtDart = int Function(int, Pointer<Uint8>, int);
typedef _RenameAtNative =
    Int32 Function(Int32, Pointer<Uint8>, Int32, Pointer<Uint8>);
typedef _RenameAtDart = int Function(int, Pointer<Uint8>, int, Pointer<Uint8>);
typedef _SymlinkAtNative =
    Int32 Function(Pointer<Uint8>, Int32, Pointer<Uint8>);
typedef _SymlinkAtDart = int Function(Pointer<Uint8>, int, Pointer<Uint8>);
typedef _ReadlinkAtNative =
    IntPtr Function(Int32, Pointer<Uint8>, Pointer<Uint8>, IntPtr);
typedef _ReadlinkAtDart =
    int Function(int, Pointer<Uint8>, Pointer<Uint8>, int);
typedef _ErrnoLocationNative = Pointer<Int32> Function();
typedef _ErrnoLocationDart = Pointer<Int32> Function();

_MallocDart? _malloc;
_FreeDart? _free;
_OpenDart? _open;
_OpenAtDart? _openat;
_CloseDart? _close;
_FtruncateDart? _ftruncate;
_FchmodDart? _fchmod;
_MkdirAtDart? _mkdirat;
_UnlinkAtDart? _unlinkat;
_RenameAtDart? _renameat;
_SymlinkAtDart? _symlinkat;
_ReadlinkAtDart? _readlinkat;
_ErrnoLocationDart? _errnoLocation;

bool _initialized = false;
bool _supported = false;
String? _fdRoot;

/// A verified file descriptor and a stable `/dev/fd`-style path for it.
///
/// The descriptor is opened by walking each path component with `openat` and
/// `O_NOFOLLOW`, so a symlink cannot be substituted between the permission
/// check and the actual operation. The descriptor path remains valid even if
/// the original name is renamed or replaced.
class SecureFileHandle {
  final int _descriptor;
  final String path;

  bool _closed = false;

  SecureFileHandle._(this._descriptor, this.path);

  void close() {
    if (_closed) return;
    _closed = true;
    _close?.call(_descriptor);
  }
}

/// Descriptor-based file opening for POSIX platforms.
///
/// Windows and platforms without a usable descriptor filesystem return `null`,
/// allowing the caller to fall back to the native path-based operation.
class SecureFileOpener {
  static bool get isSupported {
    _ensureInitialized();
    return _supported;
  }

  /// Opens an existing file for reading without following symlinks.
  static SecureFileHandle? openRead(String canonicalPath) {
    if (!isSupported) return null;
    return _openPath(canonicalPath, _oRdonly | _oNoFollow | _oCloexec);
  }

  /// Returns metadata for [canonicalPath] using a verified descriptor.
  ///
  /// The final entry is opened with `O_NOFOLLOW`; metadata is then read from
  /// the descriptor path, so replacing the original path with a symlink after
  /// the permission check cannot redirect the stat operation.
  static FileStat? stat(String canonicalPath) {
    if (!isSupported) return null;

    try {
      final handle = _openPath(
        canonicalPath,
        _oMetadata | _oNoFollow | _oCloexec,
      );
      if (handle == null) return null;
      try {
        final info = FileStat.statSync(handle.path);
        // On Linux, O_PATH|O_NOFOLLOW opens the symlink itself. Treat that
        // race result as missing rather than exposing the substituted entry.
        if (info.type == FileSystemEntityType.link) {
          return _notFoundStat();
        }
        return info;
      } finally {
        handle.close();
      }
    } on PathNotFoundException {
      return _notFoundStat();
    } on FileSystemException {
      return _notFoundStat();
    }
  }

  /// Checks whether [canonicalPath] is an existing entity of [expectedType].
  ///
  /// Returns `null` when descriptor operations are unavailable.
  static bool? existsAs(
    String canonicalPath,
    FileSystemEntityType expectedType,
  ) {
    final info = stat(canonicalPath);
    if (info == null) return null;
    return info.type == expectedType;
  }

  static FileStat _notFoundStat() {
    return FileStat.statSync('${_fdRoot!}/-1');
  }

  /// Applies POSIX permission bits to an open descriptor.
  ///
  /// This is used by file copies so the destination keeps the source mode
  /// without reopening it by path.
  static void setMode(SecureFileHandle handle, int mode) {
    if (!isSupported) return;
    if (_fchmod!(handle._descriptor, mode & 0xFFF) != 0) {
      throw FileSystemException(
        'Unable to set file mode',
        handle.path,
        _osError(),
      );
    }
  }

  /// Opens (and optionally creates/truncates) a file for writing.
  static SecureFileHandle? openWrite(
    String canonicalPath, {
    required FileMode mode,
  }) {
    if (!isSupported) return null;

    final int access;
    final bool truncate;
    if (mode == FileMode.write) {
      access = _oRdwr;
      truncate = true;
    } else if (mode == FileMode.append) {
      access = _oRdwr | _oAppend;
      truncate = false;
    } else if (mode == FileMode.writeOnly) {
      access = _oWronly;
      truncate = true;
    } else if (mode == FileMode.writeOnlyAppend) {
      access = _oWronly | _oAppend;
      truncate = false;
    } else {
      return openRead(canonicalPath);
    }

    final handle = _openPath(
      canonicalPath,
      access | _oCreat | _oNoFollow | _oCloexec,
    );
    if (handle == null) return null;

    if (truncate && _ftruncate!(handle._descriptor, 0) != 0) {
      final error = _osError();
      handle.close();
      throw FileSystemException(
        'Unable to truncate file after secure open',
        canonicalPath,
        error,
      );
    }
    return handle;
  }

  /// Creates a uniquely named directory with mode 0700 in [canonicalParent].
  ///
  /// The random suffix is appended to [namePrefix]. The suffix is returned so
  /// the caller can preserve the user-facing prefix spelling in the returned
  /// `Directory` path.
  static String? createTempDirectory(
    String canonicalParent,
    String namePrefix,
  ) {
    if (!isSupported) return null;
    if (namePrefix.contains('\u0000') || namePrefix.contains(p.separator)) {
      throw FileSystemException(
        'Invalid temporary directory prefix',
        namePrefix,
      );
    }

    final parent = _openDirectory(canonicalParent);
    if (parent == null) return null;

    try {
      for (var attempt = 0; attempt < 64; attempt++) {
        final suffix = _randomSuffix();
        final name = '$namePrefix$suffix';
        final result = _withCString(
          name,
          (entry) => _mkdirat!(parent._descriptor, entry, _tempDirectoryMode),
        );
        if (result == 0) return suffix;

        final code = _errnoCode();
        if (code == _eExist) continue;
        _throwNamespaceError(
          p.join(canonicalParent, name),
          'create temporary directory',
          code: code,
        );
      }
    } finally {
      parent.close();
    }

    throw FileSystemException(
      'Unable to create a unique temporary directory',
      canonicalParent,
    );
  }

  /// Reads a symbolic link target relative to a verified parent descriptor.
  static String? readLink(String canonicalPath) {
    if (!isSupported) return null;

    final target = namespaceTarget(canonicalPath);
    if (target == null) return null;

    final parent = _openDirectory(target.parent);
    if (parent == null) return null;

    try {
      var size = 256;
      while (size <= 65536) {
        final buffer = _malloc!(size).cast<Uint8>();
        try {
          final result = _withCString(
            target.name,
            (name) => _readlinkat!(parent._descriptor, name, buffer, size),
          );
          if (result < 0) {
            _throwNamespaceError(canonicalPath, 'read link');
          }
          if (result < size) {
            return utf8.decode(buffer.asTypedList(result));
          }
        } finally {
          _free!(buffer.cast<Void>());
        }
        size *= 2;
      }
    } finally {
      parent.close();
    }

    throw FileSystemException(
      'Symbolic link target is too long',
      canonicalPath,
    );
  }

  static final Random _random = Random.secure();

  static String _randomSuffix() {
    const alphabet =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final buffer = StringBuffer();
    for (var index = 0; index < 8; index++) {
      buffer.write(alphabet[_random.nextInt(alphabet.length)]);
    }
    return buffer.toString();
  }

  /// Splits [path] into a parent directory and its final name.
  ///
  /// The caller must provide an already-canonical parent directory. The final
  /// component is deliberately not resolved: delete, rename and create
  /// operations must act on the directory entry itself, not on a symlink
  /// target.
  static ({String parent, String name})? namespaceTarget(String path) {
    if (!isSupported) return null;

    final absolute = p.normalize(p.absolute(path));
    final name = p.basename(absolute);
    if (name.isEmpty ||
        name == '.' ||
        name == '..' ||
        name == p.separator ||
        name.contains(p.separator) ||
        name.contains('\u0000')) {
      throw FileSystemException('Invalid filesystem entry name', path);
    }

    return (parent: p.dirname(absolute), name: name);
  }

  /// Creates a regular file without following symlinks.
  static void createFile(
    String path, {
    bool recursive = false,
    bool exclusive = false,
  }) {
    final target = namespaceTarget(path);
    if (target == null) return;

    final parent = recursive
        ? _ensureDirectory(target.parent)
        : _openDirectory(target.parent);
    if (parent == null) return;

    try {
      // O_RDONLY lets File.create succeed on an existing read-only file, as
      // the native implementation does, while O_CREAT still creates missing
      // files. O_NONBLOCK avoids waiting on a FIFO.
      final flags =
          _oRdonly |
          _oCreat |
          _oNonBlock |
          _oNoFollow |
          _oCloexec |
          (exclusive ? _oExcl : 0);
      final descriptor = _withCString(
        target.name,
        (name) => _openat!(parent._descriptor, name, flags, _defaultMode),
      );
      if (descriptor < 0) {
        _throwNamespaceError(path, 'create file');
      }
      try {
        final type = File(_descriptorPath(descriptor)).statSync().type;
        if (type == FileSystemEntityType.directory) {
          throw FileSystemException(
            'Cannot create file',
            path,
            OSError('Is a directory', _eIsDir),
          );
        }
      } finally {
        _close!(descriptor);
      }
    } finally {
      parent.close();
    }
  }

  /// Creates a directory without following symlinks.
  static void createDirectory(String path, {bool recursive = false}) {
    final target = namespaceTarget(path);
    if (target == null) return;

    final parent = recursive
        ? _ensureDirectory(target.parent)
        : _openDirectory(target.parent);
    if (parent == null) return;

    try {
      final result = _withCString(
        target.name,
        (name) => _mkdirat!(parent._descriptor, name, _defaultDirectoryMode),
      );
      if (result == 0) return;

      final code = _errnoCode();
      if (code == _eExist) {
        // Directory.create is idempotent for an existing directory, but an
        // existing symlink or regular file must not be accepted.
        final existing = _withCString(
          target.name,
          (name) => _openat!(
            parent._descriptor,
            name,
            _oRdonly | _oDirectory | _oNoFollow | _oCloexec,
            _defaultMode,
          ),
        );
        if (existing >= 0) {
          _close!(existing);
          return;
        }
      }

      _throwNamespaceError(path, 'create directory', code: code);
    } finally {
      parent.close();
    }
  }

  /// Removes a file or a symbolic link without following symlinks.
  ///
  /// By default, a path that resolves to a directory is rejected with EISDIR,
  /// matching `File.delete`. Recursive deletion passes [allowDirectoryLink]
  /// to unlink a symlink to a directory without touching its target.
  static void deleteFile(String path, {bool allowDirectoryLink = false}) {
    final target = namespaceTarget(path);
    if (target == null) return;

    final parent = _openDirectory(target.parent);
    if (parent == null) return;

    try {
      if (!allowDirectoryLink) {
        final type = FileSystemEntity.typeSync(
          p.join(target.parent, target.name),
        );
        if (type == FileSystemEntityType.directory) {
          throw FileSystemException(
            'Cannot delete file',
            path,
            OSError('Is a directory', _eIsDir),
          );
        }
        if (type == FileSystemEntityType.notFound) {
          throw PathNotFoundException(
            path,
            OSError('No such file or directory', _eNoEnt),
          );
        }
      }

      final result = _withCString(
        target.name,
        (name) => _unlinkat!(parent._descriptor, name, 0),
      );
      if (result != 0) {
        _throwNamespaceError(path, 'delete file');
      }
    } finally {
      parent.close();
    }
  }

  /// Removes a symbolic link, rejecting regular files and directories.
  static void deleteLink(String path) {
    final target = namespaceTarget(path);
    if (target == null) return;

    final parent = _openDirectory(target.parent);
    if (parent == null) return;

    try {
      if (!_isSymlinkAt(parent._descriptor, target.name)) {
        final type = FileSystemEntity.typeSync(
          p.join(target.parent, target.name),
        );
        if (type == FileSystemEntityType.directory) {
          throw FileSystemException(
            'Cannot delete link',
            path,
            OSError('Is a directory', _eIsDir),
          );
        }
        throw FileSystemException(
          'Cannot delete link',
          path,
          OSError('Invalid argument', _eInval),
        );
      }

      final result = _withCString(
        target.name,
        (name) => _unlinkat!(parent._descriptor, name, 0),
      );
      if (result != 0) {
        _throwNamespaceError(path, 'delete link');
      }
    } finally {
      parent.close();
    }
  }

  /// Removes a directory (or a symlink to one) without following symlinks.
  static void deleteDirectory(String path, {bool recursive = false}) {
    if (recursive) {
      deletePathRecursive(path);
      return;
    }

    final target = namespaceTarget(path);
    if (target == null) return;

    final parent = _openDirectory(target.parent);
    if (parent == null) return;

    try {
      final isSymlink = _isSymlinkAt(parent._descriptor, target.name);
      if (isSymlink) {
        final type = FileSystemEntity.typeSync(
          p.join(target.parent, target.name),
        );
        if (type != FileSystemEntityType.directory) {
          throw FileSystemException(
            'Deletion failed',
            path,
            OSError('Not a directory', _eNotDir),
          );
        }
      }
      final result = _withCString(
        target.name,
        (name) => _unlinkat!(
          parent._descriptor,
          name,
          isSymlink ? 0 : _atRemoveDirectory,
        ),
      );
      if (result != 0) {
        _throwNamespaceError(path, 'delete directory');
      }
    } finally {
      parent.close();
    }
  }

  static bool _isSymlinkAt(int directoryFd, String name) {
    final buffer = _malloc!(1).cast<Uint8>();
    try {
      final result = _withCString(
        name,
        (entry) => _readlinkat!(directoryFd, entry, buffer, 1),
      );
      if (result >= 0) return true;
      final code = _errnoCode();
      if (code == _eInval) return false;
      _throwNamespaceError(name, 'inspect directory entry', code: code);
    } finally {
      _free!(buffer.cast<Void>());
    }
  }

  /// Recursively removes a path using descriptor-based deletes.
  ///
  /// Directories are traversed, while files and symlinks are unlinked. Listing
  /// is path-based, but every destructive step re-opens the canonical parent
  /// with `O_NOFOLLOW`. A concurrent symlink substitution therefore fails
  /// closed instead of deleting outside the authorized namespace.
  static void deletePathRecursive(String path) {
    final target = namespaceTarget(path);
    if (target == null) return;

    final fullPath = p.join(target.parent, target.name);
    final parent = _openDirectory(target.parent);
    if (parent == null) return;

    try {
      if (_isSymlinkAt(parent._descriptor, target.name)) {
        final result = _withCString(
          target.name,
          (name) => _unlinkat!(parent._descriptor, name, 0),
        );
        if (result != 0) {
          _throwNamespaceError(path, 'delete directory');
        }
        return;
      }
    } finally {
      parent.close();
    }

    final type = FileSystemEntity.typeSync(fullPath, followLinks: false);
    if (type != FileSystemEntityType.directory) {
      deleteFile(fullPath);
      return;
    }

    final children = Directory(fullPath).listSync(followLinks: false);
    for (final child in children) {
      final childPath = p.join(fullPath, p.basename(child.path));
      if (child is Directory) {
        deletePathRecursive(childPath);
      } else {
        deleteFile(childPath, allowDirectoryLink: true);
      }
    }

    deleteDirectory(fullPath);
  }

  /// Renames a directory entry relative to verified parent descriptors.
  static void renamePath(String oldPath, String newPath) {
    final oldTarget = namespaceTarget(oldPath);
    final newTarget = namespaceTarget(newPath);
    if (oldTarget == null || newTarget == null) return;

    final oldParent = _openDirectory(oldTarget.parent);
    final newParent = _openDirectory(newTarget.parent);
    if (oldParent == null || newParent == null) {
      oldParent?.close();
      newParent?.close();
      return;
    }

    try {
      final result = _withCString(
        oldTarget.name,
        (oldName) => _withCString(
          newTarget.name,
          (newName) => _renameat!(
            oldParent._descriptor,
            oldName,
            newParent._descriptor,
            newName,
          ),
        ),
      );
      if (result != 0) {
        _throwNamespaceError(oldPath, 'rename entry');
      }
    } finally {
      oldParent.close();
      newParent.close();
    }
  }

  /// Creates a symbolic link without following parent symlinks.
  static void createLink(
    String linkPath,
    String targetPath, {
    bool recursive = false,
  }) {
    final target = namespaceTarget(linkPath);
    if (target == null) return;

    final parent = recursive
        ? _ensureDirectory(target.parent)
        : _openDirectory(target.parent);
    if (parent == null) return;

    try {
      final result = _withCString(
        targetPath,
        (linkTarget) => _withCString(
          target.name,
          (name) => _symlinkat!(linkTarget, parent._descriptor, name),
        ),
      );
      if (result != 0) {
        _throwNamespaceError(linkPath, 'create link');
      }
    } finally {
      parent.close();
    }
  }

  /// Atomically replaces a symbolic link without following parent symlinks.
  static void updateLink(String linkPath, String targetPath) {
    final target = namespaceTarget(linkPath);
    if (target == null) return;

    final parent = _openDirectory(target.parent);
    if (parent == null) return;

    final temporaryName =
        '.${target.name}.d4rt-$pid-${DateTime.now().microsecondsSinceEpoch}';
    var temporaryCreated = false;
    try {
      final created = _withCString(
        targetPath,
        (linkTarget) => _withCString(
          temporaryName,
          (name) => _symlinkat!(linkTarget, parent._descriptor, name),
        ),
      );
      if (created != 0) {
        _throwNamespaceError(linkPath, 'update link');
      }
      temporaryCreated = true;

      final renamed = _withCString(
        temporaryName,
        (oldName) => _withCString(
          target.name,
          (newName) => _renameat!(
            parent._descriptor,
            oldName,
            parent._descriptor,
            newName,
          ),
        ),
      );
      if (renamed != 0) {
        _throwNamespaceError(linkPath, 'update link');
      }
      temporaryCreated = false;
    } finally {
      if (temporaryCreated) {
        _withCString(
          temporaryName,
          (name) => _unlinkat!(parent._descriptor, name, 0),
        );
      }
      parent.close();
    }
  }

  static SecureFileHandle? _openDirectory(String canonicalPath) {
    if (canonicalPath == p.separator) {
      final descriptor = _withCString(
        p.separator,
        (root) => _open!(root, _oRdonly | _oDirectory | _oCloexec),
      );
      if (descriptor < 0) {
        throw FileSystemException(
          'Unable to open filesystem root',
          canonicalPath,
          _osError(),
        );
      }
      return SecureFileHandle._(descriptor, _descriptorPath(descriptor));
    }

    return _openPath(
      canonicalPath,
      _oRdonly | _oDirectory | _oNoFollow | _oCloexec,
    );
  }

  static SecureFileHandle? _ensureDirectory(String canonicalPath) {
    final parts = p
        .split(canonicalPath)
        .where((segment) => segment != p.separator && segment.isNotEmpty)
        .toList();

    var directoryFd = _withCString(
      p.separator,
      (root) => _open!(root, _oRdonly | _oDirectory | _oCloexec),
    );
    if (directoryFd < 0) {
      throw FileSystemException(
        'Unable to open filesystem root',
        canonicalPath,
        _osError(),
      );
    }

    try {
      for (final segment in parts) {
        var nextFd = _withCString(
          segment,
          (name) => _openat!(
            directoryFd,
            name,
            _oRdonly | _oDirectory | _oNoFollow | _oCloexec,
            _defaultMode,
          ),
        );
        if (nextFd < 0 && _errnoCode() == _eNoEnt) {
          final created = _withCString(
            segment,
            (name) => _mkdirat!(directoryFd, name, _defaultDirectoryMode),
          );
          if (created == 0 || _errnoCode() == _eExist) {
            nextFd = _withCString(
              segment,
              (name) => _openat!(
                directoryFd,
                name,
                _oRdonly | _oDirectory | _oNoFollow | _oCloexec,
                _defaultMode,
              ),
            );
          }
        }
        if (nextFd < 0) {
          _throwNamespaceError(canonicalPath, 'create directory');
        }

        _close!(directoryFd);
        directoryFd = nextFd;
      }

      final result = directoryFd;
      directoryFd = -1;
      return SecureFileHandle._(result, _descriptorPath(result));
    } finally {
      if (directoryFd >= 0) _close!(directoryFd);
    }
  }

  static Never _throwOpenError(String path, String component, int code) {
    final error = OSError('secure filesystem operation failed', code);

    if (code == _eNoEnt) {
      throw PathNotFoundException(path, error);
    }
    if (code == _eAcces || code == _ePerm) {
      throw PathAccessException(path, error);
    }
    if (code == _eExist) {
      throw PathExistsException(path, error);
    }
    throw FileSystemException(
      'Unable to open path component "$component"',
      path,
      error,
    );
  }

  static Never _throwNamespaceError(
    String path,
    String operation, {
    int? code,
  }) {
    final errorCode = code ?? _errnoCode();
    final error = OSError('secure filesystem operation failed', errorCode);

    if (errorCode == _eNoEnt) {
      throw PathNotFoundException(path, error);
    }
    if (errorCode == _eAcces || errorCode == _ePerm) {
      throw PathAccessException(path, error);
    }
    if (errorCode == _eExist) {
      throw PathExistsException(path, error);
    }
    throw FileSystemException('Unable to $operation', path, error);
  }

  static int _errnoCode() => _errnoLocation?.call().value ?? 0;

  static SecureFileHandle? _openPath(String canonicalPath, int finalFlags) {
    if (canonicalPath.contains('\u0000')) {
      throw FileSystemException(
        'Filesystem paths cannot contain NUL characters',
        canonicalPath,
      );
    }

    final parts = p
        .split(canonicalPath)
        .where((segment) => segment != p.separator && segment.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      throw FileSystemException(
        'Cannot open a filesystem root as a file',
        canonicalPath,
      );
    }

    int? directoryFd;
    try {
      directoryFd = _withCString(
        p.separator,
        (root) => _open!(root, _oRdonly | _oDirectory | _oCloexec),
      );
      if (directoryFd! < 0) {
        final code = _errnoCode();
        directoryFd = null;
        _throwOpenError(canonicalPath, '/', code);
      }

      for (var index = 0; index < parts.length; index++) {
        final segment = parts[index];
        final isLast = index == parts.length - 1;
        final flags = isLast
            ? finalFlags
            : _oRdonly | _oDirectory | _oNoFollow | _oCloexec;
        final nextFd = _withCString(
          segment,
          (name) => _openat!(directoryFd!, name, flags, _defaultMode),
        );

        if (nextFd < 0) {
          final code = _errnoCode();
          _throwOpenError(canonicalPath, segment, code);
        }

        _close!(directoryFd!);
        directoryFd = nextFd;

        if (isLast) {
          final descriptor = directoryFd;
          directoryFd = null;
          return SecureFileHandle._(descriptor, _descriptorPath(descriptor));
        }
      }
    } finally {
      if (directoryFd != null && directoryFd >= 0) {
        _close!(directoryFd);
      }
    }

    throw FileSystemException('Unable to open file', canonicalPath);
  }

  static void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    if (Platform.isWindows) return;

    final fdRoot = _platformFdRoot();
    if (fdRoot == null || !Directory(fdRoot).existsSync()) return;

    try {
      final libc = DynamicLibrary.process();
      _malloc = libc.lookupFunction<_MallocNative, _MallocDart>('malloc');
      _free = libc.lookupFunction<_FreeNative, _FreeDart>('free');
      _open = libc.lookupFunction<_OpenNative, _OpenDart>('open');
      _openat = libc.lookupFunction<_OpenAtNative, _OpenAtDart>('openat');
      _close = libc.lookupFunction<_CloseNative, _CloseDart>('close');
      _ftruncate = libc.lookupFunction<_FtruncateNative, _FtruncateDart>(
        'ftruncate',
      );
      _fchmod = libc.lookupFunction<_FchmodNative, _FchmodDart>('fchmod');
      _mkdirat = libc.lookupFunction<_MkdirAtNative, _MkdirAtDart>('mkdirat');
      _unlinkat = libc.lookupFunction<_UnlinkAtNative, _UnlinkAtDart>(
        'unlinkat',
      );
      _renameat = libc.lookupFunction<_RenameAtNative, _RenameAtDart>(
        'renameat',
      );
      _symlinkat = libc.lookupFunction<_SymlinkAtNative, _SymlinkAtDart>(
        'symlinkat',
      );
      _readlinkat = libc.lookupFunction<_ReadlinkAtNative, _ReadlinkAtDart>(
        'readlinkat',
      );
      _errnoLocation = libc
          .lookupFunction<_ErrnoLocationNative, _ErrnoLocationDart>(
            (Platform.isMacOS || Platform.isIOS)
                ? '__error'
                : '__errno_location',
          );
      _fdRoot = fdRoot;
      _supported = true;
    } catch (_) {
      _supported = false;
    }
  }

  static String? _platformFdRoot() {
    if (Platform.isMacOS || Platform.isIOS) return '/dev/fd';
    if (Platform.isLinux || Platform.isAndroid) return '/proc/self/fd';
    return null;
  }

  static String _descriptorPath(int descriptor) {
    final root = _fdRoot;
    if (root == null) {
      throw StateError('Secure file descriptors are not supported');
    }
    return '$root/$descriptor';
  }

  static OSError _osError() {
    final code = _errnoLocation?.call().value ?? 0;
    return OSError('secure filesystem operation failed', code);
  }

  static T _withCString<T>(String value, T Function(Pointer<Uint8>) action) {
    final bytes = utf8.encode(value);
    final pointer = _malloc!(bytes.length + 1).cast<Uint8>();
    try {
      final list = pointer.asTypedList(bytes.length + 1);
      list.setAll(0, bytes);
      list[bytes.length] = 0;
      return action(pointer);
    } finally {
      _free!(pointer.cast<Void>());
    }
  }

  static bool get _isMacLike => Platform.isMacOS || Platform.isIOS;

  static int get _oRdonly => 0;
  // Linux O_PATH and Apple O_EVTONLY allow metadata operations without read
  // permission on the final entry.
  static int get _oMetadata => _isMacLike ? 0x8000 : 0x200000;
  static int get _oWronly => 1;
  static int get _oRdwr => 2;
  static int get _oCreat => _isMacLike ? 0x0200 : 0x40;
  static int get _oExcl => _isMacLike ? 0x0800 : 0x80;
  static int get _oAppend => _isMacLike ? 0x0008 : 0x400;
  static int get _oNonBlock => _isMacLike ? 0x0004 : 0x800;
  static int get _oNoFollow => _isMacLike ? 0x0100 : 0x20000;
  static int get _oDirectory => _isMacLike ? 0x100000 : 0x10000;
  static int get _oCloexec => _isMacLike ? 0x1000000 : 0x80000;
  static int get _atRemoveDirectory => _isMacLike ? 0x80 : 0x200;

  static const int _defaultMode = 0x1A4; // 0644
  static const int _defaultDirectoryMode = 0x1ED; // 0755
  static const int _tempDirectoryMode = 0x1C0; // 0700
  static const int _ePerm = 1;
  static const int _eNoEnt = 2;
  static const int _eAcces = 13;
  static const int _eExist = 17;
  static const int _eInval = 22;
  static const int _eIsDir = 21;
  static const int _eNotDir = 20;
}
