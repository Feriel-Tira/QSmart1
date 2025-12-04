# 📱 Mobile Frontend - Análise d'Incohérences

## 🔴 PROBLÈMES IDENTIFIÉS

### 1. **Configuration Hardcodée (CRITIQUE)**
- ❌ **Fichier**: `lib/graphql/client.dart`
- ❌ **Problème**: URL GraphQL en hardcoder
  ```dart
  static HttpLink httpLink = HttpLink(
    'http://localhost:4000/graphql',  // ← PROBLÈME: localhost
  );
  ```
- ❌ **Impact**: Impossible de changer l'URL en production, en staging, etc.
- ✅ **Solution**: Créer `lib/core/config/app_config.dart` avec gestion d'environnement

### 2. **Pas de Gestion d'Environnement**
- ❌ **Fichier**: `pubspec.yaml` + `main.dart`
- ❌ **Problème**: Aucune stratégie dev/prod/staging
- ❌ **Impact**: Configuration identique partout
- ✅ **Solution**: Implémenter `AppConfig` avec flavors (debug/release)

### 3. **Authentication Stub (CRITIQUE)**
- ❌ **Fichier**: `lib/graphql/client.dart:29`
  ```dart
  static Future<String?> _getToken() async {
    return null;  // ← TOUJOURS null!
  }
  ```
- ❌ **Problème**: Token jamais récupéré du secure storage
- ❌ **Impact**: Authentification jamais envoyée au serveur
- ✅ **Solution**: Implémenter vraie récupération depuis `flutter_secure_storage`

