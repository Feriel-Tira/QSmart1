import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smartqueue/core/models/models.dart';
import 'package:smartqueue/core/repositories/repositories.dart';
import 'package:smartqueue/core/services/error_handler.dart';
import 'package:smartqueue/core/di/service_locator.dart';

/// ============= EVENTS =============

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Événement de login
class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Événement de registration
class RegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final String phone;

  const RegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
  });

  @override
  List<Object?> get props => [name, email, password, phone];
}

/// Événement de logout
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Événement de vérification d'authentification au démarrage
class AuthStatusChecked extends AuthEvent {
  const AuthStatusChecked();
}

/// ============= STATES =============

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// État initial
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// État de chargement
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// État authentifié (succès)
class AuthAuthenticated extends AuthState {
  final UserModel user;
  final String token;

  const AuthAuthenticated({
    required this.user,
    required this.token,
  });

  @override
  List<Object?> get props => [user, token];
}

/// État non authentifié
class AuthUnauthenticated extends AuthState {
  final String? message;

  const AuthUnauthenticated({this.message});

  @override
  List<Object?> get props => [message];
}

/// État erreur
class AuthError extends AuthState {
  final String message;
  final String? code;

  const AuthError({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// ============= BLOC =============

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({AuthRepository? authRepository})
      : _authRepository = authRepository ?? getIt<AuthRepository>(),
        super(const AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthStatusChecked>(_onAuthStatusChecked);
  }

  /// Gérer la demande de login
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );

      final token = await _authRepository.getToken();
      
      if (token != null) {
        emit(AuthAuthenticated(user: user, token: token));
      } else {
        emit(const AuthError(
          message: 'Impossible de récupérer le token',
          code: 'TOKEN_NOT_FOUND',
        ));
      }
    } on AuthException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } catch (e) {
      final message = ErrorHandler.getErrorMessage(e as Exception);
      emit(AuthError(message: message));
    }
  }

  /// Gérer la demande de registration
  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final user = await _authRepository.register(
        name: event.name,
        email: event.email,
        password: event.password,
        phone: event.phone,
      );

      final token = await _authRepository.getToken();
      
      if (token != null) {
        emit(AuthAuthenticated(user: user, token: token));
      } else {
        emit(const AuthError(
          message: 'Impossible de récupérer le token',
          code: 'TOKEN_NOT_FOUND',
        ));
      }
    } on AuthException catch (e) {
      emit(AuthError(message: e.message, code: e.code));
    } catch (e) {
      final message = ErrorHandler.getErrorMessage(e as Exception);
      emit(AuthError(message: message));
    }
  }

  /// Gérer le logout
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      // Même en cas d'erreur, on logout localement
      emit(const AuthUnauthenticated());
    }
  }

  /// Vérifier si l'utilisateur est authentifié au démarrage
  Future<void> _onAuthStatusChecked(
    AuthStatusChecked event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final isAuthenticated = await _authRepository.isAuthenticated();
      
      if (isAuthenticated) {
        final token = await _authRepository.getToken();
        // Ici on pourrait charger les données utilisateur depuis le cache
        // Pour l'instant, on considère juste que c'est authentifié
        emit(AuthAuthenticated(
          user: UserModel(
            id: '',
            name: '',
            email: '',
            phone: '',
            createdAt: DateTime.now(),
          ),
          token: token ?? '',
        ));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }
}