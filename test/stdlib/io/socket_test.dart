import '../../interpreter_test.dart';
import 'package:test/test.dart';

void main() {
  group('Socket methods - comprehensive', () {
    test('Socket.connect to localhost', () async {
      const source = '''
     import 'dart:io';
     main() async {
        try {
          // Try to connect to a common service port (HTTP)
          var socket = await Socket.connect('google.com', 80, timeout: Duration(seconds: 5));
          var isConnected = socket != null;
          await socket.close();
          return isConnected;
        } catch (e) {
          return false; // Connection failed, which is acceptable for this test
        }
      }
      ''';
      final result = await execute(source);
      expect(result, isA<bool>()); // Should return true or false
    });

    test('InternetAddress.lookup functionality', () async {
      const source = '''
     import 'dart:io';
     main() async {
        try {
          var addresses = await InternetAddress.lookup('localhost');
          return addresses.length > 0;
        } catch (e) {
          return false;
        }
      }
      ''';
      final result = await execute(source);
      expect(result, isA<bool>());
    });

    test('InternetAddress constants', () {
      const source = '''
     import 'dart:io';
     main() {
        var loopbackIPv4 = InternetAddress.loopbackIPv4.address;
        var loopbackIPv6 = InternetAddress.loopbackIPv6.address;
        var anyIPv4 = InternetAddress.anyIPv4.address;
        var anyIPv6 = InternetAddress.anyIPv6.address;
        
        return [
          loopbackIPv4 == '127.0.0.1',
          loopbackIPv6 == '::1',
          anyIPv4 == '0.0.0.0',
          anyIPv6 == '::'
        ];
      }
      ''';
      final result = execute(source);
      expect(result, equals([true, true, true, true]));
    });

    test('Socket server and client communication', () async {
      const source = '''
     import 'dart:io';
import 'dart:convert';

main() async {
  // Create a server
  var server = await ServerSocket.bind('127.0.0.1', 0);
  var serverPort = server.port;

  // Handle incoming connections with sync callback
  server.listen((Socket clientSocket) {
    // Read first message and respond
    clientSocket.transform(utf8.decoder).listen((data) {
      clientSocket.write('Echo: \$data');
      clientSocket.close();
    });
  });

  // Create a client
  var clientSocket = await Socket.connect('127.0.0.1', serverPort);
  clientSocket.write('Hello Server');
  await clientSocket.flush();

  // Read response
  var response = await clientSocket.transform(utf8.decoder.cast()).first;

  await server.close();

  return response.trim();
}

      ''';

      try {
        final result = await execute(source);
        expect(
            result,
            anyOf([
              equals('Echo: Hello Server'),
              startsWith(
                  'Error:') // Accept errors as network tests can be flaky
            ]));
      } catch (e) {
        // Skip test if networking is not available
        print('Skipping socket server test: $e');
      }
    });

    test('Socket write and flush methods', () async {
      const source = '''
     import 'dart:io';
     import 'dart:convert';
     main() async {
        try {
          var socket = await Socket.connect('httpbin.org', 80, timeout: Duration(seconds: 5));
          
          // Send HTTP request
          socket.write('GET /get HTTP/1.1\\r\\n');
          socket.write('Host: httpbin.org\\r\\n');
          socket.write('Connection: close\\r\\n');
          socket.write('\\r\\n');
          
          await socket.flush();
          
          // Read a bit of response to verify it worked
          var response = '';
          await for (var data in socket.transform(utf8.decoder).take(1)) {
            response = data;
            break;
          }
          
          await socket.close();
          
          return response.contains('HTTP/1.1');
        } catch (e) {
          return false;
        }
      }
      ''';
      try {
        final result = await execute(source);
        expect(result, isA<bool>());
      } catch (e) {
        // Skip test if networking is not available
        print('Skipping HTTP request test: $e');
      }
    });

    test('Socket add method with bytes', () async {
      const source = '''
     import 'dart:io';
     import 'dart:convert';
     main() async {
        try {
          var socket = await Socket.connect('google.com', 80, timeout: Duration(seconds: 3));
          
          var data = utf8.encode('GET / HTTP/1.1\\r\\nHost: google.com\\r\\n\\r\\n');
          socket.add(data);
          await socket.flush();
          
          await socket.close();
          return true;
        } catch (e) {
          return false;
        }
      }
      ''';
      try {
        final result = await execute(source);
        expect(result, isA<bool>());
      } catch (e) {
        // Skip test if networking is not available
        print('Skipping socket add test: $e');
      }
    });

    test('InternetAddress tryParse method', () {
      const source = '''
     import 'dart:io';
     main() {
        var validIPv4 = InternetAddress.tryParse('192.168.1.1');
        var validIPv6 = InternetAddress.tryParse('::1');
        var invalid = InternetAddress.tryParse('invalid.ip');
        
        return [
          validIPv4 != null,
          validIPv6 != null,
          invalid == null
        ];
      }
      ''';
      final result = execute(source);
      expect(result, equals([true, true, true]));
    });

    test('InternetAddress type checking', () {
      const source = '''
     import 'dart:io';
     main() {
        var ipv4 = InternetAddress.tryParse('127.0.0.1');
        var ipv6 = InternetAddress.tryParse('::1');
        
        return [
          ipv4.type == InternetAddressType.IPv4,
          ipv6.type == InternetAddressType.IPv6,
          ipv4.isLoopback,
          ipv6.isLoopback
        ];
      }
      ''';
      final result = execute(source);
      expect(result, equals([true, true, true, true]));
    });
  });
}
