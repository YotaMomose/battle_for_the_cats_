/// 獲得した猫の情報を保持するクラス
class WonCat {
  final String name;
  final int cost;

  WonCat({required this.name, required this.cost});

  Map<String, dynamic> toMap() {
    return {'name': name, 'cost': cost};
  }

  factory WonCat.fromMap(Map<String, dynamic> map) {
    return WonCat(name: map['name'] ?? '', cost: map['cost'] ?? 0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WonCat &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          cost == other.cost;

  @override
  int get hashCode => name.hashCode ^ cost.hashCode;
}
