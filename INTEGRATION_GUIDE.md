# API Integration Guide

Complete guide for integrating the Flutter frontend with the Node.js backend API.

---

## 🎯 **Overview**

The frontend is architecturally ready for API integration. All BLoCs have TODO placeholders waiting for actual API calls through repositories.

**Current State**:
- ✅ Frontend structure in place
- ✅ Repositories created (AuthRepository done)
- ✅ BLoCs with TODO placeholders
- ⏳ **Next**: Implement QueueRepository and TicketRepository

---

## 📋 **Step 1: Verify Backend is Running**

```bash
# Start backend services
cd backend
docker-compose up -d

# Verify all services are running
docker-compose ps

# Test API Gateway
curl http://localhost:4000/graphql
# Should return GraphQL schema
```

### Expected Services
| Service | Port | Status |
|---------|------|--------|
| MongoDB | 27017 | Running |
| API Gateway | 4000 | ✅ |
| Queue Service | 4001 | ✅ |
| Ticket Service | 4002 | ✅ |
| User Service | 4003 | ✅ |
| Analytics Service | 4004 | ✅ |
| Notification Service | 4005 | ✅ |

---

## 🔧 **Step 2: Update Configuration**

### 2.1 Update Backend URL

**File**: `lib/core/config/app_config.dart`

```dart
// Development (local testing)
static const String _devGraphqlUrl = 'http://192.168.1.100:4000/graphql';

// Or if using localhost
static const String _devGraphqlUrl = 'http://localhost:4000/graphql';

// For physical device, use machine IP
// Run: ipconfig getifaddr en0 (Mac) or ipconfig (Windows)
static const String _devGraphqlUrl = 'http://YOUR_MACHINE_IP:4000/graphql';
```

### 2.2 Verify AppConfig

```bash
cd mobile
flutter run
# Should connect to backend without errors
```

---

## 📦 **Step 3: Complete QueueRepository**

### 3.1 Create QueueRepository

**File**: `lib/core/repositories/queue_repository.dart`

```dart
import 'package:graphql/client.dart';
import 'package:smartqueue/core/models/queue_model.dart';
import 'package:smartqueue/core/models/ticket_model.dart';
import 'package:smartqueue/graphql/client.dart';

class QueueRepository {
  final GraphQLClient _graphQLClient;

  QueueRepository({GraphQLClient? graphQLClient})
      : _graphQLClient = graphQLClient ?? GraphQLConfiguration.graphQLClient;

  /// Fetch all queues
  Future<List<QueueModel>> loadQueues() async {
    const String query = '''
      query GetQueues {
        getQueues {
          id
          name
          description
          isActive
          currentNumber
          averageServiceTime
          maxActiveTickets
          activeTickets {
            id
            ticketNumber
            userId
            status
            createdAt
          }
        }
      }
    ''';

    try {
      final QueryResult result = await _graphQLClient.query(
        QueryOptions(document: gql(query)),
      );

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      if (result.data == null) {
        return [];
      }

      final List<dynamic> queuesData = result.data?['getQueues'] ?? [];
      return queuesData
          .map((queue) => QueueModel.fromJson(queue as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load queues: $e');
    }
  }

  /// Fetch queue details
  Future<QueueModel> loadQueueDetail(String queueId) async {
    const String query = '''
      query GetQueueDetail(\$id: ID!) {
        getQueue(id: \$id) {
          id
          name
          description
          isActive
          currentNumber
          averageServiceTime
          maxActiveTickets
          activeTickets {
            id
            ticketNumber
            userId
            status
            createdAt
          }
        }
      }
    ''';

    try {
      final QueryResult result = await _graphQLClient.query(
        QueryOptions(
          document: gql(query),
          variables: {'id': queueId},
        ),
      );

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      if (result.data == null) {
        throw Exception('Queue not found');
      }

      return QueueModel.fromJson(
        result.data?['getQueue'] as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to load queue detail: $e');
    }
  }

  /// Create ticket for queue
  Future<TicketModel> createTicket(String queueId) async {
    const String mutation = '''
      mutation CreateTicket(\$queueId: ID!) {
        createTicket(queueId: \$queueId) {
          id
          ticketNumber
          status
          userId
          queueId
          createdAt
          estimatedWaitTime
        }
      }
    ''';

    try {
      final QueryResult result = await _graphQLClient.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {'queueId': queueId},
        ),
      );

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      if (result.data == null) {
        throw Exception('Failed to create ticket');
      }

      return TicketModel.fromJson(
        result.data?['createTicket'] as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to create ticket: $e');
    }
  }
}
```

