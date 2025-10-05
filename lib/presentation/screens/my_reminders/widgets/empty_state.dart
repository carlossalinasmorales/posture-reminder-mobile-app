import 'package:flutter/material.dart';
import '/../../theme/app_styles.dart';

/// Widget de estado vacío cuando no hay recordatorios
class EmptyStateWidget extends StatelessWidget {
  final String filterLabel;

  const EmptyStateWidget({
    super.key,
    required this.filterLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kExtraLargePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 120, color: Colors.grey[400]),
            const SizedBox(height: kLargePadding),
            Text(
              filterLabel == 'Todos'
                  ? '¡No hay recordatorios!'
                  : 'No hay recordatorios ${filterLabel.toLowerCase()}',
              style: kTitleTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kSmallPadding),
            Text(
              'Toca el botón "Nuevo Recordatorio" para comenzar.',
              style: kBodyTextStyle.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
