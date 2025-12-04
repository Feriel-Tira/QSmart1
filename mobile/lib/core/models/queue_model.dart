/// Modèle de Queue
/// Représente une file d'attente dans le système

class QueueModel {
  final String id;
  final String name;
  final String description;
  final int currentNumber;
  final int nextNumber;
  final int averageServiceTime; // en minutes
  final int maxActiveTickets;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  QueueModel({
    required this.id,
    required this.name,
    required this.description,
    required this.currentNumber,
    required this.nextNumber,
    required this.averageServiceTime,
    required this.maxActiveTickets,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  /// Copie avec modifications
  QueueModel copyWith({
    String? id,
    String? name,
    String? description,
    int? currentNumber,
    int? nextNumber,
    int? averageServiceTime,
    int? maxActiveTickets,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QueueModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      currentNumber: currentNumber ?? this.currentNumber,
      nextNumber: nextNumber ?? this.nextNumber,
      averageServiceTime: averageServiceTime ?? this.averageServiceTime,
      maxActiveTickets: maxActiveTickets ?? this.maxActiveTickets,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Créer depuis JSON
  factory QueueModel.fromJson(Map<String, dynamic> json) {
    return QueueModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      currentNumber: json['currentNumber'] ?? 0,
      nextNumber: json['nextNumber'] ?? 1,
      averageServiceTime: json['averageServiceTime'] ?? 5,
      maxActiveTickets: json['maxActiveTickets'] ?? 1,
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
      'description': description,
      'currentNumber': currentNumber,
      'nextNumber': nextNumber,
      'averageServiceTime': averageServiceTime,
      'maxActiveTickets': maxActiveTickets,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() => 'QueueModel(id: $id, name: $name, currentNumber: $currentNumber)';
}