### 3.2 Register in Service Locator

**File**: `lib/core/di/service_locator.dart`

```dart
// Add import
import 'package:smartqueue/core/repositories/queue_repository.dart';

// In setupServiceLocator()
getIt.registerSingleton<QueueRepository>(
  QueueRepository(),
);

// Update QueueBloc registration
getIt.registerSingleton<QueueBloc>(
  QueueBloc(queueRepository: getIt<QueueRepository>()),
);
```

---

## 📦 **Step 4: Complete QueueBloc**

### 4.1 Update QueueBloc to Use Repository

**File**: `lib/features/queue/bloc/queue_bloc.dart`

```dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smartqueue/core/di/service_locator.dart';
import 'package:smartqueue/core/models/queue_model.dart';
import 'package:smartqueue/core/models/ticket_model.dart';
import 'package:smartqueue/core/repositories/queue_repository.dart';

part 'queue_event.dart';
part 'queue_state.dart';

class QueueBloc extends Bloc<QueueEvent, QueueState> {
  final QueueRepository _queueRepository;

  QueueBloc({QueueRepository? queueRepository})
      : _queueRepository = queueRepository ?? getIt<QueueRepository>(),
        super(const QueueInitial()) {
    on<LoadQueuesRequested>(_onLoadQueuesRequested);
    on<LoadQueueDetailRequested>(_onLoadQueueDetailRequested);
    on<CreateTicketRequested>(_onCreateTicketRequested);
  }

  Future<void> _onLoadQueuesRequested(
    LoadQueuesRequested event,
    Emitter<QueueState> emit,
  ) async {
    emit(const QueueLoading());
    try {
      final queues = await _queueRepository.loadQueues();
      emit(QueuesLoaded(queues));
    } catch (e) {
      emit(QueueError(e.toString()));
    }
  }

  Future<void> _onLoadQueueDetailRequested(
    LoadQueueDetailRequested event,
    Emitter<QueueState> emit,
  ) async {
    emit(const QueueLoading());
    try {
      final queue = await _queueRepository.loadQueueDetail(event.queueId);
      emit(QueueDetailLoaded(queue));
    } catch (e) {
      emit(QueueError(e.toString()));
    }
  }

  Future<void> _onCreateTicketRequested(
    CreateTicketRequested event,
    Emitter<QueueState> emit,
  ) async {
    try {
      final ticket = await _queueRepository.createTicket(event.queueId);
      emit(TicketCreated(ticket));
      
      // Reload queues to update state
      final queues = await _queueRepository.loadQueues();
      emit(QueuesLoaded(queues));
    } catch (e) {
      emit(QueueError(e.toString()));
    }
  }
}
```

### Replace Old Code

Remove the TODO placeholders and replace with the implementation above.

---

## 🎫 **Step 5: Complete TicketRepository**

### 5.1 Create TicketRepository

**File**: `lib/core/repositories/ticket_repository.dart`

```dart
import 'package:graphql/client.dart';
import 'package:smartqueue/core/models/ticket_model.dart';
import 'package:smartqueue/graphql/client.dart';

class TicketRepository {
  final GraphQLClient _graphQLClient;

  TicketRepository({GraphQLClient? graphQLClient})
      : _graphQLClient = graphQLClient ?? GraphQLConfiguration.graphQLClient;

  /// Fetch user's tickets
  Future<List<TicketModel>> loadMyTickets() async {
    const String query = '''
      query GetMyTickets {
        getMyTickets {
          id
          ticketNumber
          status
          queueId
          userId
          createdAt
          estimatedWaitTime
        }
      }
    ''';

    try {
      final QueryResult result = await _graphQLClient.query(
        QueryOptions(document: gql(query)),
      );

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      if (result.data == null) {
        return [];
      }

      final List<dynamic> ticketsData = result.data?['getMyTickets'] ?? [];
      return ticketsData
          .map((ticket) => TicketModel.fromJson(ticket as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load tickets: $e');
    }
  }

  /// Fetch single ticket detail
  Future<TicketModel> loadTicketDetail(String ticketId) async {
    const String query = '''
      query GetTicketDetail(\$id: ID!) {
        getTicket(id: \$id) {
          id
          ticketNumber
          status
          queueId
          userId
          createdAt
          estimatedWaitTime
        }
      }
    ''';

    try {
      final QueryResult result = await _graphQLClient.query(
        QueryOptions(
          document: gql(query),
          variables: {'id': ticketId},
        ),
      );

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      if (result.data == null) {
        throw Exception('Ticket not found');
      }

      return TicketModel.fromJson(
        result.data?['getTicket'] as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to load ticket detail: $e');
    }
  }

  /// Cancel ticket
  Future<bool> cancelTicket(String ticketId) async {
    const String mutation = '''
      mutation CancelTicket(\$id: ID!) {
        cancelTicket(id: \$id)
      }
    ''';

    try {
      final QueryResult result = await _graphQLClient.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {'id': ticketId},
        ),
      );

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      return result.data?['cancelTicket'] ?? false;
    } catch (e) {
      throw Exception('Failed to cancel ticket: $e');
    }
  }
}
```

