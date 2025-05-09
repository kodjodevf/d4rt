import 'package:d4rt/d4rt.dart';

class User {
  String name;
  int _age;
  User(this.name, this._age);
  User.guest()
      : name = 'Guest',
        _age = 0;

  // ignore: unnecessary_getters_setters
  int get age => _age;
  set age(int v) => _age = v;

  static String staticHello() => 'Hello from static!';

  Future<String> fetchProfile() async => 'Profile of $name';

  String greet({String? prefix}) => '${prefix ?? 'Hi'}, $name!';
}

final userBridge = BridgedClassDefinition(
  nativeType: User,
  name: 'User',
  constructors: {
    '': (visitor, positionalArgs, namedArgs) => User(
          positionalArgs[0] as String,
          positionalArgs[1] as int,
        ),
    'guest': (visitor, positionalArgs, namedArgs) => User.guest(),
  },
  methods: {
    'greet': (visitor, target, positionalArgs, namedArgs) =>
        (target as User).greet(prefix: namedArgs['prefix'] as String?),
    'fetchProfile': (visitor, target, positionalArgs, namedArgs) =>
        (target as User).fetchProfile(), // async supported
  },
  getters: {
    'name': (visitor, target) => (target as User).name,
    'age': (visitor, target) => (target as User).age,
  },
  setters: {
    'age': (visitor, target, value) => (target as User).age = value as int,
  },
  staticMethods: {
    'staticHello': (visitor, positionalArgs, namedArgs) => User.staticHello(),
  },
);

void main() async {
  final interpreter = D4rt();
  interpreter.registerBridgedClass(userBridge);

  final code = '''
    main() async {
      var u = User('Alice', 30);
      u.age = 31;
      var greet = u.greet(prefix: 'Hello');
      var profile = await u.fetchProfile();
      var guest = User.guest();
      var staticMsg = User.staticHello();
      return [greet, profile, guest.name, staticMsg];
    }
  ''';

  final result = await interpreter.execute(code);
  print(result); // [Hello, Alice!, Profile of Alice, Guest, Hello from static!]
}
