import 'package:test/test.dart';
import '../../interpreter_test.dart' show executeAsync;

void main() {
  group('StreamTransformer Tests', () {
    test('StreamTransformer.fromHandlers with handleData', () async {
      const code = '''
import 'dart:async';

main() async {
  final controller = StreamController<int>();
  
  // Create a transformer that doubles each value
  final transformer = StreamTransformer<int, int>.fromHandlers(
    handleData: (data, sink) {
      sink.add(data * 2);
    }
  );
  
  final transformedStream = controller.stream.transform(transformer);
  
  final results = <int>[];
  transformedStream.listen((value) {
    results.add(value);
  });
  
  controller.add(1);
  controller.add(2);
  controller.add(3);
  await controller.close();
  
  // Small delay to ensure all events are processed
  await Future.delayed(Duration(milliseconds: 10));
  
  return results;
}
''';
      final result = await executeAsync(code);
      expect(result, equals([2, 4, 6]));
    });

    test('StreamTransformer.fromHandlers with handleError', () async {
      const code = '''
import 'dart:async';

main() async {
  final controller = StreamController<int>();
  
  // Create a transformer that catches errors
  final transformer = StreamTransformer<int, String>.fromHandlers(
    handleData: (data, sink) {
      if (data < 0) {
        throw Exception('Negative value');
      }
      sink.add('Value: \$data');
    },
    handleError: (error, stackTrace, sink) {
      sink.add('Error caught: \${error.toString()}');
    }
  );
  
  final transformedStream = controller.stream.transform(transformer);
  
  final results = <String>[];
  transformedStream.listen((value) {
    results.add(value);
  });
  
  controller.add(1);
  controller.addError(Exception('Test error'));
  controller.add(2);
  await controller.close();
  
  await Future.delayed(Duration(milliseconds: 10));
  
  return results.length >= 2; // At least data and error
}
''';
      final result = await executeAsync(code);
      expect(result, equals(true));
    });

    test('StreamTransformer.fromHandlers with handleDone', () async {
      const code = '''
import 'dart:async';

main() async {
  final controller = StreamController<int>();
  bool doneCalled = false;
  
  // Create a transformer that handles stream completion
  final transformer = StreamTransformer<int, int>.fromHandlers(
    handleData: (data, sink) {
      sink.add(data);
    },
    handleDone: (sink) {
      doneCalled = true;
      sink.close();
    }
  );
  
  final transformedStream = controller.stream.transform(transformer);
  
  transformedStream.listen((value) {});
  
  controller.add(1);
  await controller.close();
  
  await Future.delayed(Duration(milliseconds: 10));
  
  return doneCalled;
}
''';
      final result = await executeAsync(code);
      expect(result, equals(true));
    });

    test('StreamTransformer.fromHandlers - filtering transformer', () async {
      const code = '''
import 'dart:async';

main() async {
  final controller = StreamController<int>();
  
  // Create a transformer that filters even numbers
  final transformer = StreamTransformer<int, int>.fromHandlers(
    handleData: (data, sink) {
      if (data % 2 == 0) {
        sink.add(data);
      }
    }
  );
  
  final transformedStream = controller.stream.transform(transformer);
  
  final results = <int>[];
  transformedStream.listen((value) {
    results.add(value);
  });
  
  controller.add(1);
  controller.add(2);
  controller.add(3);
  controller.add(4);
  controller.add(5);
  await controller.close();
  
  await Future.delayed(Duration(milliseconds: 10));
  
  return results;
}
''';
      final result = await executeAsync(code);
      expect(result, equals([2, 4]));
    });

    test('StreamTransformer.fromHandlers - mapping to different type',
        () async {
      const code = '''
import 'dart:async';

main() async {
  final controller = StreamController<int>();
  
  // Transform int to String
  final transformer = StreamTransformer<int, String>.fromHandlers(
    handleData: (data, sink) {
      sink.add('Number: \$data');
    }
  );
  
  final transformedStream = controller.stream.transform(transformer);
  
  final results = <String>[];
  transformedStream.listen((value) {
    results.add(value);
  });
  
  controller.add(1);
  controller.add(2);
  await controller.close();
  
  await Future.delayed(Duration(milliseconds: 10));
  
  return results;
}
''';
      final result = await executeAsync(code);
      expect(result, equals(['Number: 1', 'Number: 2']));
    });

    test('StreamTransformer.fromBind - custom stream binding', () async {
      const code = '''
import 'dart:async';

main() async {
  // Create a transformer using fromBind
  final transformer = StreamTransformer<int, int>.fromBind((stream) {
    return stream.map((value) => value * 3);
  });
  
  final controller = StreamController<int>();
  final transformedStream = controller.stream.transform(transformer);
  
  final results = <int>[];
  transformedStream.listen((value) {
    results.add(value);
  });
  
  controller.add(1);
  controller.add(2);
  controller.add(3);
  await controller.close();
  
  await Future.delayed(Duration(milliseconds: 10));
  
  return results;
}
''';
      final result = await executeAsync(code);
      expect(result, equals([3, 6, 9]));
    });

    test('StreamTransformer.fromBind with async operations', () async {
      const code = '''
import 'dart:async';

main() async {
  // Create a transformer that delays each value
  final transformer = StreamTransformer<int, int>.fromBind((stream) {
    return stream.asyncMap((value) async {
      await Future.delayed(Duration(milliseconds: 1));
      return value + 10;
    });
  });
  
  final controller = StreamController<int>();
  final transformedStream = controller.stream.transform(transformer);
  
  final results = <int>[];
  transformedStream.listen((value) {
    results.add(value);
  });
  
  controller.add(1);
  controller.add(2);
  await controller.close();
  
  await Future.delayed(Duration(milliseconds: 50));
  
  return results;
}
''';
      final result = await executeAsync(code);
      expect(result, equals([11, 12]));
    });

    test('Chained StreamTransformers', () async {
      const code = '''
import 'dart:async';

main() async {
  final controller = StreamController<int>();
  
  // First transformer: double the value
  final doubler = StreamTransformer<int, int>.fromHandlers(
    handleData: (data, sink) {
      sink.add(data * 2);
    }
  );
  
  // Second transformer: add 10
  final adder = StreamTransformer<int, int>.fromHandlers(
    handleData: (data, sink) {
      sink.add(data + 10);
    }
  );
  
  // Chain transformers
  final transformedStream = controller.stream
      .transform(doubler)
      .transform(adder);
  
  final results = <int>[];
  transformedStream.listen((value) {
    results.add(value);
  });
  
  controller.add(1);  // 1 * 2 + 10 = 12
  controller.add(5);  // 5 * 2 + 10 = 20
  await controller.close();
  
  await Future.delayed(Duration(milliseconds: 10));
  
  return results;
}
''';
      final result = await executeAsync(code);
      expect(result, equals([12, 20]));
    });

    test('StreamTransformer with multiple outputs per input', () async {
      const code = '''
import 'dart:async';

main() async {
  final controller = StreamController<int>();
  
  // Transformer that emits multiple values per input
  final transformer = StreamTransformer<int, int>.fromHandlers(
    handleData: (data, sink) {
      // Emit the value and its square
      sink.add(data);
      sink.add(data * data);
    }
  );
  
  final transformedStream = controller.stream.transform(transformer);
  
  final results = <int>[];
  transformedStream.listen((value) {
    results.add(value);
  });
  
  controller.add(2);
  controller.add(3);
  await controller.close();
  
  await Future.delayed(Duration(milliseconds: 10));
  
  return results;
}
''';
      final result = await executeAsync(code);
      expect(result, equals([2, 4, 3, 9]));
    });

    test('StreamTransformer.cast', () async {
      const code = '''
import 'dart:async';

main() async {
  final controller = StreamController<num>();
  
  final transformer = StreamTransformer<num, num>.fromHandlers(
    handleData: (data, sink) {
      sink.add(data);
    }
  );
  
  // Cast transformer to different types
  final castedTransformer = transformer.cast<int, int>();
  
  final intController = StreamController<int>();
  final transformedStream = intController.stream.transform(castedTransformer);
  
  final results = <int>[];
  transformedStream.listen((value) {
    results.add(value);
  });
  
  intController.add(1);
  intController.add(2);
  await intController.close();
  
  await Future.delayed(Duration(milliseconds: 10));
  
  return results;
}
''';
      final result = await executeAsync(code);
      expect(result, equals([1, 2]));
    });
  });
}
