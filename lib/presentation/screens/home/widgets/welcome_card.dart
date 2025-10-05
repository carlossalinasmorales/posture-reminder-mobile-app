import 'package:flutter/material.dart';
import '../../../../theme/app_styles.dart';

class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: kMediumElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kExtraLargeBorderRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(kLargePadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kExtraLargeBorderRadius),
          gradient: const LinearGradient(
            colors: [kPrimaryColor, kSecondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.favorite_border, color: kWhiteColor, size: 48),
                SizedBox(width: 16),
                Text(
                  '¡Hola!',
                  style: TextStyle(
                    color: kWhiteColor,
                    fontSize: kExtraLargePadding,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Queremos ayudarte a recordar que debes cuidar tu postura '
              'para que te sientas mejor.',
              style: TextStyle(
                color: kWhiteColor.withValues(alpha: 0.95),
                fontSize: kSmallFontSize,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
