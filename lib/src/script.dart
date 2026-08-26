import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';

/// A pre-parsed and validated Dart script that can be executed repeatedly
/// without the overhead of re-parsing source code.
///
/// Use [D4rt.compile] to create instances of [PrecompiledScript].
///
/// ## Example:
/// ```dart
/// final d4rt = D4rt();
/// final script = d4rt.compile('int calculate(int x) => x * x;');
///
/// // Execute multiple times with high performance
/// final r1 = d4rt.executeCompiled(script, name: 'calculate', positionalArgs: [5]); // 25
/// final r2 = d4rt.executeCompiled(script, name: 'calculate', positionalArgs: [10]); // 100
/// ```
class PrecompiledScript {
  /// The parsed AST compilation unit.
  final CompilationUnit compilationUnit;

  /// Line and column location information for diagnostics.
  final LineInfo? lineInfo;

  /// The raw source code that was compiled (if available).
  final String? source;

  /// The URI associated with the script (if any).
  final Uri? uri;

  /// The base directory path used for relative import resolution.
  final String? basePath;

  /// Timestamp when the script was compiled.
  final DateTime compiledAt;

  /// Creates a new [PrecompiledScript] instance.
  PrecompiledScript({
    required this.compilationUnit,
    this.lineInfo,
    this.source,
    this.uri,
    this.basePath,
    DateTime? compiledAt,
  }) : compiledAt = compiledAt ?? DateTime.now();

  /// The raw AST compilation unit.
  CompilationUnit get ast => compilationUnit;

  /// The number of top-level declarations in the script.
  int get declarationCount => compilationUnit.declarations.length;

  /// The number of directives (imports, exports, etc.) in the script.
  int get directiveCount => compilationUnit.directives.length;

  @override
  String toString() {
    final target = uri?.toString() ?? (source != null ? 'source (${source!.length} chars)' : 'compiled AST');
    return 'PrecompiledScript($target, declarations: $declarationCount, directives: $directiveCount)';
  }
}
