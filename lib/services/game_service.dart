import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_room.dart';

class GameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ランダムなルームコードを生成 (6桁の英数字)
  String generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  // ルームを作成
  Future<String> createRoom(String hostId) async {
    final roomCode = generateRoomCode();
    final room = GameRoom(roomId: roomCode, hostId: hostId);

    await _firestore.collection('rooms').doc(roomCode).set(room.toMap());
    return roomCode;
  }

  // ルームに参加
  Future<bool> joinRoom(String roomCode, String guestId) async {
    final roomDoc = await _firestore.collection('rooms').doc(roomCode).get();

    if (!roomDoc.exists) {
      return false;
    }

    final room = GameRoom.fromMap(roomDoc.data()!);

    if (room.guestId != null) {
      return false; // すでにゲストがいる
    }

    await _firestore.collection('rooms').doc(roomCode).update({
      'guestId': guestId,
      'status': 'rolling', // サイコロフェーズから開始
    });

    return true;
  }

  // ルームの状態を監視
  Stream<GameRoom> watchRoom(String roomCode) {
    return _firestore
        .collection('rooms')
        .doc(roomCode)
        .snapshots()
        .map((snapshot) => GameRoom.fromMap(snapshot.data()!));
  }

  // 魚を賭ける（3匹の猫に対して）
  Future<void> placeBets(
    String roomCode,
    String playerId,
    Map<String, int> bets,
  ) async {
    final roomDoc = await _firestore.collection('rooms').doc(roomCode).get();
    final room = GameRoom.fromMap(roomDoc.data()!);

    final isHost = room.hostId == playerId;

    await _firestore.collection('rooms').doc(roomCode).update({
      isHost ? 'hostBets' : 'guestBets': bets,
      isHost ? 'hostReady' : 'guestReady': true,
    });

    // 両者が準備完了したら結果を判定
    final updatedDoc = await _firestore.collection('rooms').doc(roomCode).get();
    final updatedRoom = GameRoom.fromMap(updatedDoc.data()!);

    if (updatedRoom.hostReady && updatedRoom.guestReady) {
      await _resolveRound(roomCode, updatedRoom);
    }
  }

  // ラウンドの結果を判定（3匹の猫それぞれ）
  Future<void> _resolveRound(String roomCode, GameRoom room) async {
    final Map<String, String> winners = {};
    int hostWins = 0;
    int guestWins = 0;

    // 各猫について勝敗を判定
    for (int i = 0; i < 3; i++) {
      final catIndex = i.toString();
      final hostBet = room.hostBets[catIndex] ?? 0;
      final guestBet = room.guestBets[catIndex] ?? 0;

      if (hostBet > guestBet) {
        winners[catIndex] = 'host';
        hostWins++;
      } else if (guestBet > hostBet) {
        winners[catIndex] = 'guest';
        guestWins++;
      } else {
        winners[catIndex] = 'draw';
      }
    }

    // 累計獲得猫数を更新
    final newHostCatsWon = room.hostCatsWon + hostWins;
    final newGuestCatsWon = room.guestCatsWon + guestWins;

    // 勝利条件判定（3匹獲得）
    String finalStatus;
    String? finalWinner;

    if (newHostCatsWon >= 3 && newGuestCatsWon >= 3) {
      // 同時に3匹到達 → 引き分け
      finalStatus = 'finished';
      finalWinner = 'draw';
    } else if (newHostCatsWon >= 3) {
      // ホストの勝利
      finalStatus = 'finished';
      finalWinner = 'host';
    } else if (newGuestCatsWon >= 3) {
      // ゲストの勝利
      finalStatus = 'finished';
      finalWinner = 'guest';
    } else {
      // まだ勝敗がつかない → ラウンド結果表示
      finalStatus = 'roundResult';
      finalWinner = null;
    }

    await _firestore.collection('rooms').doc(roomCode).update({
      'winners': winners,
      'hostCatsWon': newHostCatsWon,
      'guestCatsWon': newGuestCatsWon,
      'status': finalStatus,
      'finalWinner': finalWinner,
    });
  }

  // サイコロを振る（1-6のランダムな目）
  Future<void> rollDice(String roomCode, String playerId) async {
    final roomDoc = await _firestore.collection('rooms').doc(roomCode).get();
    final room = GameRoom.fromMap(roomDoc.data()!);

    final isHost = room.hostId == playerId;
    final random = Random();
    final diceRoll = random.nextInt(6) + 1; // 1-6のランダムな数

    await _firestore.collection('rooms').doc(roomCode).update({
      isHost ? 'hostDiceRoll' : 'guestDiceRoll': diceRoll,
      isHost ? 'hostRolled' : 'guestRolled': true,
      isHost ? 'hostFishCount' : 'guestFishCount': diceRoll,
    });

    // 両者がサイコロを振ったらplayingフェーズに移行
    final updatedDoc = await _firestore.collection('rooms').doc(roomCode).get();
    final updatedRoom = GameRoom.fromMap(updatedDoc.data()!);

    if (updatedRoom.hostRolled && updatedRoom.guestRolled) {
      await _firestore.collection('rooms').doc(roomCode).update({
        'status': 'playing',
      });
    }
  }

  // 次のターンへ進む
  Future<void> nextTurn(String roomCode) async {
    final roomDoc = await _firestore.collection('rooms').doc(roomCode).get();
    final room = GameRoom.fromMap(roomDoc.data()!);

    await _firestore.collection('rooms').doc(roomCode).update({
      'currentTurn': room.currentTurn + 1,
      'status': 'rolling', // サイコロフェーズに移行
      'hostDiceRoll': null,
      'guestDiceRoll': null,
      'hostRolled': false,
      'guestRolled': false,
      'hostFishCount': 0, // サイコロで決定
      'guestFishCount': 0,
      'hostBets': {'0': 0, '1': 0, '2': 0}, // 賭けをリセット
      'guestBets': {'0': 0, '1': 0, '2': 0},
      'hostReady': false,
      'guestReady': false,
      'winners': null,
    });
  }

  // ルームを削除
  Future<void> deleteRoom(String roomCode) async {
    await _firestore.collection('rooms').doc(roomCode).delete();
  }

  // ランダムマッチング: 待機リストに登録
  Future<String> joinMatchmaking(String playerId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    await _firestore.collection('matchmaking').doc(playerId).set({
      'playerId': playerId,
      'timestamp': timestamp,
      'status': 'waiting',
    });

    return playerId;
  }

  // ランダムマッチング: 待機中のプレイヤーを監視してマッチング
  Stream<String?> watchMatchmaking(String playerId) async* {
    // 自分の matchmaking ドキュメントが更新されるのを監視
    await for (final snapshot
        in _firestore.collection('matchmaking').doc(playerId).snapshots()) {
      if (!snapshot.exists) {
        yield null;
        return;
      }

      final data = snapshot.data()!;
      final status = data['status'] as String;

      // マッチング成立した場合
      if (status == 'matched') {
        final roomCode = data['roomCode'] as String?;
        yield roomCode;
        return;
      }

      //------------------------------------------
      // まだ待機中の場合、自分から相手を探す
      if (status == 'waiting') {
        await _tryToMatch(playerId);
        //ここでマッチングが成功したら次のループで検出される
        yield null; // まだマッチングしていない
      }
    }
  }

  // 相手を探してマッチング試行（トランザクションで制御）
  Future<void> _tryToMatch(String playerId) async {
    try {
      // トランザクション外で待機中のプレイヤーを検索
      final querySnapshot = await _firestore
          .collection('matchmaking')
          .where('status', isEqualTo: 'waiting')
          .orderBy('timestamp')
          .limit(10)
          .get();

      // 自分以外の最初の相手を探す
      String? opponentId;
      for (final doc in querySnapshot.docs) {
        if (doc.id != playerId) {
          opponentId = doc.id;
          break;
        }
      }

      // 相手が見つからない場合は何もしない
      if (opponentId == null) {
        return;
      }

      // トランザクションでマッチング処理
      await _firestore.runTransaction((transaction) async {
        // 両プレイヤーの現在の状態を確認
        final myRef = _firestore.collection('matchmaking').doc(playerId);
        final opponentRef = _firestore
            .collection('matchmaking')
            .doc(opponentId);

        final myDoc = await transaction.get(myRef);
        final opponentDoc = await transaction.get(opponentRef);

        // どちらかが既にマッチング済みの場合は中断
        if (!myDoc.exists || !opponentDoc.exists) {
          return;
        }

        final myStatus = myDoc.data()?['status'];
        final opponentStatus = opponentDoc.data()?['status'];

        if (myStatus != 'waiting' || opponentStatus != 'waiting') {
          return;
        }

        // ルームを作成
        final roomCode = generateRoomCode();
        final room = GameRoom(
          roomId: roomCode,
          hostId: playerId,
          guestId: opponentId,
          status: 'rolling', // サイコロフェーズから開始
        );

        // トランザクション内でルームを作成
        final roomRef = _firestore.collection('rooms').doc(roomCode);
        transaction.set(roomRef, room.toMap());

        // 両プレイヤーのマッチング状態を更新
        transaction.update(myRef, {
          'status': 'matched',
          'roomCode': roomCode,
          'isHost': true,
        });

        transaction.update(opponentRef, {
          'status': 'matched',
          'roomCode': roomCode,
          'isHost': false,
        });
      });
    } catch (e) {
      // トランザクション失敗（競合が発生した場合など）
      // 何もせずに次の監視サイクルで再試行
    }
  }

  // ランダムマッチングをキャンセル
  Future<void> cancelMatchmaking(String playerId) async {
    await _firestore.collection('matchmaking').doc(playerId).delete();
  }

  // マッチング情報からホストかどうかを取得
  Future<bool> isHostInMatch(String playerId) async {
    final doc = await _firestore.collection('matchmaking').doc(playerId).get();
    return doc.data()?['isHost'] as bool? ?? true;
  }
}
