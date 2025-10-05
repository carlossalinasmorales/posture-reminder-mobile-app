import 'package:flutter/material.dart';
import '../../../../theme/app_styles.dart';
import 'text_field_custom.dart';

class LoginForm extends StatelessWidget {
  final bool isLogin;
  final bool isLoading;
  final bool obscurePassword;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController nameController;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;

  const LoginForm({
    super.key,
    required this.isLogin,
    required this.isLoading,
    required this.obscurePassword,
    required this.emailController,
    required this.passwordController,
    required this.nameController,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!isLogin)
          Column(
            children: [
              TextFieldCustom(
                controller: nameController,
                label: 'Nombre',
                icon: Icons.person,
                validator: (v) => v == null || v.isEmpty
                    ? 'Por favor ingresa tu nombre'
                    : null,
              ),
              const SizedBox(height: kDefaultPadding),
            ],
          ),
        TextFieldCustom(
          controller: emailController,
          label: 'Correo Electrónico',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Por favor ingresa tu correo';
            if (!v.contains('@')) return 'Ingresa un correo válido';
            return null;
          },
        ),
        const SizedBox(height: kDefaultPadding),
        TextFieldCustom(
          controller: passwordController,
          label: 'Contraseña',
          icon: Icons.lock,
          obscureText: obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              obscurePassword ? Icons.visibility : Icons.visibility_off,
              color: kPrimaryColor,
            ),
            onPressed: onTogglePassword,
          ),
          validator: (v) {
            if (v == null || v.isEmpty)
              return 'Por favor ingresa tu contraseña';
            if (v.length < 6) return 'Debe tener al menos 6 caracteres';
            return null;
          },
        ),
        const SizedBox(height: kExtraLargePadding),
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryColor, kPrimaryColor.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(kDefaultBorderRadius),
            ),
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: kWhiteColor,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(isLogin ? 'Iniciar Sesión' : 'Registrarse',
                      style: kButtonTextStyle),
            ),
          ),
        ),
        const SizedBox(height: kDefaultPadding),
        TextButton(
          onPressed: onToggleMode,
          child: Text(
            isLogin
                ? '¿No tienes cuenta? Regístrate'
                : '¿Ya tienes cuenta? Inicia sesión',
            style: kBodyTextStyle.copyWith(
              fontSize: kSmallFontSize,
              fontWeight: FontWeight.w600,
              color: kPrimaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
