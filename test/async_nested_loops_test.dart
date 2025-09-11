import 'package:test/test.dart';
import 'package:d4rt/d4rt.dart';

dynamic execute(String source, {Object? args}) {
  final d4rt = D4rt();
  return d4rt.execute(
      library: 'package:test/main.dart',
      args: args,
      sources: {'package:test/main.dart': source});
}

void main() {
  test('Async nested loops: while containing for inside for', () async {
    final source = '''
      Future<void> delay(int milliseconds) async {
        // Simulate async delay
        return Future.delayed(Duration(milliseconds: milliseconds));
      }
      
      Future<List<String>> processData() async {
        List<String> results = [];
        int outerCounter = 0;
        
        // While loop as outer container
        while (outerCounter < 3) {
          
          // First for loop
          for (int i = 0; i < 2; i++) {
            
            // Nested for loop inside the first for loop
            for (int j = 0; j < 2; j++) {
              
              // Async operation in the innermost loop
              await delay(10);
              
              String result = 'outer:\${outerCounter}_i:\${i}_j:\${j}';
              results.add(result);
            }
          }
          
          outerCounter++;
        }
        
        return results;
      }

      Future<int> main() async {
        
        List<String> results = await processData();
        return results.length;
      }
    ''';

    final result = await execute(source);
    expect(result, equals(12));
  });

  test('Async nested loops with conditions and breaks', () async {
    final source = '''
      Future<void> asyncPrint(String message) async {
        return Future.delayed(Duration(milliseconds: 5));
      }
      
      Future<Map<String, dynamic>> complexAsyncLoops() async {
        List<int> evenNumbers = [];
        List<int> oddNumbers = [];
        int totalIterations = 0;
        int whileCount = 0;
        
        // While loop with condition
        while (whileCount < 4) {
          await asyncPrint('While iteration: \$whileCount');
          
          // Outer for loop
          for (int x = 0; x < 3; x++) {
            await asyncPrint('  Outer for x = \$x');
            
            // Inner for loop with break condition
            for (int y = 0; y < 5; y++) {
              await asyncPrint('    Inner for y = \$y');
              
              totalIterations++;
              int value = (whileCount * 100) + (x * 10) + y;
              
              if (value % 2 == 0) {
                evenNumbers.add(value);
              } else {
                oddNumbers.add(value);
              }
              
              // Break inner loop if y reaches 3
              if (y == 3) {
                await asyncPrint('    Breaking inner loop at y = \$y');
                break;
              }
            }
            
            // Continue outer loop if x is 1
            if (x == 1) {
              await asyncPrint('  Continuing outer loop at x = \$x');
              continue;
            }
          }
          
          whileCount++;
        }
        
        return {
          'evenNumbers': evenNumbers,
          'oddNumbers': oddNumbers,
          'totalIterations': totalIterations,
          'whileCount': whileCount
        };
      }

      Future<String> main() async {
        
        await complexAsyncLoops();
        
        return 'Complex test completed';
      }
    ''';

    final result = await execute(source);
    expect(result, equals('Complex test completed'));
  });

  test('Async nested loops with exception handling', () async {
    final source = '''
      Future<int> riskyAsyncOperation(int value) async {
        await Future.delayed(Duration(milliseconds: 1));
        
        if (value == 13) {
          throw Exception('Unlucky number 13!');
        }
        
        return value * 2;
      }
      
      Future<Map<String, dynamic>> loopsWithExceptionHandling() async {
        List<int> successfulResults = [];
        List<String> errors = [];
        int loopCounter = 0;
        
        // While loop
        while (loopCounter < 2) {
          
          // Outer for loop
          for (int a = 0; a < 3; a++) {
            
            // Inner for loop
            for (int b = 0; b < 5; b++) {
              int testValue = (loopCounter * 10) + a + b;
              
              try {
                int result = await riskyAsyncOperation(testValue);
                successfulResults.add(result);
              } catch (e) {
                String errorMsg = 'Error at [\$loopCounter,\$a,\$b]: \$e';
                errors.add(errorMsg);
              }
            }
          }
          
          loopCounter++;
        }
        
        return {
          'successful': successfulResults,
          'errors': errors,
          'totalSuccessful': successfulResults.length,
          'totalErrors': errors.length
        };
      }

      Future<String> main() async {
        
        try {
          await loopsWithExceptionHandling();
          
          return 'Exception handling test completed successfully';
        } catch (e) {
          return 'Test failed with error: \$e';
        }
      }
    ''';

    final result = await execute(source);
    expect(result, equals('Exception handling test completed successfully'));
  });

  test('Async nested loops with Future.wait', () async {
    final source = '''
      Future<String> asyncTask(String taskName, int delay) async {
        await Future.delayed(Duration(milliseconds: delay));
        return 'Task \$taskName completed';
      }
      
      Future<List<String>> parallelAsyncLoops() async {
        List<String> allResults = [];
        int round = 0;
        
        // While loop for multiple rounds
        while (round < 2) {
          List<Future<String>> futures = [];
          
          // Outer for loop
          for (int i = 0; i < 2; i++) {
            // Inner for loop to create parallel tasks
            for (int j = 0; j < 2; j++) {
              String taskName = 'R\${round}_I\${i}_J\${j}';
              int delay = (i + j + 1) * 10;
              
              futures.add(asyncTask(taskName, delay));
            }
          }
          
          // Wait for all tasks in this round to complete
          List<String> roundResults = await Future.wait(futures);
          allResults.addAll(roundResults);
          
          round++;
        }
        
        return allResults;
      }

      Future<int> main() async {
        List<String> results = await parallelAsyncLoops();
        
        return results.length;
      }
    ''';

    final result = await execute(source);
    expect(result, equals(8));
  });
}
