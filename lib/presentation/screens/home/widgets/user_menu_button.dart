import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/local_datasource.dart';
import '../../../../theme/app_styles.dart';
import '../../../../main.dart';
import '../../../bloc/reminder_bloc.dart';

class UserMenuButton extends StatelessWidget {
  final VoidCallback onShowSuccessIndicator;
  const UserMenuButton({required this.onShowSuccessIndicator, super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: kContrastColor),
      itemBuilder: (_) => [
        _buildUserStatusMenuItem(),
        const PopupMenuDivider(),
        _buildLogoutMenuItem(),
      ],
      onSelected: (v) => _handleMenuSelection(context, v),
    );
  }

  PopupMenuItem<String> _buildUserStatusMenuItem() => PopupMenuItem(
        enabled: false,
        child: FutureBuilder<String>(
          future: _getUserStatus(),
          builder: (_, s) => Text(
            s.data ?? 'Cargando...',
            style: const TextStyle(
                fontSize: kExtraSmallFontSize, color: Colors.grey),
          ),
        ),
      );

  PopupMenuItem<String> _buildLogoutMenuItem() => const PopupMenuItem(
        value: 'logout',
        child: Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 12),
            Text('Cerrar Sesión', style: TextStyle(fontSize: kSmallFontSize)),
          ],
        ),
      );

  Future<String> _getUserStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null)
      return '👤 ${user.displayName ?? user.email ?? "Usuario"}';
    final prefs = await SharedPreferences.getInstance();
    final guest = prefs.getBool('guest_mode') ?? false;
    return guest ? '🎭 Modo Invitado' : 'Desconectado';
  }

  Future<void> _handleMenuSelection(BuildContext ctx, String v) async {
    if (v != 'logout') return;
    final prefs = await SharedPreferences.getInstance();
    final guest = prefs.getBool('guest_mode') ?? false;
    
    // Limpiar los datos locales para ambos tipos de sesión
    await LocalDataSource().clearAllData();
    
    // Limpiar el bloc para remover recordatorios del estado
    if (ctx.mounted) {
      ctx.read<ReminderBloc>().add(LoadReminders());
    }
    
    if (guest) {
      await prefs.remove('guest_mode');
    } else {
      await FirebaseAuth.instance.signOut();
    }
    
    // Forzar reconstrucción del AuthWrapper para que detecte los cambios
    authWrapperKey.currentState?.refresh();
  }
}
