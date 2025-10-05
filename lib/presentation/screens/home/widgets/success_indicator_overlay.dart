import 'package:flutter/material.dart';
import '../../../../theme/app_styles.dart';

class SuccessIndicatorOverlay extends StatelessWidget {
  const SuccessIndicatorOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding,
            vertical: kSmallPadding,
          ),
          decoration: BoxDecoration(
            color: Colors.green[600],
            borderRadius: BorderRadius.circular(kExtraLargeBorderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle,
                  color: kWhiteColor, size: kSmallIconSize),
              SizedBox(width: kSmallPadding),
              Text(
                'Listo',
                style: TextStyle(
                  color: kWhiteColor,
                  fontSize: kExtraSmallFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
