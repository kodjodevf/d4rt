import 'dart:io';
import 'package:d4rt/d4rt.dart';

const String version = '0.2.3';

void main(List<String> args) async {
  if (args.contains('-h') || args.contains('--help')) {
    _printUsage();
    return;
  }

  if (args.contains('-v') || args.contains('--version')) {
    stdout.writeln('d4rt version $version');
    return;
  }

  final isDebug = args.contains('--debug');
  final filteredArgs = args.where((arg) => arg != '--debug').toList();

  // Check for --eval / -e
  final evalIndex = filteredArgs.indexWhere((arg) => arg == '-e' || arg == '--eval');
  if (evalIndex >= 0) {
    if (evalIndex + 1 >= filteredArgs.length) {
      stderr.writeln('Error: -e/--eval requires a code string argument.');
      exitCode = 1;
      return;
    }
    final code = filteredArgs[evalIndex + 1];
    await _evalCode(code, isDebug: isDebug);
    return;
  }

  // Check for --introspection / -i
  final introIndex = filteredArgs.indexWhere((arg) => arg == '-i' || arg == '--introspection');
  if (introIndex >= 0) {
    if (introIndex + 1 >= filteredArgs.length) {
      stderr.writeln('Error: -i/--introspection requires a Dart file path.');
      exitCode = 1;
      return;
    }
    final filePath = filteredArgs[introIndex + 1];
    await _introspectFile(filePath, asJson: false);
    return;
  }

  // Check for --json-introspection
  final jsonIntroIndex = filteredArgs.indexOf('--json-introspection');
  if (jsonIntroIndex >= 0) {
    if (jsonIntroIndex + 1 >= filteredArgs.length) {
      stderr.writeln('Error: --json-introspection requires a Dart file path.');
      exitCode = 1;
      return;
    }
    final filePath = filteredArgs[jsonIntroIndex + 1];
    await _introspectFile(filePath, asJson: true);
    return;
  }

  if (filteredArgs.isEmpty || filteredArgs.first == 'repl') {
    await _startRepl(isDebug: isDebug);
  } else {
    final filePath = filteredArgs.first;
    final scriptArgs = filteredArgs.sublist(1);
    await _executeFile(filePath, scriptArgs, isDebug: isDebug);
  }
}

void _printUsage() {
  stdout.writeln('''
d4rt - Dart Code Interpreter & Runtime CLI

Usage:
  d4rt [options] <script.dart> [args...]       Execute a Dart script file
  d4rt -e "<code>"                             Evaluate a Dart code string directly
  d4rt -i <script.dart>                        Analyze and introspect declarations
  d4rt --json-introspection <script.dart>      Output introspection as JSON
  d4rt repl                                    Start interactive REPL shell
  d4rt                                         Start interactive REPL shell

Options:
  -h, --help                Show this help message
  -v, --version             Show d4rt version
  -e, --eval "<code>"       Evaluate a single Dart code string
  -i, --introspection       Print code structure and declaration analysis
  --json-introspection      Print code structure analysis in JSON format
  --debug                   Enable verbose debug logging
''');
}

Future<void> _evalCode(String code, {required bool isDebug}) async {
  try {
    final d4rt = D4rt(enableAstCache: true);
    if (isDebug) d4rt.setDebug(true);

    d4rt.grant(FilesystemPermission.any);
    d4rt.grant(NetworkPermission.any);
    d4rt.grant(ProcessPermission.any);

    // If source contains main(), run execute(), otherwise use eval
    if (code.contains('main(') || code.contains('main()')) {
      final result = await d4rt.execute(source: code);
      if (result != null) {
        stdout.writeln(result);
      }
    } else {
      d4rt.execute(source: 'void main() {}');
      final result = await d4rt.eval(code);
      if (result != null) {
        stdout.writeln(result);
      }
    }
  } catch (e) {
    stderr.writeln('Runtime Error: $e');
    exitCode = 1;
  }
}

Future<void> _introspectFile(String filePath, {required bool asJson}) async {
  final file = File(filePath);
  if (!await file.exists()) {
    stderr.writeln('Error: File not found: $filePath');
    exitCode = 1;
    return;
  }

  try {
    final source = await file.readAsString();
    final d4rt = D4rt();
    final result = d4rt.analyze(source: source);

    if (asJson) {
      stdout.writeln(result.toJson());
    } else {
      stdout.writeln(result.toString());
    }
  } catch (e) {
    stderr.writeln('Analysis Error: $e');
    exitCode = 1;
  }
}

