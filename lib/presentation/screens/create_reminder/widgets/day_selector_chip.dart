import 'package:flutter/material.dart';
import '/../../theme/app_styles.dart';

/// Chip para seleccionar un día de la semana
class DaySelectorChip extends StatelessWidget {
  final String label;
  final int day;
  final bool isSelected;
  final Function(bool) onSelected;

  const DaySelectorChip({
    super.key,
    required this.label,
    required this.day,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: kBodyTextStyle.copyWith(
          fontWeight: FontWeight.bold,
          color: isSelected ? kWhiteColor : kContrastColor,
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: Colors.grey[200],
      selectedColor: kPrimaryColor,
      checkmarkColor: kWhiteColor,
      padding: const EdgeInsets.all(kSmallPadding),
    );
  }
}