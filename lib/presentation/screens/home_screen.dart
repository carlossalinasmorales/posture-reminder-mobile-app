import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/reminder_bloc.dart';
import 'my_reminders_screen.dart';
import 'create_reminder_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login_screen.dart';
import '../../data/datasources/local_datasource.dart';
import '../../theme/app_styles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<String> _getUserStatus() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    return '👤 ${user.displayName ?? user.email ?? "Usuario"}';
  }
  
  final prefs = await SharedPreferences.getInstance();
  final isGuest = prefs.getBool('guest_mode') ?? false;
  if (isGuest) {
    return '🎭 Modo Invitado';
  }
  
  return 'Desconectado';
}
  @override
  void initState() {
    super.initState();
    // Cargar datos locales primero
    context.read<ReminderBloc>().add(LoadReminders());
    
    // Sincronizar automáticamente con Firebase solo si está autenticado
    _checkAndSyncIfAuthenticated();
    
    // Escuchar cambios en tiempo real
    context.read<ReminderBloc>().add(WatchReminders());
  }

  Future<void> _checkAndSyncIfAuthenticated() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Solo sincronizar si está autenticado con Firebase
      context.read<ReminderBloc>().add(SyncWithFirebase());
    }
    // Si es invitado, no hacer nada (los datos ya están locales)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(
        elevation: kDefaultElevation,
        backgroundColor: kWhiteColor,
        title: const Text(
          'Recordatorios de Postura',
          style: kTitleTextStyle,
        ),
  actions: [
    // Botón de cerrar sesión
    PopupMenuButton<String>(
  icon: const Icon(Icons.more_vert, color: kContrastColor, size: kMediumIconSize),
  itemBuilder: (context) => [
    // AGREGAR ESTA LÍNEA PARA MOSTRAR ESTADO
    PopupMenuItem(
      enabled: false,
      child: FutureBuilder<String>(
        future: _getUserStatus(),
        builder: (context, snapshot) {
          return Text(
            snapshot.data ?? 'Cargando...',
            style: const TextStyle(
              fontSize: kExtraSmallFontSize,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
    ),
    const PopupMenuDivider(),
    const PopupMenuItem(
      value: 'logout',
      child: Row(
        children: [
          Icon(Icons.logout, color: Colors.red),
          SizedBox(width: 12),
          Text('Cerrar Sesión', style: const TextStyle(fontSize: kSmallFontSize)),
        ],
      ),
    ),
  ],
  onSelected: (value) async {
    if (value == 'logout') {
      // Verificar si es invitado
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool('guest_mode') ?? false;
      
      if (isGuest) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              '¿Salir como Invitado?',
              style: kSubtitleTextStyle,
            ),
            content: const Text(
              '⚠️ Si sales como invitado, perderás TODOS tus datos. ¿Deseas crear una cuenta para guardar tus recordatorios?',
              style: kBodyTextStyle,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar', style: TextStyle(fontSize: 18)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, false);
                  // Ir a crear cuenta
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: kSuccessColor),
                child: const Text(
                  'Crear Cuenta',
                  style: TextStyle(fontSize: kSmallFontSize, color: kWhiteColor),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
                child: const Text(
                  'Salir y Borrar',
                  style: TextStyle(fontSize: kSmallFontSize, color: kWhiteColor),
                ),
              ),
            ],
          ),
        );

        if (confirm == true && context.mounted) {
          await prefs.remove('guest_mode');
          // Limpiar datos locales
          await LocalDataSource().clearAllData();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } else {
        // Usuario normal con Firebase
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              '¿Cerrar Sesión?',
              style: kSubtitleTextStyle,
            ),
            content: const Text(
              'Tus datos se guardarán y podrás acceder nuevamente cuando inicies sesión.',
              style: kBodyTextStyle,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar', style: TextStyle(fontSize: 18)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
                child: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(fontSize: kSmallFontSize, color: kWhiteColor),
                ),
              ),
            ],
          ),
        );

        if (confirm == true && context.mounted) {
          await FirebaseAuth.instance.signOut();
        }
      }
    }
  },
),
    const SizedBox(width: 8),
  ],
),
      body: BlocConsumer<ReminderBloc, ReminderState>(
        listener: (context, state) {
          // Solo mostrar errores críticos
          if (state is ReminderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message.contains('sincronizar') 
                    ? 'Error de sincronización'
                    : 'Error inesperado',
                  style: const TextStyle(fontSize: kSmallFontSize),
                ),
                backgroundColor: Colors.red[700],
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is ReminderOperationSuccess) {
            // Mostrar indicador sutil de éxito
            _showSubtleSuccessIndicator();
          }
        },
        builder: (context, state) {
          if (state is ReminderLoading) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: kPrimaryColor,
              ),
            );
          }

          return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(kLargePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mensaje de bienvenida
                  _buildWelcomeCard(),

                  const SizedBox(height: 15), // Más espacio

                  // Botón de Mis Recordatorios - Títulos y botones grandes
                  _buildMenuButton(
                    context: context,
                    title: 'Ver Mis Recordatorios', // Título más claro y activo
                    icon: Icons.list_alt,
                    color: kPrimaryColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyRemindersScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 15), // Más espacio entre botones

                  // Botón de Crear Recordatorio - Títulos y botones grandes
                  _buildMenuButton(
                    context: context,
                    title:
                        'Crear Nuevo Recordatorio', // Título más claro y activo
                    icon: Icons.add_circle,
                    color: kSecondaryColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateReminderScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(
                      height: 15), // Más espacio antes de los consejos

                  // Tips de postura
                  _buildTipsCard(),
                ],
              ),
            );
        },
      ),
    );
  }

  // --- Widgets Auxiliares Mejorados ---

  Widget _buildWelcomeCard() {
    return Card(
      elevation: kMediumElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kExtraLargeBorderRadius)),
      child: Container(
        padding: const EdgeInsets.all(kLargePadding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kExtraLargeBorderRadius),
          // Se mantiene el gradiente, pero se mejora el color
          gradient: const LinearGradient(
            colors: [
              kPrimaryColor,
              kSecondaryColor
            ], // Tonos más cálidos y claros
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.favorite_border,
                  color: kWhiteColor,
                  size: 48,
                ),
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
              'Queremos ayudarte a recordar que debes cuidar tu postura para que te sientas mejor.',
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

  Widget _buildMenuButton({
    required BuildContext context,
    required String title,
    // String description se elimina de los parámetros para simplificar
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: kMediumElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kExtraLargeBorderRadius)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kExtraLargeBorderRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: kLargePadding,
              vertical: 30),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: color.withValues(
                      alpha: 0.1), // Opacidad reducida para menos distracción
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 42, // Icono mucho más grande
                ),
              ),
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

  Widget _buildTipsCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kLargeBorderRadius)),
      child: Padding(
        padding: const EdgeInsets.all(kLargePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.lightbulb_outline,
                    color: Color(0xFFF39C12),
                    size: 30),
                SizedBox(width: 12),
                Text(
                  'Mejora tu Postura',
                  style: TextStyle(
                    fontSize: kMediumFontSize,
                    fontWeight: FontWeight.bold,
                    color: kContrastColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Se usa el mismo estilo para todos los ítems de la lista
            _buildTipItem('Mantén la espalda recta y apoyada al sentarte'),
            _buildTipItem('Asegúrate que tus pies toquen el suelo firmemente'),
            _buildTipItem('Posiciona la pantalla a la altura de tus ojos'),
            _buildTipItem('Recuerda levantarte y estirar cada 30-60 minutos'),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kDefaultPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: kSuccessColor,
            size: 26,
          ),
          const SizedBox(width: kDefaultPadding),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: kSmallFontSize,
                color: Color(0xFF4A4A4A),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubtleSuccessIndicator() {
    // Mostrar indicador sutil de éxito en la esquina superior derecha
    OverlayEntry? overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kSmallPadding),
            decoration: BoxDecoration(
              color: Colors.green[600],
              borderRadius: BorderRadius.circular(kExtraLargeBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: kWhiteColor,
                  size: kSmallIconSize,
                ),
                const SizedBox(width: kSmallPadding),
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
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    // Remover después de 1.5 segundos
    Timer(const Duration(milliseconds: 1500), () {
      overlayEntry?.remove();
    });
  }
}
