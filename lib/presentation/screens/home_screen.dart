import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/reminder_bloc.dart';
import 'my_reminders_screen.dart';
import 'create_reminder_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Carga inicial y escucha de recordatorios
    context.read<ReminderBloc>().add(LoadReminders());
    context.read<ReminderBloc>().add(WatchReminders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Usar un fondo blanco sólido para máximo contraste
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 1, // Leve elevación para separar de la vista
        backgroundColor: Colors.white,
        title: const Text(
          'Recordatorios de Postura',
          style: TextStyle(
            color: Color(0xFF2C3E50), // Color oscuro para alto contraste
            fontSize: 26, // Título de AppBar más grande
            fontWeight: FontWeight.w900, // Extra-negrita
          ),
        ),
      ),
      body: BlocConsumer<ReminderBloc, ReminderState>(
        listener: (context, state) {
          // Lógica de listener (errores y éxito) simplificada con textos más grandes
          if (state is ReminderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '¡Error! ${state.message}', // Añadir exclamación
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.red[700],
              ),
            );
          } else if (state is ReminderOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '¡Éxito! ${state.message}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.green[700],
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ReminderLoading) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 4, // Grosor mayor
                color: Color(0xFF3498DB),
              ),
            );
          }

          // La funcionalidad de `RefreshIndicator` se mantiene, pero se envuelve
          return RefreshIndicator(
            onRefresh: () async {
              context.read<ReminderBloc>().add(SyncWithFirebase());
              await Future.delayed(const Duration(seconds: 1));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24), // Mayor padding general
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
                    color: const Color(0xFF007AFF), // Azul más fuerte y moderno
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
                    color:
                        const Color(0xFF34C759), // Verde más fuerte y moderno
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
            ),
          );
        },
      ),
    );
  }

  // --- Widgets Auxiliares Mejorados ---

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4, // Mayor elevación
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24), // Mayor padding interno
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          // Se mantiene el gradiente, pero se mejora el color
          gradient: const LinearGradient(
            colors: [
              Color(0xFF8E44AD),
              Color(0xFFC06C84)
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
                  Icons.favorite_border, // Icono más amigable
                  color: Colors.white,
                  size: 48, // Icono más grande
                ),
                SizedBox(width: 16),
                Text(
                  '¡Hola!', // Mensaje más breve y directo
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32, // Título de bienvenida más grande
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Estaremos aquí para cuidar de tu postura. Es por tu bienestar.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 18, // Texto más grande
                height: 1.2, // Mayor espaciado entre líneas
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
      elevation: 4, // Mayor elevación
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical:
                  30), // Padding vertical más grande para facilitar el toque
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(
                    18), // Mayor padding para el círculo del icono
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
                    fontSize: 22, // Título de botón más grande
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              // Flecha de navegación más grande
              Icon(
                Icons.arrow_forward_ios,
                color: color, // Usar el color del botón
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Card(
      elevation: 3, // Ligera elevación
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24), // Mayor padding interno
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.lightbulb_outline, // Icono más claro
                    color: Color(0xFFF39C12),
                    size: 30), // Icono más grande
                SizedBox(width: 12),
                Text(
                  'Mejora tu Postura',
                  style: TextStyle(
                    fontSize: 22, // Título de consejos más grande
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
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
      padding: const EdgeInsets.only(bottom: 16), // Más espacio entre ítems
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline, // Icono de verificación más suave
            color: Color(0xFF34C759), // Verde más fuerte
            size: 26, // Icono más grande
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 18, // Texto de lista más grande
                color: Color(0xFF4A4A4A), // Gris oscuro para mejor contraste
                height: 1.5, // Mayor espaciado entre líneas
              ),
            ),
          ),
        ],
      ),
    );
  }
}
