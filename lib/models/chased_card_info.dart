/// 犬の効果で追い出されたカードの情報
class ChasedCardInfo {
  final String cardName;
  final String chaserPlayerId;

  ChasedCardInfo({required this.cardName, required this.chaserPlayerId});

  Map<String, dynamic> toMap() {
    return {'cardName': cardName, 'chaserPlayerId': chaserPlayerId};
  }

  factory ChasedCardInfo.fromMap(Map<String, dynamic> map) {
    return ChasedCardInfo(
      cardName: map['cardName'] ?? '',
      chaserPlayerId: map['chaserPlayerId'] ?? '',
    );
  }
}
