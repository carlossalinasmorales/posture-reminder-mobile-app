import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import '../../theme/app_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
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
      String message = 'Error de autenticación';
      switch (e.code) {
        case 'user-not-found':
          message = 'Usuario no encontrado';
          break;
        case 'wrong-password':
          message = 'Contraseña incorrecta';
          break;
        case 'email-already-in-use':
          message = 'Este correo ya está registrado';
          break;
        case 'weak-password':
          message = 'La contraseña debe tener al menos 6 caracteres';
          break;
        case 'invalid-email':
          message = 'Correo electrónico inválido';
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: kBodyTextStyle),
            backgroundColor: kErrorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('guest_mode', true);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al continuar como invitado'),
            backgroundColor: kErrorColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// Logo
                  Container(
                    padding: const EdgeInsets.all(kLargePadding),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 80,
                      height: 80,
                    ),
                  ),

                  const SizedBox(height: kExtraLargePadding),

                  /// Título
                  Text(
                    _isLogin ? '¡Hola!' : 'Crear Cuenta',
                    style: kTitleTextStyle.copyWith(color: kPrimaryColor),
                  ),

                  const SizedBox(height: kSmallPadding),

                  Text(
                    _isLogin
                        ? 'Inicia sesión para continuar'
                        : 'Regístrate para comenzar',
                    style: kBodyTextStyle.copyWith(color: Colors.grey[600]),
                  ),

                  const SizedBox(height: kExtraLargePadding),

                  /// Nombre (solo registro)
                  if (!_isLogin) ...[
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nombre',
                      icon: Icons.person,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Por favor ingresa tu nombre' : null,
                    ),
                    const SizedBox(height: kDefaultPadding),
                  ],

                  /// Email
                  _buildTextField(
                    controller: _emailController,
                    label: 'Correo Electrónico',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Por favor ingresa tu correo';
                      if (!value.contains('@')) return 'Ingresa un correo válido';
                      return null;
                    },
                  ),

                  const SizedBox(height: kDefaultPadding),

                  /// Contraseña
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Contraseña',
                    icon: Icons.lock,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: kPrimaryColor,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Por favor ingresa tu contraseña';
                      if (value.length < 6) return 'Debe tener al menos 6 caracteres';
                      return null;
                    },
                  ),

                  const SizedBox(height: kExtraLargePadding),

                  /// Botón Principal con degradado
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.7)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(kDefaultBorderRadius),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: kWhiteColor,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isLogin ? 'Iniciar Sesión' : 'Registrarse',
                                style: kButtonTextStyle,
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: kDefaultPadding),

                  /// Toggle login/registro
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin
                          ? '¿No tienes cuenta? Regístrate'
                          : '¿Ya tienes cuenta? Inicia sesión',
                      style: kBodyTextStyle.copyWith(
                        fontSize: kSmallFontSize,
                        fontWeight: FontWeight.w600,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: kLargePadding),

                  /// Divisor
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[400])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: kSmallPadding),
                        child: Text('O', style: kBodyTextStyle.copyWith(color: Colors.grey[600])),
                      ),
                      Expanded(child: Divider(color: Colors.grey[400])),
                    ],
                  ),

                  const SizedBox(height: kLargePadding),

                  /// Continuar como invitado
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _continueAsGuest,
                      icon: const Icon(Icons.person_outline, size: kMediumIconSize),
                      label: Text('Continuar como Invitado', style: kButtonTextStyle.copyWith(color: kContrastColor)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
                        side: BorderSide(color: Colors.grey[400]!, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kDefaultBorderRadius),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: kDefaultPadding),

                  Text(
                    'Nota: Como invitado, tus datos solo se guardarán en este dispositivo',
                    textAlign: TextAlign.center,
                    style: kCaptionTextStyle.copyWith(color: Colors.grey[600], fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: kBodyTextStyle,
      decoration: kTextFieldDecoration.copyWith(
        labelText: label,
        prefixIcon: Icon(icon, color: kPrimaryColor),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}
