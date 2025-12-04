/// Service de gestion de l'authentification et du stockage sécurisé
/// Gère le token JWT et les données utilisateur

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smartqueue/core/models/user_model.dart';

class AuthService {
  static const String _tokenKey = 'smartqueue_auth_token';
  static const String _userKey = 'smartqueue_user_data';
  static const String _refreshTokenKey = 'smartqueue_refresh_token';

  final FlutterSecureStorage _secureStorage;

  AuthService({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Sauvegarder le token JWT
  Future<void> saveToken(String token) async {
    await _secureStorage.write(
      key: _tokenKey,
      value: token,
    );
  }

  /// Récupérer le token JWT
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// Sauvegarder le refresh token
  Future<void> saveRefreshToken(String refreshToken) async {
    await _secureStorage.write(
      key: _refreshTokenKey,
      value: refreshToken,
    );
  }

  /// Récupérer le refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  /// Sauvegarder les données utilisateur
  Future<void> saveUser(UserModel user) async {
    await _secureStorage.write(
      key: _userKey,
      value: _userToJson(user),
    );
  }

  /// Récupérer les données utilisateur
  Future<UserModel?> getUser() async {
    final userJson = await _secureStorage.read(key: _userKey);
    if (userJson == null) return null;
    
    try {
      // Ici on pourrait parser le JSON, mais on utilise directement le modèle
      return null; // À implémenter avec serialization
    } catch (e) {
      return null;
    }
  }

  /// Vérifier si on est authentifié
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Supprimer tous les tokens et données (logout)
  Future<void> clearAll() async {
    await Future.wait([
      _secureStorage.delete(key: _tokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
      _secureStorage.delete(key: _userKey),
    ]);
  }

  /// Convertir UserModel en JSON string
  String _userToJson(UserModel user) {
    // TODO: Implémenter la sérialisation
    return user.id;
  }

  /// Extraire le Bearer token
  String? extractBearerToken(String? token) {
    if (token == null || token.isEmpty) return null;
    if (token.startsWith('Bearer ')) {
      return token.substring(7);
    }
    return token;
  }

  /// Ajouter le Bearer prefix au token
  Future<String?> getAuthorizationHeader() async {
    final token = await getToken();
    if (token == null) return null;
    return 'Bearer $token';
  }

  /// Vérifier si le token expire bientôt (dans 5 minutes)
  bool isTokenExpiringSoon(String token) {
    // TODO: Décoder le JWT et vérifier l'expiration
    // Pour maintenant, c'est une implémentation simple
    return false;
  }
}
