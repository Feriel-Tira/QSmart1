/// Constantes de l'application
/// URLs, clés, timeouts, etc.

class AppConstants {
  // ========== TIMEOUTS ==========
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration graphqlTimeout = Duration(seconds: 15);

  // ========== GRAPHQL QUERIES & MUTATIONS ==========
  static const String loginQuery = r'''
    query Login($email: String!, $password: String!) {
      login(email: $email, password: $password) {
        token
        user {
          id
          name
          email
        }
      }
    }
  ''';

  // ========== LOCAL STORAGE KEYS ==========
  static const String authTokenKey = 'smartqueue_auth_token';
  static const String refreshTokenKey = 'smartqueue_refresh_token';
  static const String userDataKey = 'smartqueue_user_data';
  static const String appThemeKey = 'smartqueue_theme_mode';

  // ========== CACHE DURATION ==========
  static const Duration cacheQueueDuration = Duration(minutes: 5);
  static const Duration cacheUserDuration = Duration(hours: 1);
  static const Duration cacheTicketsDuration = Duration(minutes: 2);

  // ========== ERROR MESSAGES ==========
  static const String networkErrorMessage = 'Erreur réseau. Vérifiez votre connexion.';
  static const String authErrorMessage = 'Erreur d\'authentification. Veuillez vous reconnecter.';
  static const String timeoutErrorMessage = 'La requête a expiré. Réessayez.';
  static const String unknownErrorMessage = 'Une erreur inconnue est survenue.';

  // ========== NOTIFICATIONS ==========
  static const String notificationChannelId = 'smartqueue_notifications';
  static const String notificationChannelName = 'SmartQueue Notifications';

  // ========== API ENDPOINTS (si REST fallback) ==========
  static const String authEndpoint = '/api/auth';
  static const String queueEndpoint = '/api/queues';
  static const String ticketEndpoint = '/api/tickets';
  static const String userEndpoint = '/api/users';
}
