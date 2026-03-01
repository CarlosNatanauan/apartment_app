class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role; // TENANT | LANDLORD | ADMIN
  final String provider; // LOCAL | GOOGLE
  final DateTime? createdAt;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.provider = 'LOCAL',
    this.createdAt,
  });

  // Computed property for full name
  String get fullName => '$firstName $lastName';

  // From JSON (backend response)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['userId'] as String? ?? json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      provider: json['provider'] as String? ?? 'LOCAL',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  // To JSON (for storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'provider': provider,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  // Helpers
  bool get isLandlord => role == 'LANDLORD';
  bool get isTenant => role == 'TENANT';
  bool get isAdmin => role == 'ADMIN';
  bool get isGoogleUser => provider == 'GOOGLE';

  @override
  String toString() => 'User(id: $id, email: $email, name: $fullName, role: $role)';
}