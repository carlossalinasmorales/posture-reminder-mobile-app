import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/reminder.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback? onComplete;
  final VoidCallback? onPostpone;
  final VoidCallback? onSkip;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onComplete,
    this.onPostpone,
    this.onSkip,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getFrequencyText(),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                reminder.description,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(reminder.dateTime),
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (reminder.postponedUntil != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.snooze,
                      size: 18,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Aplazado hasta: ${DateFormat('HH:mm').format(reminder.postponedUntil!)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              if (reminder.status == ReminderStatus.pending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onComplete,
                        icon: const Icon(Icons.check_circle, size: 20),
                        label: const Text(
                          'Completar',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27AE60),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onPostpone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF39C12),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.snooze, size: 20),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onSkip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
              ],
              if (reminder.status != ReminderStatus.pending) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 20),
                      label: const Text(
                        'Eliminar',
                        style: TextStyle(fontSize: 15),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (reminder.status) {
      case ReminderStatus.pending:
        icon = Icons.schedule;
        color = const Color(0xFF3498DB);
        break;
      case ReminderStatus.completed:
        icon = Icons.check_circle;
        color = const Color(0xFF27AE60);
        break;
      case ReminderStatus.skipped:
        icon = Icons.cancel;
        color = Colors.grey;
        break;
      case ReminderStatus.postponed:
        icon = Icons.snooze;
        color = const Color(0xFFF39C12);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildStatusBadge() {
    String text;
    Color color;

    switch (reminder.status) {
      case ReminderStatus.pending:
        text = 'Pendiente';
        color = const Color(0xFF3498DB);
        break;
      case ReminderStatus.completed:
        text = 'Completado';
        color = const Color(0xFF27AE60);
        break;
      case ReminderStatus.skipped:
        text = 'Omitido';
        color = Colors.grey;
        break;
      case ReminderStatus.postponed:
        text = 'Aplazado';
        color = const Color(0xFFF39C12);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getFrequencyText() {
    switch (reminder.frequency) {
      case ReminderFrequency.once:
        return 'Una vez';
      case ReminderFrequency.daily:
        return 'Todos los días';
      case ReminderFrequency.weekly:
        return 'Cada semana';
      case ReminderFrequency.custom:
        if (reminder.customDays != null && reminder.customDays!.isNotEmpty) {
          final days = reminder.customDays!.map(_getDayName).join(', ');
          return 'Días: $days';
        } else if (reminder.customInterval != null) {
          return 'Cada ${reminder.customInterval} días';
        }
        return 'Personalizado';
    }
  }

  String _getDayName(int day) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[day - 1];
  }
}
