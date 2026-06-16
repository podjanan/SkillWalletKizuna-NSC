// lib/models/child_link.dart

// ✅ แก้ไข: import จาก child_model.dart แทน child.dart
import 'child_model.dart';

class ChildLink {
  final String relationship;
  final Child child;

  ChildLink({
    required this.relationship,
    required this.child,
  });

  // สร้าง Object จาก JSON ที่ได้จาก Parent API
  // รูปแบบ JSON: { "relationship": "Mother", "child": { ... Child Data ... } }
  factory ChildLink.fromJson(Map<String, dynamic> json) {
    return ChildLink(
      relationship: json['relationship'],
      // ใช้ Child.fromJson เพื่อแปลง Child Data ที่อยู่ข้างใน
      child: Child.fromJson(json['child']),
    );
  }

  // ✅ เพิ่ม toJson() method
  Map<String, dynamic> toJson() {
    return {
      'relationship': relationship,
      'child': child.toJson(),
    };
  }
}
