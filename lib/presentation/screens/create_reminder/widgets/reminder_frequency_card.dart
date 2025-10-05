import 'package:flutter/material.dart';
import '/../../domain/entities/reminder.dart';
import '/../../theme/app_styles.dart';
import 'frequency_option.dart';

/// Card para seleccionar la frecuencia del recordatorio
class ReminderFrequencyCard extends StatelessWidget {
  final ReminderFrequency selectedFrequency;
  final Function(ReminderFrequency) onFrequencyChanged;

  const ReminderFrequencyCard({
    super.key,
    required this.selectedFrequency,
    required this.onFrequencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: kDefaultElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.repeat,
                    color: kPrimaryColor, size: kMediumIconSize),
                const SizedBox(width: kSmallPadding),
                Text('Frecuencia', style: kSubtitleTextStyle),
              ],
            ),
            const SizedBox(height: kSmallPadding),
            FrequencyOption(
              label: 'Una vez',
              icon: Icons.event,
              isSelected: selectedFrequency == ReminderFrequency.once,
              onTap: () => onFrequencyChanged(ReminderFrequency.once),
            ),
            FrequencyOption(
              label: 'Todos los días',
              icon: Icons.today,
              isSelected: selectedFrequency == ReminderFrequency.daily,
              onTap: () => onFrequencyChanged(ReminderFrequency.daily),
            ),
            FrequencyOption(
              label: 'Cada semana',
              icon: Icons.calendar_view_week,
              isSelected: selectedFrequency == ReminderFrequency.weekly,
              onTap: () => onFrequencyChanged(ReminderFrequency.weekly),
            ),
            FrequencyOption(
              label: 'Personalizado',
              icon: Icons.settings,
              isSelected: selectedFrequency == ReminderFrequency.custom,
              onTap: () => onFrequencyChanged(ReminderFrequency.custom),
            ),
          ],
        ),
      ),
    );
  }
}
