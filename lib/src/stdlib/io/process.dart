import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:d4rt/d4rt.dart';

/// Bridged implementation of dart:io Process functionality
class ProcessIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: Process,
        name: 'Process',
        typeParameterCount: 0,
        staticMethods: {
          'start': (visitor, positionalArgs, namedArgs) =>
              _start(positionalArgs, namedArgs),
          'run': (visitor, positionalArgs, namedArgs) =>
              _run(positionalArgs, namedArgs),
          'runSync': (visitor, positionalArgs, namedArgs) =>
              _runSync(positionalArgs, namedArgs),
          'killPid': (visitor, positionalArgs, namedArgs) =>
              _killPid(positionalArgs, namedArgs),
        },
        methods: {
          'kill': (visitor, target, positionalArgs, namedArgs) =>
              _kill(target, positionalArgs, namedArgs),
        },
        getters: {
          'exitCode': (visitor, target) => (target as Process).exitCode,
          'pid': (visitor, target) => (target as Process).pid,
          'stdin': (visitor, target) => (target as Process).stdin,
          'stdout': (visitor, target) => (target as Process).stdout,
          'stderr': (visitor, target) => (target as Process).stderr,
        },
      );

  static Future<Process> _start(
      List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) async {
    if (positionalArgs.isEmpty) {
      throw ArgumentError('Process.start requires executable path');
    }

    final executable = positionalArgs[0].toString();
    final arguments = positionalArgs.length > 1
        ? (positionalArgs[1] as List).map((e) => e.toString()).toList()
        : <String>[];

    final workingDirectory = namedArgs['workingDirectory']?.toString();
    final environment = namedArgs['environment'] as Map?;
    final includeParentEnvironment =
        namedArgs['includeParentEnvironment'] as bool? ?? true;
    final runInShell = namedArgs['runInShell'] as bool? ?? false;
    final mode = namedArgs['mode'] ?? ProcessStartMode.normal;

    return await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment?.cast(),
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      mode: mode,
    );
  }

  static Future<ProcessResult> _run(
      List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) async {
    if (positionalArgs.isEmpty) {
      throw ArgumentError('Process.run requires executable path');
    }

    final executable = positionalArgs[0].toString();
    final arguments = positionalArgs.length > 1
        ? (positionalArgs[1] as List).map((e) => e.toString()).toList()
        : <String>[];

    final workingDirectory = namedArgs['workingDirectory']?.toString();
    final environment = namedArgs['environment'] as Map?;
    final includeParentEnvironment =
        namedArgs['includeParentEnvironment'] as bool? ?? true;
    final runInShell = namedArgs['runInShell'] as bool? ?? false;
    final stdoutEncoding =
        namedArgs['stdoutEncoding'] as Encoding? ?? systemEncoding;
    final stderrEncoding =
        namedArgs['stderrEncoding'] as Encoding? ?? systemEncoding;

    return await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment?.cast(),
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding,
    );
  }

  static ProcessResult _runSync(
      List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) {
    if (positionalArgs.isEmpty) {
      throw ArgumentError('Process.runSync requires executable path');
    }

    final executable = positionalArgs[0].toString();
    final arguments = positionalArgs.length > 1
        ? (positionalArgs[1] as List).map((e) => e.toString()).toList()
        : <String>[];

    final workingDirectory = namedArgs['workingDirectory']?.toString();
    final environment = namedArgs['environment'] as Map?;
    final includeParentEnvironment =
        namedArgs['includeParentEnvironment'] as bool? ?? true;
    final runInShell = namedArgs['runInShell'] as bool? ?? false;
    final stdoutEncoding =
        namedArgs['stdoutEncoding'] as Encoding? ?? systemEncoding;
    final stderrEncoding =
        namedArgs['stderrEncoding'] as Encoding? ?? systemEncoding;

    return Process.runSync(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment?.cast(),
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding,
    );
  }

  static bool _killPid(
      List<dynamic> positionalArgs, Map<String, dynamic> namedArgs) {
    if (positionalArgs.isEmpty) {
      throw ArgumentError('Process.killPid requires pid');
    }

    final pid = positionalArgs[0] as int;
    final signal = namedArgs['signal'] ?? ProcessSignal.sigterm;

    return Process.killPid(pid, signal);
  }

  static bool _kill(dynamic instance, List<dynamic> positionalArgs,
      Map<String, dynamic> namedArgs) {
    if (instance is! Process) {
      throw ArgumentError('Invalid process instance');
    }

    final signal = namedArgs['signal'] ?? ProcessSignal.sigterm;
    return instance.kill(signal);
  }
}

