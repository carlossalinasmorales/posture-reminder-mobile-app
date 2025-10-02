import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/reminder.dart';
import '../bloc/reminder_bloc.dart';
import '../widgets/reminder_card.dart';
import 'create_reminder_screen.dart';

// Constantes de diseño para accesibilidad
const double _largeFontSize = 24.0;
const double _mediumFontSize = 20.0;
const double _iconSize = 32.0;
const Color _primaryColor = Color(0xFF007AFF); // Azul fuerte
const Color _contrastColor = Color(0xFF2C3E50); // Gris oscuro para texto

class MyRemindersScreen extends StatefulWidget {
  const MyRemindersScreen({super.key});

  @override
  State<MyRemindersScreen> createState() => _MyRemindersScreenState();
}

class _MyRemindersScreenState extends State<MyRemindersScreen> {
  // El filtro ahora se representa como una cadena para el Dropdown
  String? _currentFilterLabel;

  @override
  void initState() {
    super.initState();
    // Inicializar el estado de filtro al cargar todos los recordatorios
    _currentFilterLabel = 'Todos';
    context.read<ReminderBloc>().add(LoadReminders());
  }

  // Mapeo simple de etiquetas a estados
  ReminderStatus? _getFilterStatus(String label) {
    switch (label) {
      case 'Pendientes':
        return ReminderStatus.pending;
      case 'Completados':
        return ReminderStatus.completed;
      case 'Omitidos':
        return ReminderStatus.skipped;
      case 'Aplazados':
        return ReminderStatus.postponed;
      case 'Todos':
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: _contrastColor, size: _iconSize),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mis Recordatorios',
          style: TextStyle(
            color: _contrastColor,
            fontSize: 26.0,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: _primaryColor, size: _iconSize),
            onPressed: () {
              context.read<ReminderBloc>().add(SyncWithFirebase());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Sincronizando la información...',
                    style:
                        TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: _primaryColor,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: BlocConsumer<ReminderBloc, ReminderState>(
        listener: (context, state) {
          if (state is ReminderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '¡Error! ${state.message}',
                  style: const TextStyle(
                      fontSize: 18.0, fontWeight: FontWeight.bold),
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
                      fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.green[700],
              ),
            );
            context.read<ReminderBloc>().add(LoadReminders());
          }
        },
        builder: (context, state) {
          if (state is ReminderLoading) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: _primaryColor,
              ),
            );
          }

          if (state is ReminderLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<ReminderBloc>().add(SyncWithFirebase());
                await Future.delayed(const Duration(seconds: 1));
              },
              child: CustomScrollView(
                slivers: [
                  // Filtros (Ahora un Dropdown visible y estático)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 20.0),
                      child: _buildFilterDropdown(), // Usamos el nuevo widget
                    ),
                  ),

                  // Lista de recordatorios
                  if (state.filteredReminders.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final reminder = state.filteredReminders[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              // Nota: La simplificación visual de la tarjeta debe hacerse
                              // DENTRO del widget 'ReminderCard'. Aquí solo se aplica
                              // más espacio entre ellas para mayor claridad.
                              child: ReminderCard(
                                reminder: reminder,
                                onComplete: () => context
                                    .read<ReminderBloc>()
                                    .add(CompleteReminder(reminder.id)),
                                onPostpone: () => context
                                    .read<ReminderBloc>()
                                    .add(PostponeReminder(reminder.id,
                                        const Duration(minutes: 5))),
                                onSkip: () => context
                                    .read<ReminderBloc>()
                                    .add(SkipReminder(reminder.id)),
                                onEdit: () => _navigateToEdit(reminder),
                                onDelete: () => _showDeleteDialog(reminder.id),
                              ),
                            );
                          },
                          childCount: state.filteredReminders.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            );
          }

          return _buildEmptyState();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreate(),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 30),
        label: const Text(
          'Nuevo Recordatorio',
          style:
              TextStyle(fontSize: _mediumFontSize, fontWeight: FontWeight.bold),
        ),
        elevation: 6,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // --- Widgets Auxiliares Mejorados ---

  Widget _buildFilterDropdown() {
    // Las opciones son explícitas y no requieren deslizamiento
    const List<String> filterLabels = [
      'Todos',
      'Pendientes',
      'Completados',
      'Omitidos',
      'Aplazados',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filtrar por estado:',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: _contrastColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _primaryColor, width: 2), // Borde claro y grueso
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _currentFilterLabel,
              icon:
                  const Icon(Icons.filter_list, size: 30, color: _primaryColor),
              style: const TextStyle(
                fontSize: _mediumFontSize, // Texto grande
                color: _contrastColor,
              ),
              dropdownColor: Colors.white,
              elevation: 4,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _currentFilterLabel = newValue;
                  });
                  // Notificar al BLoC para aplicar el filtro
                  context
                      .read<ReminderBloc>()
                      .add(FilterReminders(_getFilterStatus(newValue)));
                }
              },
              items: filterLabels.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: _mediumFontSize,
                        fontWeight: _currentFilterLabel == value
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _currentFilterLabel == value
                            ? _primaryColor
                            : _contrastColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // El resto de los métodos auxiliares (EmptyState, navegación, diálogo) se mantienen sin cambios
  // ya que fueron mejorados en el paso anterior y no necesitan más simplificación.

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 120,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 30),
            Text(
              _currentFilterLabel == 'Todos'
                  ? '¡No hay recordatorios!'
                  : 'No hay recordatorios ${_currentFilterLabel?.toLowerCase()}',
              style: const TextStyle(
                fontSize: _largeFontSize,
                color: _contrastColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            const Text(
              'Toca el botón azul "Nuevo Recordatorio" para comenzar.',
              style: TextStyle(
                fontSize: 18.0,
                color: Color(0xFF6C7A89),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // String _getFilterName(ReminderStatus status) {
  //   switch (status) {
  //     case ReminderStatus.pending:
  //       return 'pendientes';
  //     case ReminderStatus.completed:
  //       return 'completados';
  //     case ReminderStatus.skipped:
  //       return 'omitidos';
  //     case ReminderStatus.postponed:
  //       return 'aplazados';
  //   }
  // }

  void _navigateToCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateReminderScreen()),
    ).then((_) {
      context.read<ReminderBloc>().add(LoadReminders());
    });
  }

  void _navigateToEdit(Reminder reminder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateReminderScreen(reminder: reminder),
      ),
    ).then((_) {
      context.read<ReminderBloc>().add(LoadReminders());
    });
  }

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          '¿Eliminar recordatorio?',
          style:
              TextStyle(fontSize: _mediumFontSize, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '¿Estás seguro/a? Esta acción no se puede deshacer.',
          style: TextStyle(fontSize: 18.0),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 18.0, color: _primaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ReminderBloc>().add(DeleteReminder(id));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'ELIMINAR',
              style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