### 5.2 Register in Service Locator

**File**: `lib/core/di/service_locator.dart`

```dart
// Add import
import 'package:smartqueue/core/repositories/ticket_repository.dart';

// In setupServiceLocator()
getIt.registerSingleton<TicketRepository>(
  TicketRepository(),
);

// Update TicketBloc registration
getIt.registerSingleton<TicketBloc>(
  TicketBloc(ticketRepository: getIt<TicketRepository>()),
);
```

---

## 🎫 **Step 6: Complete TicketBloc**

### 6.1 Update TicketBloc to Use Repository

**File**: `lib/features/ticket/bloc/ticket_bloc.dart`

```dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:smartqueue/core/di/service_locator.dart';
import 'package:smartqueue/core/models/ticket_model.dart';
import 'package:smartqueue/core/repositories/ticket_repository.dart';

part 'ticket_event.dart';
part 'ticket_state.dart';

class TicketBloc extends Bloc<TicketEvent, TicketState> {
  final TicketRepository _ticketRepository;

  TicketBloc({TicketRepository? ticketRepository})
      : _ticketRepository = ticketRepository ?? getIt<TicketRepository>(),
        super(const TicketInitial()) {
    on<LoadMyTicketsRequested>(_onLoadMyTicketsRequested);
    on<LoadTicketDetailRequested>(_onLoadTicketDetailRequested);
    on<CancelTicketRequested>(_onCancelTicketRequested);
  }

  Future<void> _onLoadMyTicketsRequested(
    LoadMyTicketsRequested event,
    Emitter<TicketState> emit,
  ) async {
    emit(const TicketLoading());
    try {
      final tickets = await _ticketRepository.loadMyTickets();
      emit(MyTicketsLoaded(tickets));
    } catch (e) {
      emit(TicketError(e.toString()));
    }
  }

  Future<void> _onLoadTicketDetailRequested(
    LoadTicketDetailRequested event,
    Emitter<TicketState> emit,
  ) async {
    emit(const TicketLoading());
    try {
      final ticket = await _ticketRepository.loadTicketDetail(event.ticketId);
      emit(TicketDetailLoaded(ticket));
    } catch (e) {
      emit(TicketError(e.toString()));
    }
  }

  Future<void> _onCancelTicketRequested(
    CancelTicketRequested event,
    Emitter<TicketState> emit,
  ) async {
    try {
      final success = await _ticketRepository.cancelTicket(event.ticketId);
      if (success) {
        emit(const TicketCancelled());
        
        // Reload tickets
        final tickets = await _ticketRepository.loadMyTickets();
        emit(MyTicketsLoaded(tickets));
      } else {
        emit(const TicketError('Failed to cancel ticket'));
      }
    } catch (e) {
      emit(TicketError(e.toString()));
    }
  }
}
```

---

## 🧪 **Step 7: Testing the Integration**

### 7.1 Test Authentication Flow

```dart
// 1. Run the app
flutter run

// 2. Register new user
// Fill in: Name, Email, Password, Phone
// Should navigate to /home

// 3. Verify token is saved
// AuthService should store token in flutter_secure_storage

// 4. Close app and reopen
// Should automatically go to /home (authenticated)
```

### 7.2 Test Queue Operations

```dart
// 1. On HomePage, should see list of queues
// If empty, create queue in backend first:
curl -X POST http://localhost:4001/api/queues \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Queue",
    "description": "Test Description",
    "maxActiveTickets": 5
  }'

// 2. Tap on queue card
// Should navigate to /queue-detail

// 3. View queue details
// Should show stats and active tickets

// 4. Tap "Prendre un numéro"
// Should create ticket and show confirmation
```

### 7.3 Test Ticket Operations

