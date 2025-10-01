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

  test('Async nested for-in loops with lists', () async {
    final source = '''
      Future<String> processItem(String category, String item) async {
        await Future.delayed(Duration(milliseconds: 5));
        return '\$category:\$item';
      }
      
      Future<List<String>> processCategories() async {
        List<String> results = [];
        
        List<String> categories = ['fruits', 'vegetables', 'grains'];
        Map<String, List<String>> items = {
          'fruits': ['apple', 'banana', 'orange'],
          'vegetables': ['carrot', 'broccoli'],
          'grains': ['rice', 'wheat', 'oats', 'barley']
        };
        
        // Outer for-in loop through categories
        for (String category in categories) {
          List<String> categoryItems = items[category] ?? [];
          
          // Inner for-in loop through items in each category
          for (String item in categoryItems) {
            String processed = await processItem(category, item);
            results.add(processed);
          }
        }
        
        return results;
      }

      Future<int> main() async {
        List<String> results = await processCategories();
        return results.length;
      }
    ''';

    final result = await execute(source);
    expect(result, equals(9)); // 3 + 2 + 4 = 9 items total
  });

  test('Async nested for-in loops with maps and complex data', () async {
    final source = '''
      Future<Map<String, dynamic>> analyzeData(String department, Map<String, dynamic> employee) async {
        await Future.delayed(Duration(milliseconds: 3));
        
        int salary = employee['salary'] as int;
        String role = employee['role'] as String;
        
        return {
          'department': department,
          'name': employee['name'],
          'role': role,
          'processedSalary': salary * 1.1, // 10% bonus calculation
          'category': salary > 50000 ? 'senior' : 'junior'
        };
      }
      
      Future<Map<String, dynamic>> processCompanyData() async {
        List<Map<String, dynamic>> allProcessed = [];
        int totalProcessed = 0;
        double totalSalary = 0;
        
        Map<String, List<Map<String, dynamic>>> company = {
          'engineering': [
            {'name': 'Alice', 'salary': 75000, 'role': 'developer'},
            {'name': 'Bob', 'salary': 85000, 'role': 'senior_dev'},
          ],
          'marketing': [
            {'name': 'Carol', 'salary': 45000, 'role': 'coordinator'},
            {'name': 'David', 'salary': 60000, 'role': 'manager'},
          ],
          'sales': [
            {'name': 'Eve', 'salary': 55000, 'role': 'representative'},
          ]
        };
        
        // Outer for-in loop through departments
        for (String department in company.keys) {
          List<Map<String, dynamic>> employees = company[department] ?? [];
          
          // Inner for-in loop through employees
          for (Map<String, dynamic> employee in employees) {
            Map<String, dynamic> processed = await analyzeData(department, employee);
            allProcessed.add(processed);
            totalProcessed++;
            totalSalary += processed['processedSalary'] as double;
          }
        }
        
        return {
          'processed': allProcessed,
          'totalEmployees': totalProcessed,
          'averageSalary': totalSalary / totalProcessed,
          'departments': company.keys.length
        };
      }

      Future<int> main() async {
        Map<String, dynamic> results = await processCompanyData();
        return results['totalEmployees'] as int;
      }
    ''';

    final result = await execute(source);
    expect(result, equals(5)); // 2 + 2 + 1 = 5 employees total
  });

  test('Async nested for-in loops with break and continue', () async {
    final source = '''
      Future<bool> shouldSkipItem(String category, String item) async {
        await Future.delayed(Duration(milliseconds: 2));
        // Skip items containing 'skip'
        return item.contains('skip');
      }
      
      Future<bool> shouldStopCategory(String category) async {
        await Future.delayed(Duration(milliseconds: 1));
        // Stop processing when we hit 'stop' category
        return category == 'stop';
      }
      
      Future<List<String>> processWithControlFlow() async {
        List<String> processed = [];
        
        List<String> categories = ['start', 'middle', 'stop', 'never_reached'];
        Map<String, List<String>> items = {
          'start': ['item1', 'skip_me', 'item2'],
          'middle': ['item3', 'item4', 'skip_this', 'item5'],
          'stop': ['item6', 'item7'],
          'never_reached': ['item8', 'item9']
        };
        
        // Outer for-in loop with break condition
        for (String category in categories) {
          if (await shouldStopCategory(category)) {
            break; // Exit both loops when we hit 'stop'
          }
          
          List<String> categoryItems = items[category] ?? [];
          
          // Inner for-in loop with continue condition
          for (String item in categoryItems) {
            if (await shouldSkipItem(category, item)) {
              continue; // Skip this item and continue with next
            }
            
            processed.add('\$category:\$item');
          }
        }
        
        return processed;
      }

      Future<int> main() async {
        List<String> results = await processWithControlFlow();
        return results.length;
      }
    ''';

    final result = await execute(source);
    expect(
        result,
        equals(
            5)); // start:item1, start:item2, middle:item3, middle:item4, middle:item5
  });

  test('Async nested for-in loops with exception handling', () async {
    final source = '''
      Future<String> riskyProcessing(String category, String item) async {
        await Future.delayed(Duration(milliseconds: 2));
        
        if (item == 'dangerous') {
          throw Exception('Processing failed for dangerous item');
        }
        
        if (category == 'unstable' && item == 'item2') {
          throw StateError('Unstable category caused an error');
        }
        
        return 'processed_\${category}_\${item}';
      }
      
      Future<Map<String, dynamic>> processWithExceptionHandling() async {
        List<String> successful = [];
        List<String> errors = [];
        int totalAttempts = 0;
        
        List<String> categories = ['stable', 'unstable', 'safe'];
        Map<String, List<String>> items = {
          'stable': ['item1', 'dangerous', 'item3'],
          'unstable': ['item1', 'item2', 'item3'],
          'safe': ['item1', 'item2']
        };
        
        // Outer for-in loop
        for (String category in categories) {
          List<String> categoryItems = items[category] ?? [];
          
          // Inner for-in loop with exception handling
          for (String item in categoryItems) {
            totalAttempts++;
            
            try {
              String result = await riskyProcessing(category, item);
              successful.add(result);
            } catch (e) {
              String errorMsg = 'Error in \$category:\$item - \$e';
              errors.add(errorMsg);
            }
          }
        }
        
        return {
          'successful': successful,
          'errors': errors,
          'totalAttempts': totalAttempts,
          'successRate': successful.length / totalAttempts
        };
      }

      Future<String> main() async {
        Map<String, dynamic> results = await processWithExceptionHandling();
        
        int successful = (results['successful'] as List).length;
        int errors = (results['errors'] as List).length;
        int total = results['totalAttempts'] as int;
        
        return 'Processed \$total items: \$successful successful, \$errors errors';
      }
    ''';

    final result = await execute(source);
    expect(result, equals('Processed 8 items: 6 successful, 2 errors'));
  });

  test('Async nested for-in loops with await for streams', () async {
    final source = '''
      Future<Stream<String>> createAsyncStream(List<String> items) async {
        await Future.delayed(Duration(milliseconds: 5));
        
        Stream<String> stream = Stream.fromIterable(items);
        return stream;
      }
      
      Future<List<String>> processStreams() async {
        List<String> allResults = [];
        
        List<String> streamNames = ['stream1', 'stream2'];
        Map<String, List<String>> streamData = {
          'stream1': ['a', 'b', 'c'],
          'stream2': ['x', 'y']
        };
        
        // Outer for-in loop through stream names
        for (String streamName in streamNames) {
          List<String> data = streamData[streamName] ?? [];
          Stream<String> stream = await createAsyncStream(data);
          
          // Inner await for loop to process stream items
          await for (String item in stream) {
            String processed = '\${streamName}:\$item';
            allResults.add(processed);
            
            // Simulate async processing for each stream item
            await Future.delayed(Duration(milliseconds: 1));
          }
        }
        
        return allResults;
      }

      Future<int> main() async {
        List<String> results = await processStreams();
        return results.length;
      }
    ''';

    final result = await execute(source);
    expect(result, equals(5)); // 3 items from stream1 + 2 items from stream2
  });

  test('Simple async nested for-in loops', () async {
    final source = '''
      Future<int> simpleNestedForIn() async {
        int count = 0;
        
        List<List<String>> data = [
          ['a', 'b'],
          ['c', 'd', 'e']
        ];
        
        // Simple nested for-in
        for (List<String> sublist in data) {
          for (String item in sublist) {
            await Future.delayed(Duration(milliseconds: 1));
            count++;
          }
        }
        
        return count;
      }

      Future<int> main() async {
        return await simpleNestedForIn();
      }
    ''';

    final result = await execute(source);
    expect(result, equals(5)); // 2 + 3 = 5 items total
  });

  test('Triple nested for-in loops with async operations', () async {
    final source = '''
      Future<void> delay(int ms) async {
        return Future.delayed(Duration(milliseconds: ms));
      }

      Future<List<String>> tripleNested() async {
        List<String> results = [];
        List<String> categories = ['A', 'B'];
        List<int> levels = [1, 2];
        List<String> items = ['x', 'y'];

        for (String category in categories) {
          await delay(5);
          for (int level in levels) {
            await delay(5);
            for (String item in items) {
              await delay(5);
              results.add('\${category}-\${level}-\${item}');
            }
          }
        }

        return results;
      }

      Future<int> main() async {
        List<String> results = await tripleNested();
        return results.length;
      }
    ''';

    final result = await execute(source);
    expect(result, equals(8)); // 2 * 2 * 2 = 8 combinations
  });

  test('Nested loops with conditional break and continue', () async {
    final source = '''
      Future<void> delay(int ms) async {
        return Future.delayed(Duration(milliseconds: ms));
      }

      Future<List<String>> complexControl() async {
        List<String> results = [];

        for (int outer = 0; outer < 5; outer++) {
          await delay(5);
          
          if (outer == 2) {
            continue; // Skip outer = 2
          }
          
          for (int inner = 0; inner < 4; inner++) {
            await delay(5);
            
            if (inner == 1) {
              continue; // Skip inner = 1
            }
            
            if (inner == 3 && outer == 3) {
              break; // Break inner loop when outer=3 and inner=3
            }
            
            results.add('\${outer}:\${inner}');
          }
        }

        return results;
      }

      Future<int> main() async {
        List<String> results = await complexControl();
        return results.length;
      }
    ''';

    final result = await execute(source);
    // outer 0: inner 0,2,3 = 3
    // outer 1: inner 0,2,3 = 3
    // outer 2: skipped = 0
    // outer 3: inner 0,2 = 2 (breaks at 3)
    // outer 4: inner 0,2,3 = 3
    // Total = 11
    expect(result, equals(11));
  });

  test('Nested for-in with maps and async transformations', () async {
    final source = '''
      Future<void> delay(int ms) async {
        return Future.delayed(Duration(milliseconds: ms));
      }

      Future<String> transform(String key, dynamic value) async {
        await delay(10);
        return '\${key}=\${value}';
      }

      Future<List<String>> processNestedMaps() async {
        List<String> results = [];
        
        Map<String, Map<String, int>> data = {
          'user1': {'score': 100, 'level': 5},
          'user2': {'score': 200, 'level': 10},
        };

        for (String userId in data.keys) {
          await delay(5);
          Map<String, int> userMap = data[userId] ?? {};
          
          for (String key in userMap.keys) {
            int value = userMap[key] ?? 0;
            String transformed = await transform(key, value);
            results.add('\${userId}:\${transformed}');
          }
        }

        return results;
      }

      Future<int> main() async {
        List<String> results = await processNestedMaps();
        return results.length;
      }
    ''';

    final result = await execute(source);
    expect(result, equals(4)); // 2 users * 2 properties = 4
  });

  test('Await for loop inside regular for-in loop', () async {
    final source = '''
      Future<void> delay(int ms) async {
        return Future.delayed(Duration(milliseconds: ms));
      }

      Stream<String> createStream(List<String> items) async* {
        for (String item in items) {
          await delay(10);
          yield item;
        }
      }

      Future<List<String>> mixedStreamProcessing() async {
        List<String> results = [];
        List<String> groups = ['G1', 'G2'];

        // Regular for-in for outer loop
        for (String group in groups) {
          await delay(5);
          List<String> items = group == 'G1' ? ['a', 'b', 'c'] : ['x', 'y'];
          
          // Await for inside
          await for (String item in createStream(items)) {
            await delay(5);
            results.add('\${group}:\${item}');
          }
        }

        return results;
      }

      Future<int> main() async {
        List<String> results = await mixedStreamProcessing();
        return results.length;
      }
    ''';

    final result = await execute(source);
    expect(result, equals(5)); // G1: 3 items, G2: 2 items = 5 total
  });

  test('Mixed loop types with async: for-in inside while inside for', () async {
    final source = '''
      Future<void> delay(int ms) async {
        return Future.delayed(Duration(milliseconds: ms));
      }

      Future<List<String>> mixedLoops() async {
        List<String> results = [];

        for (int batch = 0; batch < 2; batch++) {
          await delay(5);
          int counter = 0;
          
          while (counter < 2) {
            await delay(5);
            List<String> items = ['item1', 'item2'];
            
            for (String item in items) {
              await delay(5);
              results.add('b\${batch}:c\${counter}:\${item}');
            }
            
            counter++;
          }
        }

        return results;
      }

      Future<int> main() async {
        List<String> results = await mixedLoops();
        return results.length;
      }
    ''';

    final result = await execute(source);
    expect(result, equals(8)); // 2 batches * 2 counters * 2 items = 8
  });

  test('Nested loops with async/await in various positions', () async {
    final source = '''
      Future<int> asyncAdd(int a, int b) async {
        await Future.delayed(Duration(milliseconds: 5));
        return a + b;
      }

      Future<bool> asyncCheck(int value) async {
        await Future.delayed(Duration(milliseconds: 5));
        return value > 5;
      }

      Future<List<String>> complexAsync() async {
        List<String> results = [];

        for (int i = 0; i < 3; i++) {
          int outerSum = await asyncAdd(i, 10);
          
          for (int j = 0; j < 2; j++) {
            int innerSum = await asyncAdd(j, outerSum);
            bool shouldAdd = await asyncCheck(innerSum);
            
            if (shouldAdd) {
              results.add('i\${i}:j\${j}:sum\${innerSum}');
            }
          }
        }

        return results;
      }

      Future<int> main() async {
        List<String> results = await complexAsync();
        return results.length;
      }
    ''';

    final result = await execute(source);
    expect(result, equals(6)); // All combinations pass the > 5 check
  });

  test('Nested for-in with list modifications and async operations', () async {
    final source = '''
      Future<void> delay(int ms) async {
        return Future.delayed(Duration(milliseconds: ms));
      }

      Future<int> process(String item) async {
        await delay(5);
        return item.length;
      }

      Future<Map<String, dynamic>> nestedWithModifications() async {
        List<String> groups = ['alpha', 'beta', 'gamma'];
        Map<String, List<int>> results = {};
        int totalProcessed = 0;

        for (String group in groups) {
          await delay(5);
          List<int> groupResults = [];
          List<String> items = ['a', 'bb', 'ccc'];
          
          for (String item in items) {
            int length = await process(item);
            groupResults.add(length);
            totalProcessed++;
          }
          
          results[group] = groupResults;
        }

        return {
          'totalProcessed': totalProcessed,
          'groupCount': results.keys.length,
        };
      }

      Future<int> main() async {
        Map<String, dynamic> result = await nestedWithModifications();
        return result['totalProcessed'] as int;
      }
    ''';

    final result = await execute(source);
    expect(result, equals(9)); // 3 groups * 3 items = 9
  });

  test('Deep nesting with 4 levels and mixed async operations', () async {
    final source = '''
      Future<void> delay(int ms) async {
        return Future.delayed(Duration(milliseconds: ms));
      }

      Future<List<String>> deepNesting() async {
        List<String> results = [];
        
        for (int a = 0; a < 2; a++) {
          await delay(2);
          
          for (int b = 0; b < 2; b++) {
            await delay(2);
            
            for (int c = 0; c < 2; c++) {
              await delay(2);
              
              for (int d = 0; d < 2; d++) {
                await delay(2);
                results.add('\${a}\${b}\${c}\${d}');
              }
            }
          }
        }

        return results;
      }

      Future<int> main() async {
        List<String> results = await deepNesting();
        return results.length;
      }
    ''';

    final result = await execute(source);
    expect(result, equals(16)); // 2^4 = 16 combinations
  });

  test('Nested loops with early returns and exception handling', () async {
    final source = '''
      Future<void> delay(int ms) async {
        return Future.delayed(Duration(milliseconds: ms));
      }

      Future<Map<String, dynamic>> nestedWithExceptions() async {
        List<String> successful = [];
        List<String> errors = [];

        for (int outer = 0; outer < 3; outer++) {
          await delay(5);
          
          for (int inner = 0; inner < 3; inner++) {
            await delay(5);
            
            try {
              if (outer == 1 && inner == 1) {
                throw Exception('Simulated error');
              }
              
              successful.add('\${outer}:\${inner}');
            } catch (e) {
              errors.add('\${outer}:\${inner}');
            }
          }
        }

        return {
          'successful': successful.length,
          'errors': errors.length,
          'total': successful.length + errors.length,
        };
      }

      Future<int> main() async {
        Map<String, dynamic> result = await nestedWithExceptions();
        return result['successful'] as int;
      }
    ''';

    final result = await execute(source);
    expect(result, equals(8)); // 9 total - 1 error = 8 successful
  });

  test('Nested for-in with dynamic list generation', () async {
    final source = '''
      Future<void> delay(int ms) async {
        return Future.delayed(Duration(milliseconds: ms));
      }

      Future<List<int>> generateNumbers(int count) async {
        await delay(5);
        List<int> numbers = [];
        for (int i = 0; i < count; i++) {
          numbers.add(i);
        }
        return numbers;
      }

      Future<int> dynamicNesting() async {
        int total = 0;
        List<int> outerCounts = [2, 3, 1];

        for (int count in outerCounts) {
          await delay(5);
          List<int> innerNumbers = await generateNumbers(count);
          
          for (int number in innerNumbers) {
            await delay(5);
            total += number;
          }
        }

        return total;
      }

      Future<int> main() async {
        return await dynamicNesting();
      }
    ''';

    final result = await execute(source);
    // outer=2: 0+1=1, outer=3: 0+1+2=3, outer=1: 0=0
    // Total = 1 + 3 + 0 = 4
    expect(result, equals(4));
  });
}
