import 'package:test/test.dart';

import '../interpreter_test.dart';

enum Color { red, green, blue }

enum Status { pending, running, completed, failed }

void main() {
  group('Enum Tests', () {
    test('Enum Value Access', () {
      const source = '''
        enum Color { red, green, blue }
        
        main() {
          return Color.green;
        }
      ''';
      final result = execute(source);
      // On s'attend à ce que l'interpréteur retourne un objet représentant Color.green
      // La représentation exacte dépendra de InterpretedEnumValue.toString()
      expect(result.toString(), equals('Color.green'));
    });

    test('Enum Index Access', () {
      const source = '''
        enum Status { pending, running, completed, failed }
        
        main() {
          var s1 = Status.pending;
          var s2 = Status.completed;
          return [s1.index, s2.index];
        }
      ''';
      final result = execute(source);
      expect(result, equals([0, 2]));
    });

    test('Enum Static Values List', () {
      const source = '''
        enum Color { red, green, blue }
        
        main() {
          var valuesList = Color.values;
          // Retourne une liste de chaînes pour faciliter la comparaison
          return valuesList.map((v) => v.toString()).toList(); 
        }
      ''';
      final result = execute(source);
      expect(result, equals(['Color.red', 'Color.green', 'Color.blue']));
      // On pourrait aussi vérifier le type de retour si on avait une représentation BridgedList
      // expect(result, isA<List>()); // ou isA<BridgedList>
    });

    test('Enum Comparison', () {
      const source = '''
        enum Status { pending, running, completed, failed }
        
        main() {
          var s1 = Status.running;
          var s2 = Status.running;
          var s3 = Status.failed;
          
          return [
            s1 == s2, // true
            s1 == s3, // false
            s1 != s3  // true
          ];
        }
      ''';
      final result = execute(source);
      expect(result, equals([true, false, true]));
    });

    // Optionnel: Test avec switch (peut nécessiter plus de logique dans l'interpréteur)
    test('Enum in Switch Statement', () {
      const source = '''
        enum Status { pending, running, completed, failed }
        
        String checkStatus(Status s) {
          var result = 'unknown';
          switch (s) {
            case Status.pending:
              result = 'waiting';
              break;
            case Status.running:
              result = 'in_progress';
              break;
            case Status.completed:
              result = 'done';
              break;
            case Status.failed:
              result = 'error';
              break;
            // Pas de default, Dart requiert l'exhaustivité pour les enums
          }
          return result;
        }

        main() {
          return checkStatus(Status.completed);
        }
      ''';
      // Pour l'instant, on s'attend à ce que cela fonctionne car `==` est implémenté.
      // L'interpréteur doit pouvoir gérer les `case Enum.value:`
      final result = execute(source);
      expect(result, equals('done'));

      const source2 = '''
        enum Status { pending, running, completed, failed }
        
        String checkStatus(Status s) {
          var result = 'unknown';
          switch (s) {
            case Status.pending:
              result = 'waiting';
              break;
            case Status.running:
              result = 'in_progress';
              break;
            case Status.completed:
              result = 'done';
              break;
            case Status.failed:
              result = 'error';
              break;
          }
          return result;
        }

        main() {
          return checkStatus(Status.pending);
        }
      ''';
      final result2 = execute(source2);
      expect(result2, equals('waiting'));
    });
  });
  group('Enum Tests', () {
    test('Basic enum declaration and usage', () {
      const source = '''
        enum Direction {
          north,
          south,
          east,
          west
        }

        main() {
          var dir = Direction.north;
          return dir.toString();
        }
      ''';
      expect(execute(source), equals('Direction.north'));
    });

    test('Enum with index property', () {
      const source = '''
        enum Status {
          pending,
          processing,
          completed,
          failed
        }

        main() {
          var s = Status.processing;
          return s.index;
        }
      ''';
      expect(execute(source), equals(1));
    });

    test('Enum in switch statement', () {
      const source = '''
        enum TrafficLight {
          red,
          yellow,
          green
        }

        String getAction(TrafficLight light) {
          switch (light) {
            case TrafficLight.red:
              return 'Stop';
            case TrafficLight.yellow:
              return 'Slow down';
            case TrafficLight.green:
              return 'Go';
          }
        }

        main() {
          var light = TrafficLight.yellow;
          return getAction(light);
        }
      ''';
      expect(execute(source), equals('Slow down'));
    });

    test('Enum with methods', () {
      const source = '''
        enum Planet {
          mercury(0.38),
          venus(0.91),
          earth(1.0),
          mars(0.38),
          jupiter(2.34),
          saturn(1.06),
          uranus(0.92),
          neptune(1.19);

          final double gravity;
          const Planet(this.gravity);

          double calculateWeight(double earthWeight) {
            return earthWeight * gravity;
          }
        }

        main() {
          var weightOnMars = Planet.mars.calculateWeight(100);
          var weightOnJupiter = Planet.jupiter.calculateWeight(100);
          return [weightOnMars, weightOnJupiter];
        }
      ''';
      expect(execute(source), equals([38.0, 234.0]));
    });

    test('Enum with complex properties and methods', () {
      const source = '''
        enum CardSuit {
          hearts('♥', 'red'),
          diamonds('♦', 'red'),
          clubs('♣', 'black'),
          spades('♠', 'black');

          final String symbol;
          final String color;
          const CardSuit(this.symbol, this.color);

          bool isRed() => color == 'red';
          bool isBlack() => color == 'black';
          String get fullName {
            switch (this) {
              case CardSuit.hearts:
                return 'Hearts';
              case CardSuit.diamonds:
                return 'Diamonds';
              case CardSuit.clubs:
                return 'Clubs';
              case CardSuit.spades:
                return 'Spades';
            }
          }
        }

        main() {
          var heart = CardSuit.hearts;
          var spade = CardSuit.spades;
          return [
            heart.symbol,
            heart.color,
            heart.isRed(),
            spade.symbol,
            spade.color,
            spade.isBlack(),
            heart.fullName,
            spade.fullName
          ];
        }
      ''';
      expect(execute(source),
          equals(['♥', 'red', true, '♠', 'black', true, 'Hearts', 'Spades']));
    });

    test('Enum with static methods', () {
      const source = '''
        enum HttpStatus {
          ok(200),
          notFound(404),
          serverError(500);

          final int code;
          const HttpStatus(this.code);

          static HttpStatus fromCode(int code) {
            for (var status in HttpStatus.values) {
              if (status.code == code) return status;
            }
            throw 'Invalid status code';
          }

          bool isSuccess() => code >= 200 && code < 300;
          bool isError() => code >= 400;
        }

        main() {
          var status = HttpStatus.fromCode(404);
          return [
            status.code,
            status.isSuccess(),
            status.isError(),
            HttpStatus.ok.isSuccess(),
            HttpStatus.serverError.isError()
          ];
        }
      ''';
      expect(execute(source), equals([404, false, true, true, true]));
    });

    test('Enum with complex pattern matching', () {
      const source = '''
        enum Shape {
          circle(0),
          square(4),
          triangle(3),
          pentagon(5);

          final int sides;
          const Shape(this.sides);

          String get description {
            switch (this) {
              case Shape.circle:
                return 'Perfect round shape';
              case Shape.square:
                return 'Four equal sides';
              case Shape.triangle:
                return 'Three sides';
              case Shape.pentagon:
                return 'Five sides';
            }
          }

          bool get isRegular => sides > 0;
        }

        main() {
          var shapes = Shape.values;
          return [
            shapes.map((s) => s.description).toList(),
            shapes.where((s) => s.isRegular).map((s) => s.sides).toList(),
            shapes.where((s) => !s.isRegular).map((s) => s.name).toList()
          ];
        }
      ''';
      expect(
          execute(source),
          equals([
            [
              'Perfect round shape',
              'Four equal sides',
              'Three sides',
              'Five sides'
            ],
            [4, 3, 5],
            ['circle']
          ]));
    });

    test('Enum with complex business logic', () {
      const source = '''
        enum UserRole {
          guest(0, ['read']),
          user(1, ['read', 'write']),
          moderator(2, ['read', 'write', 'delete']),
          admin(3, ['read', 'write', 'delete', 'manage']);

          final int level;
          final List<String> permissions;
          const UserRole(this.level, this.permissions);

          bool hasPermission(String permission) {
            return permissions.contains(permission);
          }

          bool canManage(UserRole other) {
            return level > other.level;
          }

          static UserRole fromLevel(int level) {
            return UserRole.values.firstWhere(
              (role) => role.level == level,
              orElse: () => UserRole.guest
            );
          }
        }

        main() {
          var admin = UserRole.admin;
          var user = UserRole.user;
          var guest = UserRole.guest;
          
          return [
            admin.hasPermission('manage'),
            user.hasPermission('manage'),
            admin.canManage(user),
            user.canManage(admin),
            UserRole.fromLevel(2).name,
            guest.permissions
          ];
        }
      ''';
      expect(
          execute(source),
          equals([
            true,
            false,
            true,
            false,
            'moderator',
            ['read']
          ]));
    });

    test('Enum with complex state management', () {
      const source = '''
        enum GameState {
          initial,
          playing,
          paused,
          gameOver;

          GameState next() {
            switch (this) {
              case GameState.initial:
                return GameState.playing;
              case GameState.playing:
                return GameState.paused;
              case GameState.paused:
                return GameState.playing;
              case GameState.gameOver:
                return GameState.initial;
            }
          }

          bool get canResume => this == GameState.paused;
          bool get isGameOver => this == GameState.gameOver;
        }

        class Game {
          GameState state = GameState.initial;
          int score = 0;

          void start() {
            if (state == GameState.initial) {
              state = GameState.playing;
            }
          }

          void pause() {
            if (state == GameState.playing) {
              state = GameState.paused;
            }
          }

          void resume() {
            if (state.canResume) {
              state = GameState.playing;
            }
          }

          void end() {
            state = GameState.gameOver;
          }

          void updateScore(int points) {
            if (state == GameState.playing) {
              score += points;
            }
          }
        }

        main() {
          var game = Game();
          var states = [];
          var scores = [];

          game.start();
          states.add(game.state.name);
          game.updateScore(10);
          scores.add(game.score);

          game.pause();
          states.add(game.state.name);
          game.updateScore(5); // Should not update
          scores.add(game.score);

          game.resume();
          states.add(game.state.name);
          game.updateScore(15);
          scores.add(game.score);

          game.end();
          states.add(game.state.name);
          game.updateScore(20); // Should not update
          scores.add(game.score);

          return [states, scores];
        }
      ''';
      expect(
          execute(source),
          equals([
            ['playing', 'paused', 'playing', 'gameOver'],
            [10, 10, 25, 25]
          ]));
    });
  });
}
