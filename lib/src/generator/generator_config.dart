/// Generator Configuration for Bridge Generator.
///
/// Defines all settings for bridge code generation including:
/// - Input/output paths
/// - Filtering options
/// - Code style preferences
/// - Type mappings
library;

// =============================================================================
// GENERATOR CONFIG
// =============================================================================

/// Configuration for the bridge generator.
class GeneratorConfig {
  /// Base path for resolving relative paths.
  final String basePath;

  /// Input paths (files or directories) to process.
  final List<String> inputPaths;

  /// Output directory for generated files.
  final String outputPath;

  /// Patterns to exclude from processing.
  final List<String> excludePatterns;

  /// Whether to include private members (starting with _).
  final bool includePrivateMembers;

  /// Whether to generate bridges for abstract classes.
  final bool includeAbstractClasses;

  /// Whether to generate static method bridges.
  final bool includeStaticMembers;

  /// Whether to generate operator bridges.
  final bool includeOperators;

  /// Annotation that marks classes for bridging (e.g., '@BridgeClass').
  final String? bridgeAnnotation;

  /// Type mappings for complex types.
  final Map<String, String> typeMappings;

  /// Custom imports to add to generated files.
  final List<String> additionalImports;

  /// Output file naming pattern.
  final OutputNaming outputNaming;

  /// Code generation style options.
  final CodeStyle codeStyle;

  /// Verbosity level for logging.
  final LogLevel logLevel;

  const GeneratorConfig({
    this.basePath = '.',
    required this.inputPaths,
    required this.outputPath,
    this.excludePatterns = const ['.g.dart', '.generated.dart', '_test.dart'],
    this.includePrivateMembers = false,
    this.includeAbstractClasses = false,
    this.includeStaticMembers = true,
    this.includeOperators = true,
    this.bridgeAnnotation,
    this.typeMappings = const {},
    this.additionalImports = const [],
    this.outputNaming = OutputNaming.suffixed,
    this.codeStyle = const CodeStyle(),
    this.logLevel = LogLevel.info,
  });

