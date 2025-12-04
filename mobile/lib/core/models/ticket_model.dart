/// Modèle de Ticket
/// Représente un numéro de ticket dans une queue

class TicketModel {
  final String id;
  final String ticketNumber; // Format: YYMMDD-XXXXX
  final String queueId;
  final String userId;
  final TicketStatus status;
  final int priority;
  final DateTime createdAt;
  final DateTime? calledAt;
  final DateTime? servedAt;
  final DateTime? expiredAt;
  final DateTime? updatedAt;

  TicketModel({
    required this.id,
    required this.ticketNumber,
    required this.queueId,
    required this.userId,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.calledAt,
    this.servedAt,
    this.expiredAt,
    this.updatedAt,
  });

  /// Calcul du temps d'attente en minutes
  int get waitTimeMinutes {
    final now = DateTime.now();
    return now.difference(createdAt).inMinutes;
  }

  /// Vérifier si le ticket est expiré
  bool get isExpired => expiredAt != null && DateTime.now().isAfter(expiredAt!);

  /// Copie avec modifications
  TicketModel copyWith({
    String? id,
    String? ticketNumber,
    String? queueId,
    String? userId,
    TicketStatus? status,
    int? priority,
    DateTime? createdAt,
    DateTime? calledAt,
    DateTime? servedAt,
    DateTime? expiredAt,
    DateTime? updatedAt,
  }) {
    return TicketModel(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      queueId: queueId ?? this.queueId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      calledAt: calledAt ?? this.calledAt,
      servedAt: servedAt ?? this.servedAt,
      expiredAt: expiredAt ?? this.expiredAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Créer depuis JSON
  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] ?? '',
      ticketNumber: json['ticketNumber'] ?? '',
      queueId: json['queueId'] ?? '',
      userId: json['userId'] ?? '',
      status: _parseStatus(json['status']),
      priority: json['priority'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      calledAt: json['calledAt'] != null ? DateTime.parse(json['calledAt']) : null,
      servedAt: json['servedAt'] != null ? DateTime.parse(json['servedAt']) : null,
      expiredAt: json['expiredAt'] != null ? DateTime.parse(json['expiredAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  /// Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketNumber': ticketNumber,
      'queueId': queueId,
      'userId': userId,
      'status': status.toString().split('.').last,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'calledAt': calledAt?.toIso8601String(),
      'servedAt': servedAt?.toIso8601String(),
      'expiredAt': expiredAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Parser le statut depuis string
  static TicketStatus _parseStatus(String? statusStr) {
    if (statusStr == null) return TicketStatus.waiting;
    switch (statusStr.toLowerCase()) {
      case 'called':
        return TicketStatus.called;
      case 'served':
        return TicketStatus.served;
      case 'cancelled':
        return TicketStatus.cancelled;
      case 'expired':
        return TicketStatus.expired;
      case 'waiting':
      default:
        return TicketStatus.waiting;
    }
  }

  @override
  String toString() => 'TicketModel(ticketNumber: $ticketNumber, status: ${status.toString()}, waitTime: ${waitTimeMinutes}min)';
}

/// Statuts possibles d'un ticket
enum TicketStatus {
  waiting,   // En attente
  called,    // Appelé au guichet
  served,    // Servi/Traité
  cancelled, // Annulé
  expired,   // Expiré
}
