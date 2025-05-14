import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

void main() {
  group('Export Tests', () {
    test('Simple export: main imports B, B exports A', () {
      final Map<String, String> sources = {
        "d4rt-mem:/lib_A.dart": """
        String funcA() {
          return "Hello from funcA in lib_A";
        }
        String varA = "Variable A";
        """,
        "d4rt-mem:/lib_B.dart": """
        export 'lib_A.dart';
        String funcB() {
          return "Hello from funcB in lib_B";
        }
        """,
        "d4rt-mem:/main_export_test.dart": """
        import 'lib_B.dart';

        String main() {
          return funcA() + " | " + varA + " | " + funcB();
        }
        """,
      };

      final d4rt = D4rt();

      final result = d4rt.execute(
        library: "d4rt-mem:/main_export_test.dart",
        sources: sources,
      );
      expect(
          result,
          equals(
              "Hello from funcA in lib_A | Variable A | Hello from funcB in lib_B"));
    });

    test('Export with show: main imports B, B exports A show funcA, funcCommon',
        () {
      final Map<String, String> sources = {
        "d4rt-mem:/lib_A_common.dart": """
        String funcA() { return "funcA_val"; }
        String varA = "varA_val";
        String funcCommon() { return "funcCommon_val"; }
        """,
        "d4rt-mem:/lib_B_show.dart": """
        export 'lib_A_common.dart' show funcA, funcCommon;
        String funcB() { return "funcB_val"; }
        """,
        "d4rt-mem:/main_show_test.dart": """
        import 'lib_B_show.dart';

        String main() {
          String result = funcB();
          result += " | " + funcA();
          result += " | " + funcCommon();
          return result;
        }
        """,
      };
      final d4rt = D4rt();
      final result = d4rt.execute(
        library: "d4rt-mem:/main_show_test.dart",
        sources: sources,
      );
      expect(result, equals("funcB_val | funcA_val | funcCommon_val"));

      final mainVarAUriString = "d4rt-mem:/main_varA_access_show.dart";
      sources[mainVarAUriString] = """
      import 'lib_B_show.dart';
      String main() {
        return varA;
      }
      """;
      final d4rt2 = D4rt();
      expect(
        () => d4rt2.execute(library: mainVarAUriString, sources: sources),
        throwsA(isA<RuntimeError>().having(
            (e) => e.message, 'message', contains('Undefined variable: varA'))),
      );
    });

    test('Export with hide: main imports B, B exports A hide varA', () {
      final Map<String, String> sources = {
        "d4rt-mem:/lib_A_common.dart": """
        String funcA() { return "funcA_val"; }
        String varA = "varA_val";
        String funcCommon() { return "funcCommon_val"; }
        """,
        "d4rt-mem:/lib_B_hide.dart": """
        export 'lib_A_common.dart' hide varA;
        String funcB() { return "funcB_val"; }
        """,
        "d4rt-mem:/main_hide_test.dart": """
        import 'lib_B_hide.dart';

        String main() {
          String result = funcB();
          result += " | " + funcA();
          result += " | " + funcCommon();
          return result;
        }
        """,
      };
      final d4rt = D4rt();
      final result = d4rt.execute(
        library: "d4rt-mem:/main_hide_test.dart",
        sources: sources,
      );
      expect(result, equals("funcB_val | funcA_val | funcCommon_val"));

      final mainVarAUriString = "d4rt-mem:/main_varA_access_hide.dart";
      sources[mainVarAUriString] = """
      import 'lib_B_hide.dart';
      String main() {
        return varA;
      }
      """;
      final d4rt2 = D4rt();
      expect(
        () => d4rt2.execute(library: mainVarAUriString, sources: sources),
        throwsA(isA<RuntimeError>().having(
            (e) => e.message, 'message', contains('Undefined variable: varA'))),
      );
    });

    test(
        'Chained export: main imports E, E exports D (show c1,c2), D exports C (c1,c2,c3) -> E hides c2 from D',
        () {
      final Map<String, String> sources = {
        "d4rt-mem:/lib_C.dart": """
        String c1() { return "c1_val"; }
        String c2() { return "c2_val"; }
        String c3() { return "c3_val"; }
        """,
        "d4rt-mem:/lib_D_exports_C_show.dart": """
        export 'lib_C.dart' show c1, c2;
        String d_only() { return "d_val"; }
        """,
        "d4rt-mem:/lib_E_exports_D_hide.dart": """
        export 'lib_D_exports_C_show.dart' hide c2, d_only;
        """,
        "d4rt-mem:/main_chained_export_test.dart": """
        import 'lib_E_exports_D_hide.dart';

        String main() {
          return c1();
        }
        """,
      };
      final d4rt = D4rt();
      final result = d4rt.execute(
        library: "d4rt-mem:/main_chained_export_test.dart",
        sources: sources,
      );
      expect(result, equals("c1_val"));

      final mainC2UriString = "d4rt-mem:/main_c2_access.dart";
      sources[mainC2UriString] = """
      import 'lib_E_exports_D_hide.dart';
      String main() {
        return c2();
      }
      """;
      final d4rt2 = D4rt();
      expect(
        () => d4rt2.execute(library: mainC2UriString, sources: sources),
        throwsA(isA<RuntimeError>().having(
            (e) => e.message, 'message', contains('Undefined variable: c2'))),
      );

      final mainC3UriString = "d4rt-mem:/main_c3_access.dart";
      sources[mainC3UriString] = """
      import 'lib_E_exports_D_hide.dart';
      String main() {
        return c3();
      }
      """;
      final d4rt3 = D4rt();
      expect(
        () => d4rt3.execute(library: mainC3UriString, sources: sources),
        throwsA(isA<RuntimeError>().having(
            (e) => e.message, 'message', contains('Undefined variable: c3'))),
      );

      final mainDOnlyUriString = "d4rt-mem:/main_d_only_access.dart";
      sources[mainDOnlyUriString] = """
      import 'lib_E_exports_D_hide.dart';
      String main() {
        return d_only();
      }
      """;
      final d4rt4 = D4rt();
      expect(
        () => d4rt4.execute(library: mainDOnlyUriString, sources: sources),
        throwsA(isA<RuntimeError>().having((e) => e.message, 'message',
            contains('Undefined variable: d_only'))),
      );
    });

    test('Export conflict: local declaration vs. exported symbol', () {
      final Map<String, String> sources = {
        "d4rt-mem:/lib_Other_conflict.dart": """
      String commonName() { return "Hello from Other commonName"; }
      """,
        "d4rt-mem:/main_local_export_conflict.dart": """
      export 'lib_Other_conflict.dart';
      String commonName() { return "Hello from Local commonName"; }

      String main() { 
        return commonName(); 
      }
      """,
      };

      final d4rt = D4rt();
      expect(
        () => d4rt.execute(
          library: "d4rt-mem:/main_local_export_conflict.dart",
          sources: sources,
        ),
        throwsA(isA<RuntimeError>().having(
            (e) => e.message,
            'message',
            contains(
                "Name conflict in environment: Symbol 'commonName' is already defined"))),
      );
    });

    test('Export conflict: two different exports define the same symbol', () {
      final Map<String, String> sources = {
        "d4rt-mem:/lib_X.dart": """
      String conflictingSymbol() { return "from lib_X"; }
      """,
        "d4rt-mem:/lib_Y.dart": """
      String conflictingSymbol() { return "from lib_Y"; }
      """,
        "d4rt-mem:/main_two_exports_conflict.dart": """
      export 'lib_X.dart';
      export 'lib_Y.dart';

      String main() { 
        return conflictingSymbol();
      }
      """,
      };
      final d4rt = D4rt();
      expect(
        () => d4rt.execute(
          library: "d4rt-mem:/main_two_exports_conflict.dart",
          sources: sources,
        ),
        throwsA(isA<RuntimeError>().having(
            (e) => e.message,
            'message',
            contains(
                "Name conflict in environment: Symbol 'conflictingSymbol' is already defined"))),
      );
    });
  });
}
