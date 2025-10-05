import 'package:flutter/material.dart';
import '../../../../theme/app_styles.dart';

class MenuButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const MenuButton({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: kMediumElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kExtraLargeBorderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kExtraLargeBorderRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kLargePadding,
            vertical: 30,
          ),
          child: Row(
            children: [
              _buildIconContainer(),
              const SizedBox(width: 24),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: kMediumFontSize,
                    fontWeight: FontWeight.bold,
                    color: kContrastColor,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: kMediumIconSize,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: color, size: 42),
    );
  }
}
