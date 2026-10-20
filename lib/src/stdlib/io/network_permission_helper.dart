import 'package:d4rt/d4rt.dart';

/// Requires a [NetworkPermission] allowing a connection to [host]:[port].
void checkNetworkConnectPermission(
  InterpreterVisitor visitor,
  Object? host,
  int port, {
  String action = 'connect to',
}) {
  _checkNetworkPermission(
    visitor,
    host: host?.toString(),
    port: port,
    connect: true,
    action: action,
  );
}

/// Requires permission for every proxy endpoint returned by a `findProxy`
/// callback. Rules are semicolon-separated and `DIRECT` needs no proxy access.
void checkNetworkProxyPermission(
  InterpreterVisitor visitor,
  String proxyRules,
) {
  final rules = proxyRules.trim();
  if (rules.isEmpty) return;

  for (final rawRule in rules.split(';')) {
    final rule = rawRule.trim();
    if (rule.isEmpty) continue;
    if (rule.toUpperCase() == 'DIRECT') continue;

    final parts = rule.split(RegExp(r'\s+'));
    if (parts.length != 2) {
      throw RuntimeError(
        'Invalid HTTP proxy rule "$rule". Expected "DIRECT" or '
        '"PROXY host:port".',
      );
    }

    final endpoint = _parseProxyEndpoint(parts[1]);
    if (endpoint == null) {
      throw RuntimeError(
        'Invalid HTTP proxy endpoint "${parts[1]}". Expected host:port.',
      );
    }

    checkNetworkConnectPermission(
      visitor,
      endpoint.host,
      endpoint.port,
      action: 'connect to proxy',
    );
  }
}

({String host, int port})? _parseProxyEndpoint(String endpoint) {
  String host;
  String portText;

  if (endpoint.startsWith('[')) {
    final closingBracket = endpoint.indexOf(']');
    if (closingBracket <= 1 ||
        closingBracket + 1 >= endpoint.length ||
        endpoint[closingBracket + 1] != ':') {
      return null;
    }
    host = endpoint.substring(1, closingBracket);
    portText = endpoint.substring(closingBracket + 2);
  } else {
    final separator = endpoint.lastIndexOf(':');
    if (separator <= 0 || separator == endpoint.length - 1) return null;
    host = endpoint.substring(0, separator);
    if (host.contains(':')) return null;
    portText = endpoint.substring(separator + 1);
  }

  final port = int.tryParse(portText);
  if (host.isEmpty || port == null || port < 1 || port > 65535) {
    return null;
  }
  return (host: host, port: port);
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
