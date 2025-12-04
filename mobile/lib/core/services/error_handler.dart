/// Gestion centralisée des erreurs
/// Exception personnalisées et handler d'erreurs

class AppException implements Exception {
  final String message;
  final String? code;
  final Exception? originalException;

  AppException({
    required this.message,
    this.code,
    this.originalException,
  });

  @override
  String toString() => message;
}

/// Exception d'authentification
class AuthException extends AppException {
  AuthException({
    required String message,
    String? code,
    Exception? originalException,
  }) : super(
    message: message,
    code: code ?? 'AUTH_ERROR',
    originalException: originalException,
  );
}

/// Exception réseau
class NetworkException extends AppException {
  NetworkException({
    required String message,
    String? code,
    Exception? originalException,
  }) : super(
    message: message,
    code: code ?? 'NETWORK_ERROR',
    originalException: originalException,
  );
}

/// Exception serveur
class ServerException extends AppException {
  final int? statusCode;

  ServerException({
    required String message,
    this.statusCode,
    String? code,
    Exception? originalException,
  }) : super(
    message: message,
    code: code ?? 'SERVER_ERROR',
    originalException: originalException,
  );
}

/// Exception validation
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException({
    required String message,
    this.fieldErrors,
    String? code,
    Exception? originalException,
  }) : super(
    message: message,
    code: code ?? 'VALIDATION_ERROR',
    originalException: originalException,
  );
}

/// Handler centralisé des erreurs
class ErrorHandler {
  /// Gérer une exception et retourner un message d'erreur lisible
  static String getErrorMessage(Exception exception) {
    if (exception is AuthException) {
      return exception.message;
    } else if (exception is NetworkException) {
      return 'Erreur réseau. Vérifiez votre connexion.';
    } else if (exception is ServerException) {
      return exception.message;
    } else if (exception is ValidationException) {
      return exception.message;
    } else if (exception is AppException) {
      return exception.message;
    }

    return 'Une erreur inconnue est survenue.';
  }

  /// Obtenir le code d'erreur
  static String? getErrorCode(Exception exception) {
    if (exception is AppException) {
      return exception.code;
    }
    return null;
  }

  /// Vérifier si c'est une erreur d'authentification
  static bool isAuthError(Exception exception) {
    return exception is AuthException ||
        (exception is AppException && exception.code == 'AUTH_ERROR');
  }

  /// Vérifier si c'est une erreur réseau
  static bool isNetworkError(Exception exception) {
    return exception is NetworkException ||
        (exception is AppException && exception.code == 'NETWORK_ERROR');
  }

  /// Vérifier si c'est une erreur serveur
  static bool isServerError(Exception exception) {
    return exception is ServerException ||
        (exception is AppException && exception.code == 'SERVER_ERROR');
  }

  /// Log une erreur
  static void logError(Exception exception, {String? tag}) {
    final tagPrefix = tag != null ? '[$tag] ' : '';
    print('$tagPrefix❌ ERROR: ${exception.toString()}');
    
    if (exception is AppException && exception.originalException != null) {
      print('$tagPrefix  Original: ${exception.originalException}');
    }
  }
}