```dart
// 1. From HomePage, create a ticket
// Button: "Prendre un numéro"

// 2. Tap on ticket notification (or profile)
// Should navigate to /ticket

// 3. View ticket details
// Should show ticket number and status

// 4. Tap "Annuler le Ticket" (if waiting)
// Should ask for confirmation
// After confirmation, status should change
```

---

## 🐛 **Debugging Tips**

### Enable GraphQL Logging

**File**: `lib/graphql/client.dart`

```dart
// Add logging
final link = Link.from([
  HttpLink(url, defaultHeaders: headers),
]).chain(
  LoggingLink(), // Add this for debugging
);
```

### Debug API Calls

```dart
// In BLoC handler
try {
  final queues = await _queueRepository.loadQueues();
  print('✅ Loaded ${queues.length} queues');
  emit(QueuesLoaded(queues));
} catch (e, stackTrace) {
  print('❌ Error: $e');
  print('📍 Stack trace: $stackTrace');
  emit(QueueError(e.toString()));
}
```

### Check Backend Logs

```bash
# View service logs
docker-compose logs api-gateway

# View specific service
docker-compose logs queue-service

# Follow logs in real-time
docker-compose logs -f api-gateway
```

---

## 🔗 **GraphQL Schema Reference**

### Queries

```graphql
# Get all queues
query GetQueues {
  getQueues {
    id
    name
    description
    isActive
    currentNumber
    averageServiceTime
    maxActiveTickets
    activeTickets {
      id
      ticketNumber
      userId
      status
      createdAt
    }
  }
}

# Get single queue
query GetQueueDetail($id: ID!) {
  getQueue(id: $id) {
    id
    name
    description
    isActive
    currentNumber
    averageServiceTime
    maxActiveTickets
  }
}

# Get user's tickets
query GetMyTickets {
  getMyTickets {
    id
    ticketNumber
    status
    queueId
    createdAt
    estimatedWaitTime
  }
}

# Get single ticket
query GetTicketDetail($id: ID!) {
  getTicket(id: $id) {
    id
    ticketNumber
    status
    queueId
    createdAt
  }
}
```

### Mutations

```graphql
# Login
mutation Login($email: String!, $password: String!) {
  login(email: $email, password: $password) {
    user {
      id
      name
      email
      phone
      role
    }
    token
  }
}

# Register
mutation Register(
  $name: String!
  $email: String!
  $password: String!
  $phone: String
) {
  register(
    name: $name
    email: $email
    password: $password
    phone: $phone
  ) {
    user {
      id
      name
      email
      phone
    }
    token
  }
}

# Create ticket
mutation CreateTicket($queueId: ID!) {
  createTicket(queueId: $queueId) {
    id
    ticketNumber
    status
    createdAt
  }
}

# Cancel ticket
mutation CancelTicket($id: ID!) {
  cancelTicket(id: $id)
}
```

---

## ✅ **Integration Checklist**

### Prerequisites
- [ ] Backend running: `docker-compose up -d`
- [ ] All 6 services showing healthy status
- [ ] MongoDB data populated with test queues

### Frontend Setup
- [ ] Updated backend URL in `app_config.dart`
- [ ] Configured for your machine IP or localhost
- [ ] GraphQL client initialized

### Repository Implementation
- [ ] ✅ AuthRepository (already done)
- [ ] QueueRepository created and registered
- [ ] TicketRepository created and registered

### BLoC Implementation
- [ ] AuthBloc using AuthRepository
- [ ] QueueBloc using QueueRepository
- [ ] TicketBloc using TicketRepository

### Testing
- [ ] Authentication flow works (register → login → home)
- [ ] Queue list displays on HomePage
- [ ] Queue details show correct data
- [ ] Can create tickets
- [ ] Can view ticket details
- [ ] Can cancel tickets
- [ ] Profile page displays user info
- [ ] Logout works correctly

### Error Handling
- [ ] Network errors display snackbars
- [ ] Invalid credentials show error messages
- [ ] Loading states display spinners
- [ ] Empty states handled gracefully

---

## 🎉 **Success Indicators**

✅ **Integration Complete When:**
- Frontend fully connects to backend APIs
- All CRUD operations working
- Real-time data syncing
- Error handling robust
- User experience smooth

---

## 📞 **Next Phase**

Once API integration is complete:

1. **Add Real-Time Updates** with Socket.io
2. **Implement Notifications** system
3. **Performance Optimization** (caching, pagination)
4. **Production Deployment** (to cloud)
5. **Advanced Features** (analytics, analytics dashboard)

---

**Good luck with integration! 🚀**
