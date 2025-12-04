import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartqueue/features/auth/bloc/auth_bloc.dart';
import 'package:smartqueue/features/queue/bloc/queue_bloc.dart';

/// Page d'accueil
/// Affiche la liste des queues disponibles
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Charger les queues au démarrage
    context.read<QueueBloc>().add(const LoadQueuesRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartQueue - Accueil'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const LogoutRequested());
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: BlocBuilder<QueueBloc, QueueState>(
        builder: (context, state) {
          if (state is QueueLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is QueueError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${state.message}'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<QueueBloc>().add(const LoadQueuesRequested());
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (state is QueuesLoaded) {
            if (state.queues.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune queue disponible',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<QueueBloc>().add(const LoadQueuesRequested());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.queues.length,
                itemBuilder: (context, index) {
                  final queue = state.queues[index];
                  return QueueCard(queue: queue);
                },
              ),
            );
          }

          return const Center(child: Text('État inconnu'));
        },
      ),
    );
  }
}

/// Card pour afficher une queue
class QueueCard extends StatelessWidget {
  final dynamic queue; // Devrait être QueueModel quand on aura le repository

  const QueueCard({
    Key? key,
    required this.queue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            '/queue-detail',
            arguments: queue['id'] ?? '',
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          queue['name'] ?? 'Unnamed Queue',
                          style: Theme.of(context).textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          queue['description'] ?? '',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Indicateur de statut
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: (queue['isActive'] ?? false)
                          ? Colors.green[100]
                          : Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (queue['isActive'] ?? false) ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: (queue['isActive'] ?? false)
                            ? Colors.green[800]
                            : Colors.red[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Stats de la queue
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    icon: Icons.confirmation_num,
                    label: 'Actuel',
                    value: '${queue['currentNumber'] ?? 0}',
                  ),
                  _StatItem(
                    icon: Icons.hourglass_bottom,
                    label: 'Temps moy',
                    value: '${queue['averageServiceTime'] ?? 0} min',
                  ),
                  _StatItem(
                    icon: Icons.people,
                    label: 'Max actifs',
                    value: '${queue['maxActiveTickets'] ?? 1}',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Bouton d'action
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<QueueBloc>().add(
                      CreateTicketRequested(
                        queueId: queue.id,
                        userId: 'current_user_id',  // TODO: Get from auth
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Prendre un numéro'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget pour afficher une stat
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}