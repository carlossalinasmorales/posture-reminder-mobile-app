import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_styles.dart';
import '../home/home_screen.dart';

// Widgets
import 'widgets/login_logo.dart';
import 'widgets/login_title.dart';
import 'widgets/login_form.dart';
import 'widgets/divider_with_text.dart';
import 'widgets/guest_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        await credential.user?.updateDisplayName(_nameController.text.trim());
      }
    } on FirebaseAuthException catch (e) {
      _showAuthError(e.code);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAuthError(String code) {
    String message = switch (code) {
      'user-not-found' => 'Usuario no encontrado',
      'wrong-password' => 'Contraseña incorrecta',
      'email-already-in-use' => 'Este correo ya está registrado',
      'weak-password' => 'La contraseña debe tener al menos 6 caracteres',
      'invalid-email' => 'Correo electrónico inválido',
      _ => 'Error de autenticación',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: kBodyTextStyle),
        backgroundColor: kErrorColor,
      ),
    );
  }

  Future<void> _continueAsGuest() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('guest_mode', true);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al continuar como invitado'),
          backgroundColor: kErrorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(kLargePadding),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const LoginLogo(),
                  const SizedBox(height: kExtraLargePadding),
                  LoginTitle(isLogin: _isLogin),
                  const SizedBox(height: kExtraLargePadding),
                  LoginForm(
                    isLogin: _isLogin,
                    isLoading: _isLoading,
                    obscurePassword: _obscurePassword,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    nameController: _nameController,
                    onTogglePassword: () => setState(() {
                      _obscurePassword = !_obscurePassword;
                    }),
                    onSubmit: _submit,
                    onToggleMode: () => setState(() => _isLogin = !_isLogin),
                  ),
                  const SizedBox(height: kLargePadding),
                  const DividerWithText(text: 'O'),
                  const SizedBox(height: kLargePadding),
                  GuestButton(
                    isLoading: _isLoading,
                    onPressed: _continueAsGuest,
                  ),
                  const SizedBox(height: kDefaultPadding),
                  Text(
                    'Nota: Como invitado, tus datos solo se guardarán en este dispositivo mientras no cierres sesión.',
                    textAlign: TextAlign.center,
                    style: kCaptionTextStyle.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
