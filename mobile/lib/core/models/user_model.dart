/// Modèle utilisateur
/// Représente un utilisateur du système

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatar;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatar,
    this.role = UserRole.user,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// Créer une copie avec modifications
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Créer depuis JSON (GraphQL response)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'],
      role: _parseRole(json['role']),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  /// Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'role': role.toString().split('.').last,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Parser le rôle depuis string
  static UserRole _parseRole(String? roleStr) {
    if (roleStr == null) return UserRole.user;
    switch (roleStr.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'operator':
        return UserRole.operator;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  @override
  String toString() => 'UserModel(id: $id, name: $name, email: $email, role: ${role.toString()})';
}

/// Énumération des rôles utilisateur
enum UserRole {
  user,      // Citoyen/client
  operator,  // Opérateur de queue
  admin,     // Administrateur
}

/// Extension methods for UserRole
extension UserRoleExtension on UserRole {
  /// Convertir en string
  String toShortString() {
    return toString().split('.').last;
  }

  /// Afficher le rôle en français
  String toDisplayString() {
    switch (this) {
      case UserRole.user:
        return 'Utilisateur';
      case UserRole.operator:
        return 'Opérateur';
      case UserRole.admin:
        return 'Administrateur';
    }
  }
}
