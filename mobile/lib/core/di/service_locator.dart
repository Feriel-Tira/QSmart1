/// Service Locator - Gestion centralisée des dépendances
/// Utilise GetIt pour l'injection de dépendances

import 'package:get_it/get_it.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:smartqueue/core/config/app_config.dart';
import 'package:smartqueue/core/repositories/auth_repository.dart';
import 'package:smartqueue/core/repositories/queue_repository.dart';
import 'package:smartqueue/core/repositories/ticket_repository.dart';
import 'package:smartqueue/core/services/auth_service.dart';
import 'package:smartqueue/features/auth/bloc/auth_bloc.dart';
import 'package:smartqueue/features/queue/bloc/queue_bloc.dart';
import 'package:smartqueue/features/ticket/bloc/ticket_bloc.dart';
import 'package:smartqueue/graphql/client.dart';

final getIt = GetIt.instance;

/// Initialiser toutes les dépendances
Future<void> setupServiceLocator() async {
  // Initialiser la configuration
  AppConfig.initialize();

  // Services
  getIt.registerSingleton<AuthService>(
    AuthService(),
  );

  // Initializzare GraphQL con i servizi disponibili
  await GraphQLConfiguration.initialize();
  
  // Ottenere il client GraphQL
  final graphQLClient = GraphQLConfiguration.graphQLClient;

  // Repositories
  getIt.registerSingleton<AuthRepository>(
    AuthRepository(
      authService: getIt<AuthService>(),
    ),
  );

  getIt.registerSingleton<QueueRepository>(
    QueueRepository(graphQLClient: graphQLClient),
  );

  getIt.registerSingleton<TicketRepository>(
    TicketRepository(graphQLClient: graphQLClient),
  );

  // BLoCs
  getIt.registerSingleton<AuthBloc>(
    AuthBloc(
      authRepository: getIt<AuthRepository>(),
    ),
  );

  getIt.registerSingleton<QueueBloc>(
    QueueBloc(
      queueRepository: getIt<QueueRepository>(),
    ),
  );

  getIt.registerSingleton<TicketBloc>(
    TicketBloc(
      ticketRepository: getIt<TicketRepository>(),
    ),
  );

  if (AppConfig.instance.enableLogging) {
    print('✓ Service Locator initialized');
    print('  - AppConfig');
    print('  - AuthService');
    print('  - GraphQLConfiguration');
    print('  - AuthRepository');
    print('  - QueueRepository');
    print('  - TicketRepository');
    print('  - AuthBloc');
    print('  - QueueBloc');
    print('  - TicketBloc');
  }
}

/// Réinitialiser le service locator (utile pour les tests)
Future<void> resetServiceLocator() async {
  await getIt.reset();
  await setupServiceLocator();
}