import 'package:flutter/material.dart';
import '../../../../theme/app_styles.dart';

class GuestButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const GuestButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: const Icon(Icons.person_outline, size: kMediumIconSize),
        label: Text(
          'Continuar como Invitado',
          style: kButtonTextStyle.copyWith(color: kContrastColor),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
          side: BorderSide(color: Colors.grey[400]!, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kDefaultBorderRadius),
          ),
        ),
      ),
    );
  }
}