/// Bridged implementation of ProcessResult
class ProcessResultIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: ProcessResult,
        name: 'ProcessResult',
        typeParameterCount: 0,
        getters: {
          'exitCode': (visitor, target) => (target as ProcessResult).exitCode,
          'pid': (visitor, target) => (target as ProcessResult).pid,
          'stdout': (visitor, target) => (target as ProcessResult).stdout,
          'stderr': (visitor, target) => (target as ProcessResult).stderr,
        },
      );
}

/// Bridged implementation of ProcessSignal
class ProcessSignalIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: ProcessSignal,
        name: 'ProcessSignal',
        typeParameterCount: 0,
        staticGetters: {
          'sighup': (visitor) => ProcessSignal.sighup,
          'sigint': (visitor) => ProcessSignal.sigint,
          'sigquit': (visitor) => ProcessSignal.sigquit,
          'sigill': (visitor) => ProcessSignal.sigill,
          'sigtrap': (visitor) => ProcessSignal.sigtrap,
          'sigabrt': (visitor) => ProcessSignal.sigabrt,
          'sigbus': (visitor) => ProcessSignal.sigbus,
          'sigfpe': (visitor) => ProcessSignal.sigfpe,
          'sigkill': (visitor) => ProcessSignal.sigkill,
          'sigusr1': (visitor) => ProcessSignal.sigusr1,
          'sigsegv': (visitor) => ProcessSignal.sigsegv,
          'sigusr2': (visitor) => ProcessSignal.sigusr2,
          'sigpipe': (visitor) => ProcessSignal.sigpipe,
          'sigalrm': (visitor) => ProcessSignal.sigalrm,
          'sigterm': (visitor) => ProcessSignal.sigterm,
          'sigchld': (visitor) => ProcessSignal.sigchld,
          'sigcont': (visitor) => ProcessSignal.sigcont,
          'sigstop': (visitor) => ProcessSignal.sigstop,
          'sigtstp': (visitor) => ProcessSignal.sigtstp,
          'sigttin': (visitor) => ProcessSignal.sigttin,
          'sigttou': (visitor) => ProcessSignal.sigttou,
          'sigurg': (visitor) => ProcessSignal.sigurg,
          'sigxcpu': (visitor) => ProcessSignal.sigxcpu,
          'sigxfsz': (visitor) => ProcessSignal.sigxfsz,
          'sigvtalrm': (visitor) => ProcessSignal.sigvtalrm,
          'sigprof': (visitor) => ProcessSignal.sigprof,
          'sigwinch': (visitor) => ProcessSignal.sigwinch,
          'sigpoll': (visitor) => ProcessSignal.sigpoll,
          'sigsys': (visitor) => ProcessSignal.sigsys,
        },
        getters: {
          'name': (visitor, target) => (target as ProcessSignal).name,
          'runtimeType': (visitor, target) =>
              (target as ProcessSignal).runtimeType,
          'hashCode': (visitor, target) => (target as ProcessSignal).hashCode,
        },
        methods: {
          'watch': (visitor, target, positionalArgs, namedArgs) =>
              (target as ProcessSignal).watch(),
          'toString': (visitor, target, positionalArgs, namedArgs) =>
              (target as ProcessSignal).toString(),
        },
      );
}

/// Bridged implementation of ProcessStartMode
class ProcessStartModeIo {
  static BridgedClass get definition => BridgedClass(
        nativeType: ProcessStartMode,
        name: 'ProcessStartMode',
        typeParameterCount: 0,
        staticGetters: {
          'normal': (visitor) => ProcessStartMode.normal,
          'inheritStdio': (visitor) => ProcessStartMode.inheritStdio,
          'detached': (visitor) => ProcessStartMode.detached,
          'detachedWithStdio': (visitor) => ProcessStartMode.detachedWithStdio,
        },
      );
}
