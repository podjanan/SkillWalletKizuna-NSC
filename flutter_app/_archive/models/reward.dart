class Reward {
  final String id;
  final String name;
  final int cost;
  // คุณอาจเพิ่ม field อื่นๆ ที่ Backend ส่งมา เช่น description หรือ imageUrl (ถ้ามี)

  Reward({
    required this.id,
    required this.name,
    required this.cost,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'],
      name: json['name'],
      cost: json['cost'],
    );
  }
}
