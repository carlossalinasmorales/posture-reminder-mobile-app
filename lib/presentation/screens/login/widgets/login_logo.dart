import 'package:flutter/material.dart';
import '../../../../theme/app_styles.dart';

class LoginLogo extends StatelessWidget {
  const LoginLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kLargePadding),
      decoration: BoxDecoration(
        color: kPrimaryColor.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Image.asset('assets/images/logo.png', width: 80, height: 80),
    );
  }
}
