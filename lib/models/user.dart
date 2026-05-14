class User {
  final int? id;
  final String username;
  final String passwordHash;
  final String createdAt;

  User({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'created_at': createdAt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  User copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
