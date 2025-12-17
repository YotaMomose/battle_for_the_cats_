import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_room.dart';

class GameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // ランダムなルームコードを生成 (6桁の英数字)
  String generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // ルームを作成
  Future<String> createRoom(String hostId) async {
    final roomCode = generateRoomCode();
    final room = GameRoom(
      roomId: roomCode,
      hostId: hostId,
    );
    
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
      'status': 'playing',
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

  // 魚を賭ける
  Future<void> placeBet(String roomCode, String playerId, int betAmount) async {
    final roomDoc = await _firestore.collection('rooms').doc(roomCode).get();
    final room = GameRoom.fromMap(roomDoc.data()!);
    
    final isHost = room.hostId == playerId;
    
    await _firestore.collection('rooms').doc(roomCode).update({
      isHost ? 'hostBet' : 'guestBet': betAmount,
      isHost ? 'hostReady' : 'guestReady': true,
    });
    
    // 両者が準備完了したら結果を判定
    final updatedDoc = await _firestore.collection('rooms').doc(roomCode).get();
    final updatedRoom = GameRoom.fromMap(updatedDoc.data()!);
    
    if (updatedRoom.hostReady && updatedRoom.guestReady) {
      await _resolveRound(roomCode, updatedRoom);
    }
  }

  // ラウンドの結果を判定
  Future<void> _resolveRound(String roomCode, GameRoom room) async {
    final hostBet = room.hostBet ?? 0;
    final guestBet = room.guestBet ?? 0;
    
    String? winner;
    if (hostBet > guestBet) {
      winner = 'host';
    } else if (guestBet > hostBet) {
      winner = 'guest';
    } else {
      winner = 'draw';
    }
    
    await _firestore.collection('rooms').doc(roomCode).update({
      'winner': winner,
      'status': 'finished',
    });
  }

  // ルームを削除
  Future<void> deleteRoom(String roomCode) async {
    await _firestore.collection('rooms').doc(roomCode).delete();
  }
}
