import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/../../theme/app_styles.dart';

/// Card para seleccionar fecha y hora del recordatorio
class ReminderDateTimeCard extends StatelessWidget {
  final DateTime selectedDateTime;
  final VoidCallback onDatePressed;
  final VoidCallback onTimePressed;

  const ReminderDateTimeCard({
    super.key,
    required this.selectedDateTime,
    required this.onDatePressed,
    required this.onTimePressed,
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
                const Icon(Icons.access_time, color: kPrimaryColor, size: kMediumIconSize),
                const SizedBox(width: kSmallPadding),
                Text('Fecha y hora', style: kSubtitleTextStyle),
              ],
            ),
            const SizedBox(height: kDefaultPadding),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDatePressed,
                    icon: const Icon(Icons.calendar_today, color: kPrimaryColor),
                    label: Text(
                      DateFormat('dd/MM/yyyy', 'es').format(selectedDateTime),
                      style: kCaptionTextStyle,
                    ),
                  ),
                ),
                const SizedBox(width: kSmallPadding),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTimePressed,
                    icon: const Icon(Icons.schedule, color: kPrimaryColor),
                    label: Text(
                      DateFormat('HH:mm').format(selectedDateTime),
                      style: kCaptionTextStyle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}