// lib/models/auth_response_model.dart
import 'user_model.dart';

class AuthResponse {
  final String? token;
  final User user;
  final String? url;
  final bool redirect;

  AuthResponse({
    this.token,
    required this.user,
    this.url,
    this.redirect = false,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String?,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      url: json['url'] as String?,
      redirect: json['redirect'] as bool? ?? false,
    );
  }
}
