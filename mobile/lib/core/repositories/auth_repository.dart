/// Repository pour la gestion de l'authentification
/// Couche entre les BloCs et les services GraphQL

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:smartqueue/core/models/user_model.dart';
import 'package:smartqueue/core/services/auth_service.dart';
import 'package:smartqueue/graphql/client.dart';

class AuthRepository {
  final AuthService _authService;
  final GraphQLClient _graphqlClient;

  AuthRepository({
    AuthService? authService,
  })  : _authService = authService ?? AuthService(),
        _graphqlClient = GraphQLConfiguration.client.value;

  /// Connexion utilisateur
  /// Retourne l'utilisateur si succès, lance une exception sinon
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    const loginMutation = r'''
      mutation Login($email: String!, $password: String!) {
        login(email: $email, password: $password) {
          token
          refreshToken
          user {
            id
            name
            email
            phone
            role
            avatar
            isActive
            createdAt
            updatedAt
          }
        }
      }
    ''';

    try {
      final result = await _graphqlClient.mutate(
        MutationOptions(
          document: gql(loginMutation),
          variables: {
            'email': email,
            'password': password,
          },
        ),
      );

      if (result.hasException) {
        throw _handleGraphQLException(result.exception!);
      }

      final data = result.data?['login'];
      if (data == null) {
        throw Exception('Login failed: Invalid response');
      }

      // Sauvegarder les tokens
      await _authService.saveToken(data['token']);
      if (data['refreshToken'] != null) {
        await _authService.saveRefreshToken(data['refreshToken']);
      }

      // Créer et retourner l'utilisateur
      final user = UserModel.fromJson(data['user']);
      await _authService.saveUser(user);

      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// Inscription utilisateur
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    const registerMutation = r'''
      mutation Register($name: String!, $email: String!, $password: String!, $phone: String!) {
        register(name: $name, email: $email, password: $password, phone: $phone) {
          token
          refreshToken
          user {
            id
            name
            email
            phone
            role
            avatar
            isActive
            createdAt
            updatedAt
          }
        }
      }
    ''';

    try {
      final result = await _graphqlClient.mutate(
        MutationOptions(
          document: gql(registerMutation),
          variables: {
            'name': name,
            'email': email,
            'password': password,
            'phone': phone,
          },
        ),
      );

      if (result.hasException) {
        throw _handleGraphQLException(result.exception!);
      }

      final data = result.data?['register'];
      if (data == null) {
        throw Exception('Registration failed: Invalid response');
      }

      // Sauvegarder les tokens
      await _authService.saveToken(data['token']);
      if (data['refreshToken'] != null) {
        await _authService.saveRefreshToken(data['refreshToken']);
      }

      // Créer et retourner l'utilisateur
      final user = UserModel.fromJson(data['user']);
      await _authService.saveUser(user);

      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    try {
      // Appel optionnel au serveur pour invalider la session
      const logoutMutation = r'''
        mutation Logout {
          logout
        }
      ''';

      await _graphqlClient.mutate(
        MutationOptions(
          document: gql(logoutMutation),
        ),
      );
    } catch (e) {
      // Continuer même si l'appel serveur échoue
    } finally {
      // Toujours nettoyer les données locales
      await _authService.clearAll();
    }
  }

  /// Vérifier si l'utilisateur est authentifié
  Future<bool> isAuthenticated() async {
    return await _authService.isAuthenticated();
  }

  /// Récupérer le token actuel
  Future<String?> getToken() async {
    return await _authService.getToken();
  }

  /// Rafraîchir le token
  Future<String> refreshToken() async {
    final refreshToken = await _authService.getRefreshToken();
    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }

    const refreshMutation = r'''
      mutation RefreshToken($refreshToken: String!) {
        refreshToken(refreshToken: $refreshToken) {
          token
          refreshToken
        }
      }
    ''';

    try {
      final result = await _graphqlClient.mutate(
        MutationOptions(
          document: gql(refreshMutation),
          variables: {'refreshToken': refreshToken},
        ),
      );

      if (result.hasException) {
        throw _handleGraphQLException(result.exception!);
      }

      final data = result.data?['refreshToken'];
      if (data == null) {
        throw Exception('Failed to refresh token');
      }

      final newToken = data['token'];
      await _authService.saveToken(newToken);

      if (data['refreshToken'] != null) {
        await _authService.saveRefreshToken(data['refreshToken']);
      }

      return newToken;
    } catch (e) {
      // Si le refresh échoue, logout
      await _authService.clearAll();
      rethrow;
    }
  }

  /// Gestion des exceptions GraphQL
  Exception _handleGraphQLException(OperationException exception) {
    if (exception.graphqlErrors.isNotEmpty) {
      final error = exception.graphqlErrors.first;
      return Exception(error.message);
    }
    if (exception.linkException != null) {
      return Exception('Network error: ${exception.linkException}');
    }
    return Exception('Unknown error');
  }
}