### 4. **Structure Dossiers Incomplète**
- ❌ **Manquent**: 
  - `lib/core/services/` (pas de services pour API calls)
  - `lib/core/repositories/` (pas de couche données)
  - `lib/core/models/` (pas de models)
  - `lib/core/constants/` (pas de constantes)
  - `lib/core/utils/` (pas d'utilitaires)
- ❌ **Impact**: Code répétitif et difficile à maintenir
- ✅ **Solution**: Créer structure complète Clean Architecture

### 5. **BloC partiellement implémenté**
- ⚠️ **Fichier**: `lib/features/auth/bloc/auth_bloc.dart`
- ⚠️ **Problème**: 
  - BloC défini mais implémentation incomplète
  - `mapEventToState()` peut être vide ou incomplète
  - Erreurs de gestion manquantes
- ✅ **Solution**: Finir l'implémentation des BloCs

### 6. **GraphQL Queries/Mutations Incomplets**
- ⚠️ **Fichier**: `lib/graphql/auth_mutations.dart`
- ⚠️ **Problème**: Pas vérifiée, probablement manquantes
- ✅ **Solution**: Implémenter mutations GraphQL complètes

### 7. **Pas de Models/DTOs**
- ❌ **Fichier**: Aucun fichier `lib/core/models/`
- ❌ **Problème**: Pas de typage des données GraphQL
- ❌ **Impact**: Risque de type casting errors
- ✅ **Solution**: Créer models User, Queue, Ticket, Notification

### 8. **Pas de Routes Fallback**
- ⚠️ **Fichier**: `lib/core/config/routes.dart`
- ⚠️ **Problème**: Pas de gestion d'erreur de route ou splash screen
- ✅ **Solution**: Implémenter SplashScreen + navigation intelligente

### 9. **Secure Storage pas Utilisé**
- ❌ **Problème**: `flutter_secure_storage` en dépendance mais pas utilisé
- ❌ **Impact**: Token/sensitive data stocké en plaintext potentiellement
- ✅ **Solution**: Implémenter `AuthRepository` avec `flutter_secure_storage`

### 10. **Pas de Gestion d'Erreur Globale**
- ❌ **Problème**: Pas de service pour gérer les erreurs API globalement
- ❌ **Impact**: Chaque appel GraphQL doit gérer ses erreurs
- ✅ **Solution**: Créer `lib/core/services/error_handler.dart`

---

## 📋 RÉSUMÉ DES FICHIERS ACTUELS

| Fichier | Status | Problème |
|---------|--------|---------|
| `pubspec.yaml` | ✅ OK | Dépendances présentes |
| `main.dart` | ✅ OK | Initialisation basique OK |
| `lib/graphql/client.dart` | ❌ CRITIQUE | URL hardcodée, token toujours null |
| `lib/graphql/auth_mutations.dart` | ⚠️ A VÉRIFIER | Contenu non analysé |
| `lib/core/config/routes.dart` | ⚠️ A VÉRIFIER | Pas de gestion erreur |
| `lib/core/config/theme.dart` | ⚠️ A VÉRIFIER | Thème basique |
| `lib/features/auth/bloc/auth_bloc.dart` | ⚠️ PARTIEL | Événements définis, logique incomplète |
| `lib/features/auth/pages/login_page.dart` | ⚠️ PARTIEL | UI définie, logique manquante |
| `lib/features/auth/pages/register_page.dart` | ⚠️ PARTIEL | UI définie, logique manquante |
| `lib/features/queue/bloc/queue_bloc.dart` | ⚠️ PARTIEL | À vérifier |
| `lib/features/queue/pages/home_page.dart` | ⚠️ PARTIEL | À vérifier |

---

## 🚀 PLAN DE CORRECTIONS (Priorisation)

### **PRIORITY 1 - CRITIQUE (Bloque tout)**
1. [ ] Créer `lib/core/config/app_config.dart` - Gestion d'environnement
2. [ ] Corriger `lib/graphql/client.dart` - URL dynamique + auth token
3. [ ] Implémenter `AuthRepository` avec secure storage
4. [ ] Finir `AuthBloc` avec logique complète

### **PRIORITY 2 - IMPORTANT (Infrastructure)**
5. [ ] Créer `lib/core/services/` structure (API client, error handler)
6. [ ] Créer `lib/core/models/` (User, Queue, Ticket, Notification)
7. [ ] Créer `lib/core/repositories/` (pattern clean architecture)
8. [ ] Créer `lib/core/constants/` et `lib/core/utils/`

### **PRIORITY 3 - FONCTIONNALITÉ**
9. [ ] Finir `AuthBloc` + pages
10. [ ] Implémenter `QueueBloc` complet
11. [ ] GraphQL queries/mutations
12. [ ] Pages UI finies

### **PRIORITY 4 - POLISH**
13. [ ] Gestion d'erreur globale
14. [ ] Routes avec fallback
15. [ ] Tests unitaires
16. [ ] Loading states + animations

---

## 📝 Notes Techniques

**Stack Utilisé**:
- Flutter/Dart (✓)
- BLoC pattern (⚠️ Partiellement)
- GraphQL (⚠️ Stub)
- State Management: BLoC (✓)
- Local Storage: SharedPreferences + SecureStorage (❌ Pas utilisé)
- HTTP Client: GraphQL only (⚠️ Pas de fallback REST)

**Manque Critique**: 
- Aucune séparation entre UI et logique métier
- Pas de layer repository/service
- Configuration en hardcoder
- Authentication stub

---

## 🔧 Fichiers à Créer

```
lib/core/
├── config/
│   ├── app_config.dart .............. [NEW] Gestion environnement
│   ├── routes.dart ................. [EXIST - À améliorer]
│   └── theme.dart .................. [EXIST]
├── constants/
│   ├── api_constants.dart ........... [NEW]
│   └── app_strings.dart ............. [NEW]
├── models/
│   ├── user_model.dart .............. [NEW]
│   ├── queue_model.dart ............. [NEW]
│   ├── ticket_model.dart ............ [NEW]
│   └── notification_model.dart ...... [NEW]
├── services/
│   ├── graphql_service.dart ......... [NEW]
│   ├── error_handler.dart ........... [NEW]
│   └── logger_service.dart .......... [NEW]
├── repositories/
│   ├── auth_repository.dart ......... [NEW]
│   ├── queue_repository.dart ........ [NEW]
│   └── user_repository.dart ......... [NEW]
└── utils/
    ├── extensions.dart .............. [NEW]
    └── validators.dart .............. [NEW]

lib/features/
├── auth/
│   ├── bloc/ ........................ [EXIST - À finir]
│   └── pages/ ....................... [EXIST - À finir]
├── queue/
│   ├── bloc/ ........................ [EXIST - À finir]
│   └── pages/ ....................... [EXIST - À finir]
└── ticket/ ........................... [NEW]
    ├── bloc/
    ├── pages/
    └── widgets/

lib/
├── main.dart ........................ [EXIST - À améliorer]
├── graphql/
│   ├── client.dart .................. [EXIST - À corriger]
│   └── queries/ ..................... [NEW]
│       ├── auth_queries.dart
│       ├── queue_queries.dart
│       └── ticket_queries.dart
└── shared/
    └── widgets/ ..................... [NEW]
        ├── loading_widget.dart
        ├── error_widget.dart
        └── app_bar.dart
```

---

**Analyse Date**: December 3, 2025  
**Status**: 🔴 Critique - Doit être corrigé avant production
