import '../../interpreter_test.dart';
import 'package:test/test.dart';

void main() {
  group('Uri methods - comprehensive', () {
    test('toString', () {
      const source = '''
      main() {
        Uri uri = Uri.parse("https://example.com/path?query=value#fragment");
        return uri.toString();
      }
      ''';
      expect(execute(source),
          equals('https://example.com/path?query=value#fragment'));
    });

    test('host', () {
      const source = '''
      main() {
        Uri uri = Uri.parse("https://example.com/path");
        return uri.host;
      }
      ''';
      expect(execute(source), equals('example.com'));
    });

    test('port', () {
      const source = '''
      main() {
        Uri uri = Uri.parse("https://example.com:8080/path");
        return uri.port;
      }
      ''';
      expect(execute(source), equals(8080));
    });

    test('scheme', () {
      const source = '''
      main() {
        Uri uri = Uri.parse("https://example.com/path");
        return uri.scheme;
      }
      ''';
      expect(execute(source), equals('https'));
    });

    test('path', () {
      const source = '''
      main() {
        Uri uri = Uri.parse("https://example.com/path/to/resource");
        return uri.path;
      }
      ''';
      expect(execute(source), equals('/path/to/resource'));
    });

    test('query', () {
      const source = '''
      main() {
        Uri uri = Uri.parse("https://example.com/path?query=value");
        return uri.query;
      }
      ''';
      expect(execute(source), equals('query=value'));
    });

    test('fragment', () {
      const source = '''
      main() {
        Uri uri = Uri.parse("https://example.com/path#fragment");
        return uri.fragment;
      }
      ''';
      expect(execute(source), equals('fragment'));
    });

    test('encodeComponent', () {
      const source = '''
      main() {
        return Uri.encodeComponent("hello world");
      }
      ''';
      expect(execute(source), equals('hello%20world'));
    });

    test('decodeComponent', () {
      const source = '''
      main() {
        return Uri.decodeComponent("hello%20world");
      }
      ''';
      expect(execute(source), equals('hello world'));
    });

    test('encodeQueryComponent', () {
      const source = '''
      main() {
        return Uri.encodeQueryComponent("key=value");
      }
      ''';
      expect(execute(source), equals('key%3Dvalue'));
    });

    test('decodeQueryComponent', () {
      const source = '''
      main() {
        return Uri.decodeQueryComponent("key%3Dvalue");
      }
      ''';
      expect(execute(source), equals('key=value'));
    });

    test('encodeFull', () {
      const source = '''
      main() {
        return Uri.encodeFull("https://example.com/path?query=value#fragment");
      }
      ''';
      expect(execute(source),
          equals('https://example.com/path?query=value#fragment'));
    });

    test('decodeFull', () {
      const source = '''
      main() {
        return Uri.decodeFull("https%3A%2F%2Fexample.com%2Fpath%3Fquery%3Dvalue%23fragment");
      }
      ''';
      expect(execute(source),
          equals('https://example.com/path?query=value#fragment'));
    });

    test('splitQueryString', () {
      const source = '''
      main() {
        Map<String, String> queryParams = Uri.splitQueryString("key1=value1&key2=value2");
        return queryParams;
      }
      ''';
      expect(execute(source), equals({'key1': 'value1', 'key2': 'value2'}));
    });

    test('queryParametersAll', () {
      const source = '''
      main() {
        Uri uri = Uri.parse("https://example.com/path?key=value&key=value2");
        return uri.queryParametersAll;
      }
      ''';
      expect(
          execute(source),
          equals({
            'key': ['value', 'value2']
          }));
    });

    test('https', () {
      const source = '''
      main() {
        Uri uri = Uri.https("example.com", "/path", {"query": "value"});
        return uri.toString();
      }
      ''';
      expect(execute(source), equals('https://example.com/path?query=value'));
    });

    test('http', () {
      const source = '''
      main() {
        Uri uri = Uri.http("example.com", "/path", {"query": "value"});
        return uri.toString();
      }
      ''';
      expect(execute(source), equals('http://example.com/path?query=value'));
    });

    test('file', () {
      const source = '''
      main() {
        Uri uri = Uri.file("/path/to/file");
        return uri.toString();
      }
      ''';
      expect(execute(source), equals('file:///path/to/file'));
    });

    test('directory', () {
      const source = '''
      main() {
        Uri uri = Uri.directory("/path/to/directory");
        return uri.toString();
      }
      ''';
      expect(execute(source), equals('file:///path/to/directory/'));
    });

    test('dataFromBytes', () {
      const source = '''
      main() {
        Uri uri = Uri.dataFromBytes([104, 101, 108, 108, 111]);
        return uri.toString();
      }
      ''';
      expect(execute(source),
          equals('data:application/octet-stream;base64,aGVsbG8='));
    });

    test('dataFromString', () {
      const source = '''
      main() {
        Uri uri = Uri.dataFromString("hello");
        return uri.toString();
      }
      ''';
      expect(execute(source), equals('data:;charset=utf-8,hello'));
    });

    test('parse', () {
      const source = '''
      main() {
        Uri uri = Uri.parse("https://example.com/path");
        return uri.toString();
      }
      ''';
      expect(execute(source), equals('https://example.com/path'));
    });

    test('tryParse', () {
      const source = '''
      main() {
        Uri? uri = Uri.tryParse("https://example.com/path");
        return uri?.toString();
      }
      ''';
      expect(execute(source), equals('https://example.com/path'));
    });
  });
}
