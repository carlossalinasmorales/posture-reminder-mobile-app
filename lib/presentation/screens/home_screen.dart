import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart';
import '../../domain/entities/reminder.dart';
import '../bloc/reminder_bloc.dart';
import '../widgets/reminder_card.dart';
import '../widgets/statistics_card.dart';
import 'create_reminder_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ReminderStatus? _currentFilter;

  @override
  void initState() {
    super.initState();
    context.read<ReminderBloc>().add(LoadReminders());
    context.read<ReminderBloc>().add(WatchReminders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Recordatorios de Postura',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Color(0xFF3498DB), size: 32),
            onPressed: () {
              context.read<ReminderBloc>().add(SyncWithFirebase());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Sincronizando...',
                    style: TextStyle(fontSize: 16),
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<ReminderBloc, ReminderState>(
        listener: (context, state) {
          if (state is ReminderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(fontSize: 16),
                ),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is ReminderOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(fontSize: 16),
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ReminderLoading) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF3498DB),
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
                  // Estadísticas
                  if (state.statistics != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: StatisticsCard(statistics: state.statistics!),
                      ),
                    ),

                  // Filtros
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildFilters(),
                    ),
                  ),

                  // Lista de recordatorios
                  if (state.filteredReminders.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final reminder = state.filteredReminders[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ReminderCard(
                                reminder: reminder,
                                onComplete: () => context
                                    .read<ReminderBloc>()
                                    .add(CompleteReminder(reminder.id)),
                                onPostpone: () => context
                                    .read<ReminderBloc>()
                                    .add(PostponeReminder(
                                      reminder.id,
                                      const Duration(minutes: 2),
                                    )),
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
                ],
              ),
            );
          }

          return const Center(
            child: Text(
              'Toca el botón + para crear tu primer recordatorio',
              style: TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreate(),
        backgroundColor: const Color(0xFF3498DB),
        icon: const Icon(Icons.add, size: 32),
        label: const Text(
          'Nuevo Recordatorio',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Todos', null),
          const SizedBox(width: 8),
          _buildFilterChip('Pendientes', ReminderStatus.pending),
          const SizedBox(width: 8),
          _buildFilterChip('Completados', ReminderStatus.completed),
          const SizedBox(width: 8),
          _buildFilterChip('Omitidos', ReminderStatus.skipped),
          const SizedBox(width: 8),
          _buildFilterChip('Aplazados', ReminderStatus.postponed),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ReminderStatus? status) {
    final isSelected = _currentFilter == status;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isSelected ? Colors.white : const Color(0xFF2C3E50),
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _currentFilter = status;
        });
        context.read<ReminderBloc>().add(FilterReminders(status));
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF3498DB),
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: isSelected ? 4 : 1,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            _currentFilter == null
                ? 'No hay recordatorios'
                : 'No hay recordatorios ${_getFilterName(_currentFilter!)}',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Toca el botón + para crear uno nuevo',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterName(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.pending:
        return 'pendientes';
      case ReminderStatus.completed:
        return 'completados';
      case ReminderStatus.skipped:
        return 'omitidos';
      case ReminderStatus.postponed:
        return 'aplazados';
    }
  }

  void _navigateToCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateReminderScreen()),
    );
  }

  void _navigateToEdit(Reminder reminder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateReminderScreen(reminder: reminder),
      ),
    );
  }

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '¿Eliminar recordatorio?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Esta acción no se puede deshacer.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              this.context.read<ReminderBloc>().add(DeleteReminder(id));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
