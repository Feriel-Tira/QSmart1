import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:smartqueue/core/config/app_config.dart';
import 'package:smartqueue/core/services/auth_service.dart';

class GraphQLConfiguration {
  static late AuthService _authService;
  static late HttpLink _httpLink;
  static late AuthLink _authLink;
  static late Link _link;
  static late ValueNotifier<GraphQLClient> _client;

  /// Initialiser le client GraphQL
  static Future<void> initialize() async {
    _authService = AuthService();

    // URL dynamique depuis AppConfig
    _httpLink = HttpLink(
      AppConfig.instance.fullGraphqlUrl,
      httpClient: null,
    );

    // Auth link avec vrai token depuis secure storage
    _authLink = AuthLink(
      getToken: () async {
        return await _authService.getAuthorizationHeader();
      },
    );

    // Combiner les links
    _link = _authLink.concat(_httpLink);

    // Créer le client GraphQL
    _client = ValueNotifier(
      GraphQLClient(
        link: _link,
        cache: GraphQLCache(
          store: InMemoryStore(),
        ),
        defaultPolicies: DefaultPolicies(
          watchQuery: Policies(
            fetch: FetchPolicy.cacheAndNetwork,
            error: ErrorPolicy.all,
          ),
          query: Policies(
            fetch: FetchPolicy.networkOnly,
            error: ErrorPolicy.all,
          ),
          mutate: Policies(
            fetch: FetchPolicy.networkOnly,
            error: ErrorPolicy.all,
          ),
        ),
      ),
    );

    if (AppConfig.instance.enableLogging) {
      print('✓ GraphQL Client initialized');
      print('  URL: ${AppConfig.instance.fullGraphqlUrl}');
      print('  Environment: ${AppConfig.environment}');
    }
  }

  /// Getter per il client GraphQL
  static ValueNotifier<GraphQLClient> get client => _client;

  /// Getter per il servizio GraphQL diretto
  static GraphQLClient get graphQLClient => _client.value;

  /// Réinitialiser le client (utile après logout)
  static Future<void> reinitialize() async {
    await initialize();
  }
}

class GraphQLProviderWidget extends StatefulWidget {
  final Widget child;

  const GraphQLProviderWidget({super.key, required this.child});

  @override
  State<GraphQLProviderWidget> createState() => _GraphQLProviderWidgetState();
}

class _GraphQLProviderWidgetState extends State<GraphQLProviderWidget> {
  @override
  void initState() {
    super.initState();
    _initializeGraphQL();
  }

  Future<void> _initializeGraphQL() async {
    try {
      await GraphQLConfiguration.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (AppConfig.instance.enableLogging) {
        print('Error initializing GraphQL: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: GraphQLConfiguration.client,
      child: widget.child,
    );
  }
}