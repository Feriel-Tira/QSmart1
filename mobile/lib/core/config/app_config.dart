/// Configuration centralisée de l'application
/// Gère les différents environnements (dev, staging, prod)

enum AppEnvironment { development, staging, production }

class AppConfig {
  static late final AppConfig _instance;
  static late final AppEnvironment _environment;

  final String apiUrl;
  final String graphqlEndpoint;
  final bool enableLogging;
  final bool enableErrorReporting;
  final String appName;
  final String version;

  AppConfig._({
    required this.apiUrl,
    required this.graphqlEndpoint,
    required this.enableLogging,
    required this.enableErrorReporting,
    required this.appName,
    required this.version,
  });

  /// Initialiser la configuration selon l'environnement
  static void initialize({
    AppEnvironment environment = AppEnvironment.development,
  }) {
    _environment = environment;

    late String apiUrl;
    late bool enableLogging;
    late bool enableErrorReporting;

    switch (environment) {
      case AppEnvironment.development:
        apiUrl = 'http://192.168.1.100:4000'; // À adapter pour localhost/IP
        enableLogging = true;
        enableErrorReporting = false;
        break;

      case AppEnvironment.staging:
        apiUrl = 'https://staging-api.smartqueue.com';
        enableLogging = true;
        enableErrorReporting = true;
        break;

      case AppEnvironment.production:
        apiUrl = 'https://api.smartqueue.com';
        enableLogging = false;
        enableErrorReporting = true;
        break;
    }

    _instance = AppConfig._(
      apiUrl: apiUrl,
      graphqlEndpoint: '$apiUrl/graphql',
      enableLogging: enableLogging,
      enableErrorReporting: enableErrorReporting,
      appName: 'SmartQueue',
      version: '1.0.0',
    );
  }

  /// Getter pour accéder à l'instance
  static AppConfig get instance {
    if (_instance == null) {
      initialize(); // Initialise avec env par défaut (dev)
    }
    return _instance;
  }

  /// Getter pour l'environnement actuel
  static AppEnvironment get environment => _environment;

  /// Vérifier si on est en production
  static bool get isProduction => _environment == AppEnvironment.production;

  /// Vérifier si on est en développement
  static bool get isDevelopment => _environment == AppEnvironment.development;

  /// URL complète GraphQL
  String get fullGraphqlUrl => graphqlEndpoint;

  /// URL pour les API REST (fallback)
  String get apiBaseUrl => apiUrl;

  @override
  String toString() => '''
AppConfig {
  environment: $_environment
  apiUrl: $apiUrl
  graphqlEndpoint: $graphqlEndpoint
  enableLogging: $enableLogging
  appName: $appName v$version
}
  ''';
}
