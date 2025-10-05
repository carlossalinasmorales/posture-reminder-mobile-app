import 'package:flutter/material.dart';
import '../../../../theme/app_styles.dart';

class LoginTitle extends StatelessWidget {
  final bool isLogin;
  const LoginTitle({super.key, required this.isLogin});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          isLogin ? '¡Hola!' : 'Crear Cuenta',
          style: kTitleTextStyle.copyWith(color: kPrimaryColor),
        ),
        const SizedBox(height: kSmallPadding),
        Text(
          isLogin ? 'Inicia sesión para continuar' : 'Regístrate para comenzar',
          style: kBodyTextStyle.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}
