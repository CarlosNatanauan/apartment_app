class User {
  final String id;
  final String email;
  final String role; // TENANT | LANDLORD | ADMIN
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    required this.role,
    this.createdAt,
  });

  // From JSON (backend response)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['userId'] as String? ?? json['id'] as String, // ✅ Backend returns 'userId'
      email: json['email'] as String,
      role: json['role'] as String,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  // To JSON (for storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  // Helpers
  bool get isLandlord => role == 'LANDLORD';
  bool get isTenant => role == 'TENANT';
  bool get isAdmin => role == 'ADMIN';

  @override
  String toString() => 'User(id: $id, email: $email, role: $role)';
}