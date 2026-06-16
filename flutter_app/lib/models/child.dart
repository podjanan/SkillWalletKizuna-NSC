// // ไม่จำเป็นต้อง import http ถ้าไฟล์นี้ใช้แค่ Data Model

// class Child {
//   final String id;
//   final String fullName;
//   final DateTime? dob; // อาจเป็น null ได้
//   final int score;
//   final int scoreUpdate; // อาจจะไม่ได้ใช้ใน Frontend โดยตรง แต่รวมไว้เผื่อ

//   Child({
//     required this.id,
//     required this.fullName,
//     this.dob,
//     required this.score,
//     required this.scoreUpdate,
//   });

//   factory Child.fromJson(Map<String, dynamic> json) {
//     return Child(
//       id: json['id'],
//       fullName: json['fullName'],
//       // แปลง String วันที่จาก JSON เป็น DateTime
//       dob: json['dob'] != null ? DateTime.parse(json['dob']) : null,
//       score: json['score'] ?? 0,
//       scoreUpdate: json['scoreUpdate'] ?? 0,
//     );
//   }
// }