Future<void> _executeFile(
  String filePath,
  List<String> scriptArgs, {
  required bool isDebug,
}) async {
  final file = File(filePath);
  if (!await file.exists()) {
    stderr.writeln('Error: File not found: $filePath');
    exitCode = 1;
    return;
  }

  try {
    final source = await file.readAsString();
    final d4rt = D4rt();
    if (isDebug) d4rt.setDebug(true);

    // Grant standard permissions for CLI execution
    d4rt.grant(FilesystemPermission.any);
    d4rt.grant(NetworkPermission.any);
    d4rt.grant(ProcessPermission.any);

    final basePath = file.parent.absolute.path;
    final result = await d4rt.execute(
      source: source,
      name: 'main',
      positionalArgs: [scriptArgs],
      basePath: basePath,
      allowFileSystemImports: true,
    );

    if (result != null && result != 0) {
      if (result is int) {
        exitCode = result;
      }
    }
  } catch (e) {
    stderr.writeln('Runtime Error: $e');
    exitCode = 1;
  }
}

Future<void> _startRepl({required bool isDebug}) async {
  stdout.writeln('==============================================');
  stdout.writeln('  d4rt v$version - Interactive Dart REPL');
  stdout.writeln('  Type :help for help, :exit or Ctrl+C to quit');
  stdout.writeln('==============================================\n');

  var d4rt = D4rt(enableAstCache: true);
  if (isDebug) d4rt.setDebug(true);

  // Grant standard permissions
  d4rt.grant(FilesystemPermission.any);
  d4rt.grant(NetworkPermission.any);
  d4rt.grant(ProcessPermission.any);

  // Initialize context
  d4rt.execute(source: 'void main() {}');

  var buffer = StringBuffer();
  var openBraces = 0;
  var openParens = 0;

  while (true) {
    final prompt = buffer.isEmpty ? 'd4rt> ' : '....> ';
    stdout.write(prompt);
    final line = stdin.readLineSync();

    if (line == null) {
      stdout.writeln();
      break;
    }

    final trimmed = line.trim();

    // REPL commands
    if (buffer.isEmpty) {
      if (trimmed == ':exit' ||
          trimmed == ':quit' ||
          trimmed == 'exit' ||
          trimmed == 'quit') {
        stdout.writeln('Goodbye!');
        break;
      }
      if (trimmed == ':help') {
        _printReplHelp();
        continue;
      }
      if (trimmed == ':clear') {
        d4rt = D4rt(enableAstCache: true);
        if (isDebug) d4rt.setDebug(true);
        d4rt.grant(FilesystemPermission.any);
        d4rt.grant(NetworkPermission.any);
        d4rt.grant(ProcessPermission.any);
        d4rt.execute(source: 'void main() {}');
        stdout.writeln('Environment cleared.');
        continue;
      }
      if (trimmed.isEmpty) {
        continue;
      }
    }

    // Count delimiters for multiline support
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '{') openBraces++;
      if (char == '}') {
        if (openBraces > 0) openBraces--;
      }
      if (char == '(') openParens++;
      if (char == ')') {
        if (openParens > 0) openParens--;
      }
    }

    buffer.writeln(line);

    if (openBraces > 0 || openParens > 0) {
      continue;
    }

    final code = buffer.toString().trim();
    buffer.clear();
    openBraces = 0;
    openParens = 0;

    if (code.isEmpty) continue;

    try {
      final result = await d4rt.eval(code);
      if (result != null) {
        stdout.writeln('=> $result');
      }
    } catch (e) {
      stderr.writeln('Error: $e');
    }
  }
}

void _printReplHelp() {
  stdout.writeln('''
REPL Commands:
  :help          Show this help message
  :clear         Reset the evaluation environment
  :exit, :quit   Exit the REPL

Tips:
  - Enter Dart expressions directly: 2 + 2, "hello".toUpperCase()
  - Define variables: var x = 42; or int y = 100;
  - Define functions: int add(int a, int b) => a + b;
  - Multiline statements with { ... } or ( ... ) are automatically collected.
''');
}
