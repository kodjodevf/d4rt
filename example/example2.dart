import 'package:d4rt/d4rt.dart';

enum Status {
  success(200),
  notFound(404),
  error(500);

  final int code;
  const Status(this.code);
  bool get isError => code >= 400;
  String describe() => 'Status $name ($code)';
}

final statusEnumBridge = BridgedEnumDefinition<Status>(
  name: 'Status',
  values: Status.values,
  methods: {
    'describe': (visitor, target, positionalArgs, namedArgs) =>
        (target as Status).describe(),
  },
  getters: {
    'code': (visitor, target) => (target as Status).code,
    'isError': (visitor, target) => (target as Status).isError,
  },
);

void main() {
  final interpreter = D4rt();
  interpreter.registerBridgedEnum(statusEnumBridge);

  final code = '''
    main() {
      var s = Status.error;
      return [s.code, s.isError, s.describe()];
    }
  ''';

  final result = interpreter.execute(code);
  print(result); // [500, true, Status error (500)]
}
