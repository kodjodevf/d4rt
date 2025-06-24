import 'package:d4rt/src/environment.dart';
import 'package:d4rt/src/stdlib/math/math.dart';
import 'package:d4rt/src/stdlib/math/point.dart';
import 'package:d4rt/src/stdlib/math/rectangle.dart';
import 'package:d4rt/src/stdlib/math/random.dart';

export 'package:d4rt/src/environment.dart';
export 'package:d4rt/src/stdlib/math/math.dart';
export 'package:d4rt/src/stdlib/math/point.dart';
export 'package:d4rt/src/stdlib/math/rectangle.dart';
export 'package:d4rt/src/stdlib/math/random.dart';

class MathStdlib {
  static void register(Environment environment) {
    MathMath.register(environment);
    environment.defineBridge(RandomMath.definition);
    environment.defineBridge(PointMath.definition);
    environment.defineBridge(RectangleMath.definition);
  }
}
