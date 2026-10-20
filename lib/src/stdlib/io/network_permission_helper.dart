import 'package:d4rt/d4rt.dart';

/// Requires a [NetworkPermission] allowing a connection to [host]:[port].
void checkNetworkConnectPermission(
  InterpreterVisitor visitor,
  Object? host,
  int port,
) {
  _checkNetworkPermission(
    visitor,
    host: host?.toString(),
    port: port,
    connect: true,
    action: 'connect to',
  );
}

/// Requires a [NetworkPermission] allowing a DNS lookup for [host].
void checkNetworkLookupPermission(InterpreterVisitor visitor, Object? host) {
  _checkNetworkPermission(
    visitor,
    host: host?.toString(),
    connect: true,
    action: 'resolve',
  );
}

/// Requires a [NetworkPermission] allowing a server to listen on
/// [host]:[port].
void checkNetworkListenPermission(
  InterpreterVisitor visitor,
  Object? host,
  int port,
) {
  _checkNetworkPermission(
    visitor,
    host: host?.toString(),
    port: port,
    listen: true,
    allowBindFallback: true,
    action: 'listen on',
  );
}

/// Requires any network permission (used for local network inspection).
void checkNetworkInspectionPermission(InterpreterVisitor visitor) {
  _checkNetworkPermission(visitor, action: 'inspect network interfaces');
}

void _checkNetworkPermission(
  InterpreterVisitor visitor, {
  String? host,
  int? port,
  bool connect = false,
  bool listen = false,
  bool allowBindFallback = false,
  required String action,
}) {
  final d4rt = visitor.moduleLoader.d4rt;
  if (d4rt == null) return;

  if ((connect || listen) && host == null) {
    throw RuntimeError('Network $action requires a host.');
  }

  final operation = <String, dynamic>{'type': 'network'};
  if (host != null) operation['host'] = host;
  if (port != null) operation['port'] = port;
  if (connect) operation['connect'] = true;
  if (listen) operation['listen'] = true;

  if (d4rt.checkPermission(operation)) return;

  // Server binds are both a bind and a listen operation in dart:io. Accept
  // either capability so NetworkPermission.bind remains meaningful.
  if (allowBindFallback) {
    final bindOperation = <String, dynamic>{
      ...operation,
      'listen': false,
      'bind': true,
    };
    if (d4rt.checkPermission(bindOperation)) return;
  }

  final target = host == null
      ? ''
      : port == null
      ? ' $host'
      : ' $host:$port';
  throw RuntimeError(
    'Network permission denied to $action$target. '
    'Grant an appropriate NetworkPermission for this destination.',
  );
}
