import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

dynamic execute(String source, {List<Object?>? args}) {
  final d4rt = D4rt();
  d4rt.setDebug(false);
  return d4rt.execute(
      library: 'package:test/main.dart',
      positionalArgs: args,
      sources: {'package:test/main.dart': source});
}

void main() {
  group('Async Constructor Patterns', () {
    test('Static async factory method pattern', () async {
      final code = '''
        import 'dart:async';
        
        class AsyncData {
          final String value;
          
          AsyncData._(this.value);
          
          static Future<AsyncData> create() async {
            final data = await Future.value("async-initialized");
            return AsyncData._(data);
          }
        }
        
        main() async {
          final instance = await AsyncData.create();
          return instance.value;
        }
      ''';

      final result = await execute(code);
      expect(result, equals("async-initialized"));
    });

    test('Async service initialization pattern', () async {
      final code = '''
        import 'dart:async';
        
        class AsyncService {
          final String config;
          final bool isReady;
          
          AsyncService._(this.config, this.isReady);
          
          static Future<AsyncService> initialize(String configName) async {
            final config = await loadConfig(configName);
            return AsyncService._(config, true);
          }
          
          static Future<String> loadConfig(String name) async {
            return "config-for-" + name;
          }
        }
        
        main() async {
          final service = await AsyncService.initialize("production");
          return [service.config, service.isReady];
        }
      ''';

      final result = await execute(code);
      expect(result, equals(["config-for-production", true]));
    });

    test('Database connection async creation pattern', () async {
      final code = '''
        import 'dart:async';
        
        class DatabaseConnection {
          final String connectionString;
          final bool isConnected;
          
          DatabaseConnection._(this.connectionString, this.isConnected);
          
          static Future<DatabaseConnection> connect(String host, int port) async {
            await Future.delayed(Duration(milliseconds: 1)); // Simulate connection
            final connStr = host + ":" + port.toString();
            return DatabaseConnection._(connStr, true);
          }
          
          static Future<DatabaseConnection> connectWithRetry(String host) async {
            // Simulate multiple async operations
            await Future.delayed(Duration(milliseconds: 1));
            final validated = await validateHost(host);
            final connStr = "validated-" + validated;
            return DatabaseConnection._(connStr, true);
          }
          
          static Future<String> validateHost(String host) async {
            return host + "-validated";
          }
        }
        
        main() async {
          final db1 = await DatabaseConnection.connect("localhost", 5432);
          final db2 = await DatabaseConnection.connectWithRetry("remote");
          return [db1.connectionString, db1.isConnected, db2.connectionString];
        }
      ''';

      final result = await execute(code);
      expect(result,
          equals(["localhost:5432", true, "validated-remote-validated"]));
    });

    test('Factory constructor with complex async initialization', () async {
      final code = '''
        import 'dart:async';
        
        class ConfigManager {
          final Map<String, String> config;
          final List<String> loadedModules;
          
          ConfigManager._(this.config, this.loadedModules);
          
          static Future<ConfigManager> initialize() async {
            // Multiple async operations in sequence
            final baseConfig = await loadBaseConfig();
            final modules = await loadModules(baseConfig);
            final finalConfig = await processConfig(baseConfig, modules);
            
            return ConfigManager._(finalConfig, modules);
          }
          
          static Future<Map<String, String>> loadBaseConfig() async {
            await Future.delayed(Duration(milliseconds: 1));
            return {"env": "prod", "version": "1.0"};
          }
          
          static Future<List<String>> loadModules(Map<String, String> config) async {
            await Future.delayed(Duration(milliseconds: 1));
            return ["auth", "database", "cache"];
          }
          
          static Future<Map<String, String>> processConfig(
              Map<String, String> base, List<String> modules) async {
            await Future.delayed(Duration(milliseconds: 1));
            final processed = <String, String>{};
            processed["env"] = base["env"];
            processed["version"] = base["version"];
            processed["modules"] = modules.join(",");
            return processed;
          }
        }
        
        main() async {
          final manager = await ConfigManager.initialize();
          return {
            "config": manager.config,
            "modules": manager.loadedModules
          };
        }
      ''';

      final result = await execute(code);
      expect(result, isA<Map>());
      final resultMap = result as Map;
      expect(
          resultMap["config"],
          equals({
            "env": "prod",
            "version": "1.0",
            "modules": "auth,database,cache"
          }));
      expect(resultMap["modules"], equals(["auth", "database", "cache"]));
    });

    test('Stream-based async constructor pattern', () async {
      final code = '''
        import 'dart:async';
        
        class StreamProcessor {
          final List<String> data;
          final String summary;
          
          StreamProcessor._(this.data, this.summary);
          
          static Future<StreamProcessor> fromStream(Stream<String> stream) async {
            final List<String> collected = await stream.toList();
            final summary = "Processed " + collected.length.toString() + " items";
            return StreamProcessor._(collected, summary);
          }
          
          static Stream<String> createDataStream() {
            return Stream.fromIterable(["item1", "item2", "item3"]);
          }
        }
        
        main() async {
          final stream = StreamProcessor.createDataStream();
          final processor = await StreamProcessor.fromStream(stream);
          return [processor.data, processor.summary];
        }
      ''';

      final result = await execute(code);
      expect(
          result,
          equals([
            ["item1", "item2", "item3"],
            "Processed 3 items"
          ]));
    });

    test('Stream subscription async constructor pattern', () async {
      final code = '''
        import 'dart:async';
        
        class EventCollector {
          final List<String> events;
          final int eventCount;
          
          EventCollector._(this.events, this.eventCount);
          
          static Future<EventCollector> collectEvents(int maxEvents) async {
            final stream = generateEvents();
            final events = await stream.take(maxEvents).toList();
            return EventCollector._(events, events.length);
          }
          
          static Stream<String> generateEvents() {
            return Stream.fromIterable(["event1", "event2", "event3", "event4", "event5"]);
          }
        }
        
        main() async {
          final collector = await EventCollector.collectEvents(3);
          return [collector.events, collector.eventCount];
        }
      ''';

      final result = await execute(code);
      expect(
          result,
          equals([
            ["event1", "event2", "event3"],
            3
          ]));
    });

    test('Stream transformation async constructor pattern', () async {
      final code = '''
        import 'dart:async';
        
        class DataTransformer {
          final List<int> transformedData;
          final double average;
          
          DataTransformer._(this.transformedData, this.average);
          
          static Future<DataTransformer> transformStream() async {
            final sourceStream = generateNumbers();
            final transformedStream = sourceStream
                .map((n) => n * 2)
                .where((n) => n > 5);
            
            final results = await transformedStream.toList();
            final sum = results.fold(0, (a, b) => a + b);
            final avg = results.isEmpty ? 0.0 : sum / results.length;
            
            return DataTransformer._(results, avg);
          }
          
          static Stream<int> generateNumbers() {
            return Stream.fromIterable([1, 2, 3, 4, 5]);
          }
        }
        
        main() async {
          final transformer = await DataTransformer.transformStream();
          return [transformer.transformedData, transformer.average];
        }
      ''';

      final result = await execute(code);
      expect(
          result,
          equals([
            [6, 8, 10], // 3*2=6, 4*2=8, 5*2=10 (all > 5)
            8.0 // (6+8+10)/3 = 8.0
          ]));
    });

    test('Complex stream async constructor with error handling', () async {
      final code = '''
        import 'dart:async';
        
        class RobustStreamProcessor {
          final List<String> successfulItems;
          final List<String> errors;
          final bool hasErrors;
          
          RobustStreamProcessor._(this.successfulItems, this.errors, this.hasErrors);
          
          static Future<RobustStreamProcessor> processWithErrorHandling() async {
            final List<String> successful = [];
            final List<String> errorMessages = [];
            
            final stream = generateMixedStream();
            final items = await stream.toList();
            
            for (final item in items) {
              try {
                final processed = await processItem(item);
                successful.add(processed);
              } catch (e) {
                errorMessages.add("Error: \$e");
              }
            }
            
            return RobustStreamProcessor._(
              successful, 
              errorMessages, 
              errorMessages.isNotEmpty
            );
          }
          
          static Stream<String> generateMixedStream() {
            return Stream.fromIterable(["good1", "error", "good2", "good3"]);
          }
          
          static Future<String> processItem(String item) async {
            if (item == "error") {
              throw Exception("Processing failed for \$item");
            }
            return "processed-\$item";
          }
        }
        
        main() async {
          final processor = await RobustStreamProcessor.processWithErrorHandling();
          return [
            processor.successfulItems,
            processor.errors,
            processor.hasErrors
          ];
        }
      ''';

      final result = await execute(code);
      expect(
          result,
          equals([
            ["processed-good1", "processed-good2", "processed-good3"],
            ["Error: Exception: Processing failed for error"],
            true
          ]));
    });

    test('Stream controller async constructor pattern', () async {
      final code = '''
        import 'dart:async';
        
        class StreamControllerManager {
          final List<String> receivedData;
          
          StreamControllerManager._(this.receivedData);
          
          static Future<StreamControllerManager> createWithInitialData() async {
            final controller = StreamController<String>();
            final List<String> received = [];
            
            // Set up listener
            controller.stream.listen((data) {
              received.add(data);
            });
            
            // Add initial data
            controller.add("initial1");
            controller.add("initial2");
            
            // Wait for processing
            await Future.delayed(Duration(milliseconds: 10));
            
            // Add more data and close
            controller.add("added1");
            await controller.close();
            
            return StreamControllerManager._(received);
          }
        }
        
        main() async {
          final manager = await StreamControllerManager.createWithInitialData();
          return manager.receivedData;
        }
      ''';

      final result = await execute(code);
      expect(result, equals(["initial1", "initial2", "added1"]));
    });

    test('Stream subscription management async constructor pattern', () async {
      final code = '''
        import 'dart:async';
        
        class SubscriptionManager {
          final List<String> collectedData;
          final bool subscriptionWasPaused;
          
          SubscriptionManager._(this.collectedData, this.subscriptionWasPaused);
          
          static Future<SubscriptionManager> createWithSubscriptionControl() async {
            final controller = StreamController<String>();
            final List<String> collected = [];
            bool wasPaused = false;
            
            final subscription = controller.stream.listen((data) {
              collected.add(data);
            });
            
            // Add some data
            controller.add("data1");
            await Future.delayed(Duration(milliseconds: 5));
            
            // Pause subscription
            subscription.pause();
            wasPaused = subscription.isPaused;
            
            // Add data while paused (should be buffered)
            controller.add("data2");
            
            // Resume and add more data  
            subscription.resume();
            await Future.delayed(Duration(milliseconds: 5));
            controller.add("data3");
            
            await Future.delayed(Duration(milliseconds: 10));
            await subscription.cancel();
            await controller.close();
            
            return SubscriptionManager._(collected, wasPaused);
          }
        }
        
        main() async {
          final manager = await SubscriptionManager.createWithSubscriptionControl();
          return [manager.collectedData, manager.subscriptionWasPaused];
        }
      ''';

      final result = await execute(code);
      expect(
          result,
          equals([
            ["data1", "data2", "data3"],
            true
          ]));
    });

    test('Stream periodic constructor pattern', () async {
      final code = '''
        import 'dart:async';
        
        class PeriodicDataCollector {
          final List<int> timerData;
          final int dataCount;
          
          PeriodicDataCollector._(this.timerData, this.dataCount);
          
          static Future<PeriodicDataCollector> createFromPeriodicStream() async {
            // Create a periodic stream that emits counter values
            final periodicStream = Stream.periodic(
              Duration(milliseconds: 10), 
              (count) => count * 2
            );
            
            // Take only the first 4 values
            final data = await periodicStream.take(4).toList();
            
            return PeriodicDataCollector._(data, data.length);
          }
        }
        
        main() async {
          final collector = await PeriodicDataCollector.createFromPeriodicStream();
          return [collector.timerData, collector.dataCount];
        }
      ''';

      final result = await execute(code);
      expect(
          result,
          equals([
            [0, 2, 4, 6], // count * 2 for count = 0, 1, 2, 3
            4
          ]));
    });

    test('Stream broadcast async constructor pattern', () async {
      final code = '''
        import 'dart:async';
        
        class BroadcastStreamManager {
          final List<String> listener1Data;
          final List<String> listener2Data;
          final bool isBroadcast;
          
          BroadcastStreamManager._(this.listener1Data, this.listener2Data, this.isBroadcast);
          
          static Future<BroadcastStreamManager> createWithBroadcast() async {
            final controller = StreamController<String>();
            final broadcast = controller.stream.asBroadcastStream();
            
            final List<String> listener1 = [];
            final List<String> listener2 = [];
            
            // Multiple listeners on broadcast stream
            broadcast.listen((data) => listener1.add("L1:" + data));
            broadcast.listen((data) => listener2.add("L2:" + data));
            
            // Add data
            controller.add("broadcast1");
            controller.add("broadcast2");
            
            await Future.delayed(Duration(milliseconds: 10));
            await controller.close();
            
            return BroadcastStreamManager._(listener1, listener2, broadcast.isBroadcast);
          }
        }
        
        main() async {
          final manager = await BroadcastStreamManager.createWithBroadcast();
          return [manager.listener1Data, manager.listener2Data, manager.isBroadcast];
        }
      ''';

      final result = await execute(code);
      expect(
          result,
          equals([
            ["L1:broadcast1", "L1:broadcast2"],
            ["L2:broadcast1", "L2:broadcast2"],
            true
          ]));
    });

    test('Stream from Future async constructor pattern', () async {
      final code = '''
        import 'dart:async';
        
        class FutureStreamProcessor {
          final List<String> results;
          final String summary;
          
          FutureStreamProcessor._(this.results, this.summary);
          
          static Future<FutureStreamProcessor> createFromFutures() async {
            // Create futures that complete at different times
            final future1 = Future.delayed(Duration(milliseconds: 10), () => "result1");
            final future2 = Future.value("result2");
            final future3 = Future.delayed(Duration(milliseconds: 5), () => "result3");
            
            // Create stream from futures
            final stream = Stream.fromFutures([future1, future2, future3]);
            final results = await stream.toList();
            
            final summary = "Collected " + results.length.toString() + " results";
            return FutureStreamProcessor._(results, summary);
          }
        }
        
        main() async {
          final processor = await FutureStreamProcessor.createFromFutures();
          return [processor.results.length, processor.summary];
        }
      ''';

      final result = await execute(code);
      expect(result, equals([3, "Collected 3 results"]));
    });

    test('Async generator (async*) constructor pattern', () async {
      final code = '''
        import 'dart:async';
        
        class AsyncGeneratorManager {
          final List<String> collectedData;
          final int count;
          
          AsyncGeneratorManager._(this.collectedData, this.count);
          
          static Future<AsyncGeneratorManager> fromAsyncGenerator() async {
            final stream = generateAsyncStream();
            final data = await stream.toList();
            return AsyncGeneratorManager._(data, data.length);
          }
          
          static Stream<String> generateAsyncStream() async* {
            yield "async1";
            await Future.delayed(Duration(milliseconds: 1));
            yield "async2";
            yield "async3";
          }
        }
        
        main() async {
          final manager = await AsyncGeneratorManager.fromAsyncGenerator();
          return [manager.collectedData, manager.count];
        }
      ''';

      final result = await execute(code);
      expect(
          result,
          equals([
            ["async1", "async2", "async3"],
            3
          ]));
    });

    test('Sync generator (sync*) constructor pattern', () async {
      final code = '''
        import 'dart:async';
        
        class SyncGeneratorManager {
          final List<int> numbers;
          final int sum;
          
          SyncGeneratorManager._(this.numbers, this.sum);
          
          static Future<SyncGeneratorManager> fromSyncGenerator() async {
            final iterable = generateNumbers();
            final numbers = iterable.toList();
            final sum = numbers.fold(0, (a, b) => a + b);
            return SyncGeneratorManager._(numbers, sum);
          }
          
          static Iterable<int> generateNumbers() sync* {
            yield 1;
            yield 2;
            yield 3;
            yield 4;
          }
        }
        
        main() async {
          final manager = await SyncGeneratorManager.fromSyncGenerator();
          return [manager.numbers, manager.sum];
        }
      ''';

      final result = await execute(code);
      expect(
          result,
          equals([
            [1, 2, 3, 4],
            10
          ]));
    });

    test('Generator with yield* constructor pattern', () async {
      final code = '''
        import 'dart:async';
        
        class YieldStarManager {
          final List<String> allData;
          final String summary;
          
          YieldStarManager._(this.allData, this.summary);
          
          static Future<YieldStarManager> fromYieldStar() async {
            final stream = generateWithYieldStar();
            final data = await stream.toList();
            final summary = "Combined " + data.length.toString() + " items";
            return YieldStarManager._(data, summary);
          }
          
          static Stream<String> generateWithYieldStar() async* {
            yield "direct1";
            yield* Stream.fromIterable(["from_iterable1", "from_iterable2"]);
            yield "direct2";
            yield* generateSubStream();
          }
          
          static Stream<String> generateSubStream() async* {
            yield "sub1";
            yield "sub2";
          }
        }
        
        main() async {
          final manager = await YieldStarManager.fromYieldStar();
          return [manager.allData, manager.summary];
        }
      ''';

      final result = await execute(code);
      expect(
          result,
          equals([
            [
              "direct1",
              "from_iterable1",
              "from_iterable2",
              "direct2",
              "sub1",
              "sub2"
            ],
            "Combined 6 items"
          ]));
    });

    test('Await for loop with stream processing pattern', () async {
      final code = '''
        import 'dart:async';
        
        class StreamSumProcessor {
          final int totalSum;
          final int processedCount;
          
          StreamSumProcessor._(this.totalSum, this.processedCount);
          
          static Future<StreamSumProcessor> processWithAwaitFor() async {
            final stream = generateNumberStream();
            final sum = await sumStream(stream);
            final count = 5; // We know we have 5 numbers
            return StreamSumProcessor._(sum, count);
          }
          
          static Future<int> sumStream(Stream<int> stream) async {
            var sum = 0;
            await for (final value in stream) {
              sum += value;
            }
            return sum;
          }
          
          static Stream<int> generateNumberStream() async* {
            yield 10;
            yield 20;
            yield 30;
            yield 40;
            yield 50;
          }
        }
        
        main() async {
          final processor = await StreamSumProcessor.processWithAwaitFor();
          return [processor.totalSum, processor.processedCount];
        }
      ''';

      final result = await execute(code);
      expect(
          result,
          equals([
            150, // 10 + 20 + 30 + 40 + 50
            5
          ]));
    });
  });
}
