import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartqueue/core/models/ticket_model.dart';
import 'package:smartqueue/features/ticket/bloc/ticket_bloc.dart';

class TicketPage extends StatefulWidget {
  final String ticketId;
  final String queueId;

  const TicketPage({
    Key? key,
    required this.ticketId,
    required this.queueId,
  }) : super(key: key);

  @override
  State<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {
  @override
  void initState() {
    super.initState();
    // Load ticket details
    context.read<TicketBloc>().add(
      LoadTicketDetailRequested(widget.ticketId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Ticket'),
        elevation: 0,
      ),
      body: BlocBuilder<TicketBloc, TicketState>(
        builder: (context, state) {
          if (state is TicketLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is TicketDetailLoaded) {
            final ticket = state.ticket;
            return _buildTicketDetail(context, ticket);
          }

          if (state is TicketError) {
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
                      context.read<TicketBloc>().add(
                        LoadTicketDetailRequested(widget.ticketId),
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

  Widget _buildTicketDetail(BuildContext context, TicketModel ticket) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ticket Number Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Votre Ticket',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  ticket.ticketNumber,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusBackgroundColor(ticket.status.toShortString()),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ticket.status.toDisplayString(),
                    style: TextStyle(
                      color: _getStatusTextColor(ticket.status.toShortString()),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Ticket Information
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informations du Ticket',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  context,
                  label: 'Utilisateur',
                  value: ticket.userName ?? 'Utilisateur',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  label: 'Créé le',
                  value: _formatDate(ticket.createdAt),
                  icon: Icons.calendar_today,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  context,
                  label: 'Position',
                  value: 'À déterminer',
                  icon: Icons.trending_up,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Action Buttons
          if (ticket.status.toLowerCase() == 'waiting')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showCancelDialog(context, ticket.id);
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Annuler le Ticket'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),

          // Info Message
          if (ticket.status == TicketStatus.waiting)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vous serez notifié quand ce sera votre tour',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.blue[700],
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
        return Colors.orange.withOpacity(0.3);
      case 'served':
        return Colors.green.withOpacity(0.3);
      case 'cancelled':
        return Colors.red.withOpacity(0.3);
      default:
        return Colors.grey.withOpacity(0.3);
    }
  }

  Color _getStatusTextColor(String status) {
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

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showCancelDialog(BuildContext context, String ticketId) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler ce ticket ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<TicketBloc>().add(
                CancelTicketRequested(ticketId),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ticket annulé avec succès'),
                ),
              );
            },
            child: const Text(
              'Oui',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