  /// Creates config from a JSON map.
  factory GeneratorConfig.fromJson(
    Map<String, dynamic> json, {
    String basePath = '.',
  }) {
    return GeneratorConfig(
      basePath: json['basePath'] as String? ?? basePath,
      inputPaths: (json['inputPaths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      outputPath: json['outputPath'] as String? ?? 'lib/generated',
      excludePatterns: (json['excludePatterns'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['.g.dart', '.generated.dart', '_test.dart'],
      includePrivateMembers: json['includePrivateMembers'] as bool? ?? false,
      includeAbstractClasses: json['includeAbstractClasses'] as bool? ?? false,
      includeStaticMembers: json['includeStaticMembers'] as bool? ?? true,
      includeOperators: json['includeOperators'] as bool? ?? true,
      bridgeAnnotation: json['bridgeAnnotation'] as String?,
      typeMappings: (json['typeMappings'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as String)) ??
          const {},
      additionalImports: (json['additionalImports'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      outputNaming: OutputNaming.values.firstWhere(
        (e) => e.name == (json['outputNaming'] as String?),
        orElse: () => OutputNaming.suffixed,
      ),
      codeStyle: json['codeStyle'] != null
          ? CodeStyle.fromJson(json['codeStyle'] as Map<String, dynamic>)
          : const CodeStyle(),
      logLevel: LogLevel.values.firstWhere(
        (e) => e.name == (json['logLevel'] as String?),
        orElse: () => LogLevel.info,
      ),
    );
  }

  /// Converts config to JSON.
  Map<String, dynamic> toJson() => {
        'basePath': basePath,
        'inputPaths': inputPaths,
        'outputPath': outputPath,
        'excludePatterns': excludePatterns,
        'includePrivateMembers': includePrivateMembers,
        'includeAbstractClasses': includeAbstractClasses,
        'includeStaticMembers': includeStaticMembers,
        'includeOperators': includeOperators,
        'bridgeAnnotation': bridgeAnnotation,
        'typeMappings': typeMappings,
        'additionalImports': additionalImports,
        'outputNaming': outputNaming.name,
        'codeStyle': codeStyle.toJson(),
        'logLevel': logLevel.name,
      };

  /// Creates a copy with modified values.
  GeneratorConfig copyWith({
    String? basePath,
    List<String>? inputPaths,
    String? outputPath,
    List<String>? excludePatterns,
    bool? includePrivateMembers,
    bool? includeAbstractClasses,
    bool? includeStaticMembers,
    bool? includeOperators,
    String? bridgeAnnotation,
    Map<String, String>? typeMappings,
    List<String>? additionalImports,
    OutputNaming? outputNaming,
    CodeStyle? codeStyle,
    LogLevel? logLevel,
  }) {
    return GeneratorConfig(
      basePath: basePath ?? this.basePath,
      inputPaths: inputPaths ?? this.inputPaths,
      outputPath: outputPath ?? this.outputPath,
      excludePatterns: excludePatterns ?? this.excludePatterns,
      includePrivateMembers:
          includePrivateMembers ?? this.includePrivateMembers,
      includeAbstractClasses:
          includeAbstractClasses ?? this.includeAbstractClasses,
      includeStaticMembers: includeStaticMembers ?? this.includeStaticMembers,
      includeOperators: includeOperators ?? this.includeOperators,
      bridgeAnnotation: bridgeAnnotation ?? this.bridgeAnnotation,
      typeMappings: typeMappings ?? this.typeMappings,
      additionalImports: additionalImports ?? this.additionalImports,
      outputNaming: outputNaming ?? this.outputNaming,
      codeStyle: codeStyle ?? this.codeStyle,
      logLevel: logLevel ?? this.logLevel,
    );
  }
}

// =============================================================================
// OUTPUT NAMING
// =============================================================================

/// Output file naming strategy.
enum OutputNaming {
  /// Add '.bridge.dart' suffix (user.dart -> user.bridge.dart).
  suffixed,

  /// Single file per package (all_bridges.dart).
  consolidated,

  /// Mirror input structure in output directory.
  mirrored,
}

// =============================================================================
// CODE STYLE
// =============================================================================

/// Code generation style options.
class CodeStyle {
  /// Line length for formatting.
  final int lineLength;

  /// Whether to use trailing commas.
  final bool trailingCommas;

  /// Whether to add documentation comments.
  final bool generateDocs;

  /// Whether to use const where possible.
  final bool preferConst;

  /// Indentation string (spaces or tabs).
  final String indent;

  const CodeStyle({
    this.lineLength = 80,
    this.trailingCommas = true,
    this.generateDocs = true,
    this.preferConst = true,
    this.indent = '  ',
  });

  factory CodeStyle.fromJson(Map<String, dynamic> json) {
    return CodeStyle(
      lineLength: json['lineLength'] as int? ?? 80,
      trailingCommas: json['trailingCommas'] as bool? ?? true,
      generateDocs: json['generateDocs'] as bool? ?? true,
      preferConst: json['preferConst'] as bool? ?? true,
      indent: json['indent'] as String? ?? '  ',
    );
  }

  Map<String, dynamic> toJson() => {
        'lineLength': lineLength,
        'trailingCommas': trailingCommas,
        'generateDocs': generateDocs,
        'preferConst': preferConst,
        'indent': indent,
      };
}

// =============================================================================
// LOG LEVEL
// =============================================================================

/// Logging verbosity levels.
enum LogLevel {
  /// No output.
  quiet,

  /// Errors only.
  error,

  /// Errors and warnings.
  warning,

  /// Normal output.
  info,

  /// Detailed output.
  verbose,

  /// Debug output.
  debug,
}

// =============================================================================
// CONFIG BUILDER
// =============================================================================

/// Fluent builder for GeneratorConfig.
class ConfigBuilder {
  String _basePath = '.';
  final List<String> _inputPaths = [];
  String _outputPath = 'lib/generated';
  final List<String> _excludePatterns = ['.g.dart', '.generated.dart'];
  bool _includePrivateMembers = false;
  bool _includeAbstractClasses = false;
  bool _includeStaticMembers = true;
  bool _includeOperators = true;
  String? _bridgeAnnotation;
  final Map<String, String> _typeMappings = {};
  final List<String> _additionalImports = [];
  OutputNaming _outputNaming = OutputNaming.suffixed;
  CodeStyle _codeStyle = const CodeStyle();
  LogLevel _logLevel = LogLevel.info;

  /// Sets the base path.
  ConfigBuilder basePath(String path) {
    _basePath = path;
    return this;
  }

  /// Adds an input path.
  ConfigBuilder addInput(String path) {
    _inputPaths.add(path);
    return this;
  }

  /// Adds multiple input paths.
  ConfigBuilder addInputs(List<String> paths) {
    _inputPaths.addAll(paths);
    return this;
  }

  /// Sets the output path.
  ConfigBuilder output(String path) {
    _outputPath = path;
    return this;
  }

  /// Adds an exclusion pattern.
  ConfigBuilder exclude(String pattern) {
    _excludePatterns.add(pattern);
    return this;
  }

  /// Includes private members.
  ConfigBuilder withPrivateMembers() {
    _includePrivateMembers = true;
    return this;
  }

  /// Includes private members (alias for withPrivateMembers).
  ConfigBuilder includePrivate(bool value) {
    _includePrivateMembers = value;
    return this;
  }

  /// Includes abstract classes.
  ConfigBuilder withAbstractClasses() {
    _includeAbstractClasses = true;
    return this;
  }

  /// Excludes static members.
  ConfigBuilder withoutStaticMembers() {
    _includeStaticMembers = false;
    return this;
  }

  /// Excludes operators.
  ConfigBuilder withoutOperators() {
    _includeOperators = false;
    return this;
  }

  /// Sets the bridge annotation filter.
  ConfigBuilder annotatedWith(String annotation) {
    _bridgeAnnotation = annotation;
    return this;
  }

  /// Sets the bridge annotation filter (alias for annotatedWith).
  ConfigBuilder annotation(String annotation) {
    _bridgeAnnotation = annotation;
    return this;
  }

  /// Adds a type mapping.
  ConfigBuilder mapType(String from, String to) {
    _typeMappings[from] = to;
    return this;
  }

  /// Adds an additional import.
  ConfigBuilder addImport(String import) {
    _additionalImports.add(import);
    return this;
  }

  /// Sets output naming strategy.
  ConfigBuilder naming(OutputNaming naming) {
    _outputNaming = naming;
    return this;
  }

  /// Sets code style.
  ConfigBuilder style(CodeStyle style) {
    _codeStyle = style;
    return this;
  }

  /// Sets log level.
  ConfigBuilder logging(LogLevel level) {
    _logLevel = level;
    return this;
  }

  /// Builds the configuration.
  GeneratorConfig build() {
    if (_inputPaths.isEmpty) {
      throw StateError('At least one input path is required');
    }
    return GeneratorConfig(
      basePath: _basePath,
      inputPaths: List.unmodifiable(_inputPaths),
      outputPath: _outputPath,
      excludePatterns: List.unmodifiable(_excludePatterns),
      includePrivateMembers: _includePrivateMembers,
      includeAbstractClasses: _includeAbstractClasses,
      includeStaticMembers: _includeStaticMembers,
      includeOperators: _includeOperators,
      bridgeAnnotation: _bridgeAnnotation,
      typeMappings: Map.unmodifiable(_typeMappings),
      additionalImports: List.unmodifiable(_additionalImports),
      outputNaming: _outputNaming,
      codeStyle: _codeStyle,
      logLevel: _logLevel,
    );
  }
}
