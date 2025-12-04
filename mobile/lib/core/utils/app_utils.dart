/// Utilitaires et extensions pour le code
/// Validations, formatages, etc.

class AppValidators {
  /// Valider une email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Valider un mot de passe (minimum 6 caractères)
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Valider un numéro de téléphone (au moins 10 chiffres)
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$');
    return phoneRegex.hasMatch(phone.replaceAll(' ', ''));
  }

  /// Valider un nom (minimum 2 caractères, pas de chiffres)
  static bool isValidName(String name) {
    return name.length >= 2 && !RegExp(r'[0-9]').hasMatch(name);
  }
}

class AppFormatters {
  /// Formater un numéro de ticket (ex: "A-123")
  static String formatTicketNumber(String ticketNumber) {
    return ticketNumber.toUpperCase();
  }

  /// Formater une date en format lisible
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Formater une heure
  static String formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Formater date et heure combinées
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${formatTime(dateTime)}';
  }

  /// Formater le temps d'attente estimé
  static String formatWaitTime(int minutes) {
    if (minutes < 1) {
      return 'Moins d\'une minute';
    } else if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
  }
}

/// Extensions sur String
extension StringExtensions on String {
  /// Vérifier si c'est un email valide
  bool get isValidEmail => AppValidators.isValidEmail(this);

  /// Capitaliser la première lettre
  String get capitalize => isEmpty ? this : this[0].toUpperCase() + substring(1);

  /// Tronquer avec ellipsis
  String truncate(int length) {
    return this.length > length ? '${substring(0, length)}...' : this;
  }
}

/// Extensions sur int
extension IntExtensions on int {
  /// Convertir en durée formatée
  String get asFormattedDuration {
    if (this < 1) return 'Moins d\'une minute';
    if (this < 60) return '$this min';
    final hours = this ~/ 60;
    final mins = this % 60;
    return '${hours}h ${mins}m';
  }
}

/// Extensions sur DateTime
extension DateTimeExtensions on DateTime {
  /// Formater en date lisible
  String get formattedDate => AppFormatters.formatDate(this);

  /// Formater en heure lisible
  String get formattedTime => AppFormatters.formatTime(this);

  /// Formater en date/heure lisible
  String get formattedDateTime => AppFormatters.formatDateTime(this);

  /// Vérifier si c'est aujourd'hui
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Vérifier si c'est hier
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }
}
