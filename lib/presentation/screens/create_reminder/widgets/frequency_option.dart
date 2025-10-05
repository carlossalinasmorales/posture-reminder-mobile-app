import 'package:flutter/material.dart';
import '/../../theme/app_styles.dart';

/// Widget para una opción individual de frecuencia
class FrequencyOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const FrequencyOption({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kSmallPadding),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
        child: Container(
          padding: const EdgeInsets.all(kSmallPadding),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(kDefaultBorderRadius),
            border: Border.all(
              color: isSelected ? kPrimaryColor : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? kPrimaryColor : Colors.grey[600],
                size: kMediumIconSize,
              ),
              const SizedBox(width: kSmallPadding),
              Text(
                label,
                style: kBodyTextStyle.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? kPrimaryColor : kContrastColor,
                ),
              ),
              const Spacer(),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: kPrimaryColor,
                  size: kSmallIconSize,
                ),
            ],
          ),
        ),
      ),
    );
  }
}