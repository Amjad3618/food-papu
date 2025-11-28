class AdminMdel {
  final String id;
  final String name;
  final String email;
  final String password;
  final DateTime createdAt;

  AdminMdel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.createdAt,
  });

  // Convert Admin to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create Admin from JSON
  factory AdminMdel.fromJson(Map<String, dynamic> json) {
    return AdminMdel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // Create a copy of Admin with updated fields
  AdminMdel copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    DateTime? createdAt,
  }) {
    return AdminMdel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Admin(id: $id, name: $name, email: $email, createdAt: $createdAt)';
  }
}