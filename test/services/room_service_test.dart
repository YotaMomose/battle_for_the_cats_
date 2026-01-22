import 'package:flutter_test/flutter_test.dart';
import 'package:battle_for_the_cats/services/room_service.dart';
import 'package:battle_for_the_cats/models/game_room.dart';
import '../mocks/mock_room_repository.dart';
import '../helpers/test_fixtures.dart';

void main() {
  group('RoomService - 詳細なMockテスト', () {
    late RoomService roomService;
    late MockRoomRepository mockRepository;

    setUp(() {
      mockRepository = MockRoomRepository();
      roomService = RoomService(repository: mockRepository);
    });

    group('generateRoomCode', () {
      test('ルームコードが6文字で生成される', () {
        // Act
        final roomCode = roomService.generateRoomCode();

        // Assert
        expect(roomCode, hasLength(6));
      });

      test('ルームコードは大文字英数字のみで構成される', () {
        // Act & Assert
        for (int i = 0; i < 100; i++) {
          final roomCode = roomService.generateRoomCode();
          expect(roomCode, matches(RegExp(r'^[A-Z0-9]{6}$')));
        }
      });

      test('異なるルームコードが生成される', () {
        // Act
        final codes = <String>{};
        for (int i = 0; i < 50; i++) {
          codes.add(roomService.generateRoomCode());
        }

        // Assert: 50回生成で衝突がないはず
        expect(codes.length, 50);
      });

      test('連続したルームコード生成でユニークネスが保証される（1000回）', () {
        // Act
        final codes = <String>{};
        for (int i = 0; i < 1000; i++) {
          codes.add(roomService.generateRoomCode());
        }

        // Assert: 1000回生成で衝突がないはず
        expect(codes.length, 1000);
      });

      test('各位置でランダムな文字が出現する', () {
        // Act
        final codeSet = <String>{};
        for (int i = 0; i < 500; i++) {
          codeSet.add(roomService.generateRoomCode());
        }

        // 各位置で複数の異なる文字が出現しているかチェック
        final charsByPosition = <int, Set<String>>{};
        for (int pos = 0; pos < 6; pos++) {
          charsByPosition[pos] = <String>{};
        }

        for (final code in codeSet) {
          for (int pos = 0; pos < 6; pos++) {
            charsByPosition[pos]!.add(code[pos]);
          }
        }

        // Assert: 各位置で3種類以上の異なる文字が出現
        for (int pos = 0; pos < 6; pos++) {
          expect(charsByPosition[pos]!.length, greaterThanOrEqualTo(3),
              reason: '位置 $pos での多様性が不足');
        }
      });
    });

    group('createRoom', () {
      test('ルームコードが文字列で返される', () async {
        // Arrange
        const hostId = 'host123';

        // Act
        final roomCode = await roomService.createRoom(hostId);

        // Assert
        expect(roomCode, isNotNull);
        expect(roomCode, isNotEmpty);
        expect(roomCode, matches(RegExp(r'^[A-Z0-9]{6}$')));
      });

      test('作成されたルームコードはユニークである', () async {
        // Arrange
        const hostId = 'host123';

        // Act
        final roomCode1 = await roomService.createRoom(hostId);
        final roomCode2 = await roomService.createRoom(hostId);

        // Assert
        expect(roomCode1, isNotEmpty);
        expect(roomCode2, isNotEmpty);
        expect(roomCode1, isNot(equals(roomCode2)));
      });

      test('複数のルームコード生成がユニークである', () async {
        // Arrange
        const hostId = 'host123';

        // Act
        final roomCodes = <String>{};
        for (int i = 0; i < 10; i++) {
          roomCodes.add(await roomService.createRoom(hostId));
        }

        // Assert: 10回作成で10個のユニークなコードが生成される
        expect(roomCodes.length, equals(10));
      });

      test('生成されるルームコードが正しい形式である', () async {
        // Arrange
        const hostId = 'host123';

        // Act
        final roomCode = await roomService.createRoom(hostId);

        // Assert
        expect(roomCode.length, equals(6));
        expect(roomCode, matches(RegExp(r'^[A-Z0-9]{6}$')));
        
        // 小文字がない
        expect(roomCode, isNot(matches(RegExp(r'[a-z]'))));
        
        // スペースなし
        expect(roomCode, isNot(matches(RegExp(r'\s'))));
      });

      test('異なるホストで作成されたルームコードは異なる', () async {
        // Arrange
        const hostId1 = 'host1';
        const hostId2 = 'host2';

        // Act
        final roomCode1 = await roomService.createRoom(hostId1);
        final roomCode2 = await roomService.createRoom(hostId2);

        // Assert
        expect(roomCode1, isNotEmpty);
        expect(roomCode2, isNotEmpty);
        expect(roomCode1, isNot(equals(roomCode2)));
      });
    });

    group('ルーム管理のエッジケース', () {
      test('複数の同時ルーム作成が独立している', () async {
        // Arrange
        const hostIds = ['host1', 'host2', 'host3', 'host4'];

        // Act
        final roomCodes = <String>[];
        for (final hostId in hostIds) {
          roomCodes.add(await roomService.createRoom(hostId));
        }

        // Assert: すべてのルームコードがユニークで独立している
        expect(roomCodes.length, equals(4));
        for (int i = 0; i < roomCodes.length; i++) {
          for (int j = i + 1; j < roomCodes.length; j++) {
            expect(roomCodes[i], isNot(equals(roomCodes[j])));
          }
        }
      });

      test('ルーム作成時のルームコード形式が正しい', () async {
        // Arrange
        const hostId = 'host_comprehensive_test';

        // Act
        final roomCode = await roomService.createRoom(hostId);

        // Assert
        expect(roomCode, isNotEmpty);
        expect(roomCode, matches(RegExp(r'^[A-Z0-9]{6}$')));
      });
    });

    group('RoomCode形式の検証', () {
      test('生成されるルームコードのフォーマット検証（大文字英数字のみ）', () {
        // Act & Assert
        for (int i = 0; i < 200; i++) {
          final roomCode = roomService.generateRoomCode();
          
          // 6文字確認
          expect(roomCode.length, equals(6));
          
          // 大文字英数字のみ確認
          for (final char in roomCode.split('')) {
            final isUppercase = RegExp(r'[A-Z0-9]').hasMatch(char);
            expect(isUppercase, isTrue,
                reason: 'ルームコード "$roomCode" に不正な文字 "$char" が含まれています');
          }
        }
      });

      test('ルームコードに小文字が含まれていない', () {
        // Act & Assert
        for (int i = 0; i < 100; i++) {
          final roomCode = roomService.generateRoomCode();
          
          // 小文字がないことを確認
          expect(roomCode, isNot(matches(RegExp(r'[a-z]'))),
              reason: 'ルームコード "$roomCode" に小文字が含まれています');
        }
      });

      test('ルームコードに特殊文字が含まれていない', () {
        // Act & Assert
        for (int i = 0; i < 100; i++) {
          final roomCode = roomService.generateRoomCode();
          
          // 正規表現が正しく英数字のみ
          expect(roomCode, matches(RegExp(r'^[A-Z0-9]{6}$')),
              reason: 'ルームコード "$roomCode" が正しい形式ではありません');
        }
      });

      test('ルームコード全体の検証（複合条件）', () {
        // Act
        final generatedCodes = <String>[];
        for (int i = 0; i < 500; i++) {
          generatedCodes.add(roomService.generateRoomCode());
        }

        // Assert
        for (final code in generatedCodes) {
          // 長さ
          expect(code.length, equals(6));
          
          // 大文字英数字のみ
          expect(code, matches(RegExp(r'^[A-Z0-9]{6}$')));
          
          // 小文字なし
          expect(code, isNot(matches(RegExp(r'[a-z]'))));
          
          // スペースなし
          expect(code, isNot(matches(RegExp(r'\s'))));
        }
      });
    });
  });
}
