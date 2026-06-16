import 'child_link.dart';

class Parent {
  final String id;
  final String fullName;
  final String email;
  final String verification;
  final List<ChildLink> children;

  Parent({
    required this.id,
    required this.fullName,
    required this.email,
    required this.verification,
    required this.children,
  });

  factory Parent.fromJson(Map<String, dynamic> json) {
    return Parent(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      verification: json['verification'],
      // Map children list
      children:
          (json['children'] as List).map((i) => ChildLink.fromJson(i)).toList(),
    );
  }
}
// ต้องมี ChildLink และ Child models ด้วย
// ... (ChildLink, Child models)
