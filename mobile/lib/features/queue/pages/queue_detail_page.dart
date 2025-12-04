import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartqueue/core/models/queue_model.dart';
import 'package:smartqueue/features/queue/bloc/queue_bloc.dart';

class QueueDetailPage extends StatefulWidget {
  final String queueId;

  const QueueDetailPage({
    Key? key,
    required this.queueId,
  }) : super(key: key);

  @override
  State<QueueDetailPage> createState() => _QueueDetailPageState();
}

class _QueueDetailPageState extends State<QueueDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<QueueBloc>().add(
      LoadQueueDetailRequested(widget.queueId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la File'),
        elevation: 0,
      ),
      body: BlocBuilder<QueueBloc, QueueState>(
        builder: (context, state) {
          if (state is QueueLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is QueueDetailLoaded) {
            final queue = state.queue;
            return _buildQueueDetail(context, queue);
          }

          if (state is QueueError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: ${state.message}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<QueueBloc>().add(
                        LoadQueueDetailRequested(widget.queueId),
                      );
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return const Center(
            child: Text('Aucune donnée disponible'),
          );
        },
      ),
    );
  }

  Widget _buildQueueDetail(BuildContext context, QueueModel queue) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  queue.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  queue.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Status Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'État de la file',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildStatsGrid(context, queue),
              ],
            ),
          ),

          // Status Badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: queue.isActive ? Colors.green[50] : Colors.red[50],
                border: Border.all(
                  color: queue.isActive ? Colors.green : Colors.red,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    queue.isActive ? Icons.check_circle : Icons.cancel,
                    color: queue.isActive ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    queue.isActive ? 'File Active' : 'File Inactive',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: queue.isActive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<QueueBloc>().add(
                    CreateTicketRequested(
                      queueId: queue.id,
                      userId: 'current_user_id',  // TODO: Replace with actual user ID
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Prendre un numéro'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Tickets Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Tickets Actifs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          const SizedBox(height: 16),

          if (queue.activeTickets.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.assignment_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aucun ticket actif',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: queue.activeTickets.length,
              itemBuilder: (context, index) {
                final ticketNumber = queue.activeTickets[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ticket #$ticketNumber',
                              style:
                                  Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor('Waiting'),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'En attente',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, QueueModel queue) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          'Numéro Actuel',
          '${queue.currentNumber}',
          Icons.confirmation_num,
        ),
        _buildStatCard(
          context,
          'Temps Moyen',
          '${queue.averageServiceTime} min',
          Icons.hourglass_bottom,
        ),
        _buildStatCard(
          context,
          'Actifs',
          '${queue.activeTickets.length}',
          Icons.people,
        ),
        _buildStatCard(
          context,
          'Max Actifs',
          '${queue.maxActiveTickets}',
          Icons.person_add,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
        return Colors.orange;
      case 'served':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else {
      return 'Il y a ${difference.inDays} j';
    }
  }
}
