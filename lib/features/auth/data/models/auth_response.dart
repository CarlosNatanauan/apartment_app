import 'user_model.dart';

class LoginResponse {
  final String accessToken;
  final User? user; // Optional, might come from /auth/me

  LoginResponse({
    required this.accessToken,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}

class RegisterResponse {
  final String accessToken;
  final User? user;

  RegisterResponse({
    required this.accessToken,
    this.user,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      accessToken: json['accessToken'] as String,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}