import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/reminder.dart';
import '../../theme/app_styles.dart';

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
      elevation: kDefaultElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kLargeBorderRadius),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(kLargeBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// --- Cabecera con título y estado ---
              Row(
                children: [
                  _buildStatusIcon(),
                  const SizedBox(width: kSmallPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reminder.title, style: kSubtitleTextStyle),
                        const SizedBox(height: 4),
                        Text(
                          _getFrequencyText(),
                          style: kCaptionTextStyle.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),

              const SizedBox(height: kDefaultPadding),

              /// --- Descripción ---
              Text(
                reminder.description,
                style: kBodyTextStyle.copyWith(height: 1.4),
              ),

              const SizedBox(height: kDefaultPadding),

              /// --- Fecha y hora ---
              Row(
                children: [
                  const Icon(Icons.access_time, size: kSmallIconSize, color: kContrastColor),
                  const SizedBox(width: kSmallPadding),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(reminder.dateTime),
                    style: kCaptionTextStyle.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              /// --- Aplazado ---
              if (reminder.postponedUntil != null) ...[
                const SizedBox(height: kSmallPadding),
                Row(
                  children: [
                    const Icon(Icons.snooze, size: kSmallIconSize, color: Colors.orange),
                    const SizedBox(width: kSmallPadding),
                    Text(
                      'Aplazado hasta: ${DateFormat('HH:mm').format(reminder.postponedUntil!)}',
                      style: kCaptionTextStyle.copyWith(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],

              /// --- Botones según estado ---
              if (reminder.status == ReminderStatus.pending) ...[
                const SizedBox(height: kLargePadding),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onComplete,
                        style: kPrimaryButtonStyle.copyWith(
                          backgroundColor: WidgetStateProperty.all(kSuccessColor),
                        ),
                        icon: const Icon(Icons.check_circle, size: kSmallIconSize),
                        label: const Text('Completar', style: kButtonTextStyle),
                      ),
                    ),
                    const SizedBox(width: kSmallPadding),
                    ElevatedButton(
                      onPressed: onSkip,
                      style: kPrimaryButtonStyle.copyWith(
                        backgroundColor: WidgetStateProperty.all(Colors.grey),
                      ),
                      child: const Icon(Icons.close, size: kSmallIconSize, color: kWhiteColor),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: kSmallPadding),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: kSmallIconSize),
                      label: const Text('Eliminar', style: kBodyTextStyle),
                      style: TextButton.styleFrom(foregroundColor: kErrorColor),
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

  /// --- Icono de estado ---
  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (reminder.status) {
      case ReminderStatus.pending:
        icon = Icons.schedule;
        color = Colors.blue;
        break;
      case ReminderStatus.completed:
        icon = Icons.check_circle;
        color = kSuccessColor;
        break;
      case ReminderStatus.skipped:
        icon = Icons.cancel;
        color = Colors.grey;
        break;
      case ReminderStatus.postponed:
        icon = Icons.snooze;
        color = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(kSmallPadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
      ),
      child: Icon(icon, color: color, size: kMediumIconSize),
    );
  }

  /// --- Badge de estado ---
  Widget _buildStatusBadge() {
    String text;
    Color color;

    switch (reminder.status) {
      case ReminderStatus.pending:
        text = 'Pendiente';
        color = Colors.blue;
        break;
      case ReminderStatus.completed:
        text = 'Completado';
        color = kSuccessColor;
        break;
      case ReminderStatus.skipped:
        text = 'Omitido';
        color = Colors.grey;
        break;
      case ReminderStatus.postponed:
        text = 'Aplazado';
        color = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kSmallPadding, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(kLargeBorderRadius),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: kCaptionTextStyle.copyWith(
          color: color,
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
