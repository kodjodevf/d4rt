import 'package:d4rt/d4rt.dart';
import 'package:test/test.dart';

void main() {
  group('Convert Features, Error Bridges and Subtyping Tests', () {
    late D4rt d4rt;

    setUp(() {
      d4rt = D4rt();
    });

    test('HtmlEscapeMode static getters and modes', () {
      final result = d4rt.execute(source: '''
        import 'dart:convert';

        main() {
          final attrMode = HtmlEscapeMode.attribute;
          final elemMode = HtmlEscapeMode.element;
          final sqMode = HtmlEscapeMode.sqAttribute;
          final unkMode = HtmlEscapeMode.unknown;

          final escaper = HtmlEscape(HtmlEscapeMode.attribute);
          final escaped = escaper.convert('<foo & "bar">');

          final isMode = attrMode is HtmlEscapeMode;
          final isConverter = escaper is Converter;

          return [
            escaped,
            isMode,
            isConverter,
            attrMode.escapeQuot,
            elemMode.escapeLtGt,
            sqMode.escapeApos,
            unkMode.escapeSlash,
          ];
        }
      ''') as List;

      expect(result[0], equals('&lt;foo &amp; &quot;bar&quot;&gt;'));
      expect(result[1], isTrue);
      expect(result[2], isTrue);
      expect(result[3], isTrue);
      expect(result[4], isTrue);
      expect(result[5], isTrue);
      expect(result[6], isTrue);
    });

    test('JsonUnsupportedObjectError bridge and properties', () {
      final result = d4rt.execute(source: '''
        import 'dart:convert';

        main() {
          final unsupp = Object();
          final err = JsonUnsupportedObjectError(unsupp, cause: 'custom cause');
          final isError = err is Error;
          final isJsonError = err is JsonUnsupportedObjectError;
          return [
            isError,
            isJsonError,
            err.cause,
            err.toString(),
          ];
        }
      ''') as List;

      expect(result[0], isTrue);
      expect(result[1], isTrue);
      expect(result[2], equals('custom cause'));
      expect(result[3], contains('Converting object to an encodable object failed: Instance of \'Object\''));
    });

    test('Codec, Converter, and Encoding subtyping', () {
      final result = d4rt.execute(source: '''
        import 'dart:async';
        import 'dart:convert';

        main() {
          final isUtf8Codec = utf8 is Utf8Codec;
          final isUtf8Encoding = utf8 is Encoding;
          final isUtf8AsCodec = utf8 is Codec;
          final isJsonAsCodec = json is JsonCodec;
          final isBase64AsCodec = base64 is Base64Codec;
          final isLineSplitterStreamTransformer = LineSplitter() is StreamTransformer;
          final isEncoderConverter = utf8.encoder is Converter;
          final isDecoderConverter = utf8.decoder is Converter;

          return [
            isUtf8Codec,
            isUtf8Encoding,
            isUtf8AsCodec,
            isJsonAsCodec,
            isBase64AsCodec,
            isLineSplitterStreamTransformer,
            isEncoderConverter,
            isDecoderConverter,
          ];
        }
      ''') as List;

      expect(result[0], isTrue);
      expect(result[1], isTrue);
      expect(result[2], isTrue);
      expect(result[3], isTrue);
      expect(result[4], isTrue);
      expect(result[5], isTrue);
      expect(result[6], isTrue);
      expect(result[7], isTrue);
    });
  });
}
