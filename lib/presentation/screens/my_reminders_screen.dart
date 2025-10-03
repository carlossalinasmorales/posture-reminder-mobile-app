import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/reminder.dart';
import '../bloc/reminder_bloc.dart';
import '../widgets/reminder_card.dart';
import 'create_reminder_screen.dart';
import '../../theme/app_styles.dart';

class MyRemindersScreen extends StatefulWidget {
  const MyRemindersScreen({super.key});

  @override
  State<MyRemindersScreen> createState() => _MyRemindersScreenState();
}

class _MyRemindersScreenState extends State<MyRemindersScreen> {
  String? _currentFilterLabel;
  Reminder? _deletedReminder;
  Timer? _undoTimer;

  @override
  void initState() {
    super.initState();
    _currentFilterLabel = 'Todos';
    context.read<ReminderBloc>().add(LoadReminders());
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    super.dispose();
  }

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
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(
        elevation: kDefaultElevation,
        backgroundColor: kWhiteColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: kContrastColor, size: kLargeIconSize),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Mis Recordatorios', style: kTitleTextStyle),
      ),
      body: BlocConsumer<ReminderBloc, ReminderState>(
        listener: (context, state) {
          if (state is ReminderError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message.contains('sincronizar')
                      ? 'Error de sincronización'
                      : 'Error inesperado',
                  style: kBodyTextStyle,
                ),
                backgroundColor: kErrorColor,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is ReminderOperationSuccess) {
            _showSubtleSuccessIndicator();
            context.read<ReminderBloc>().add(LoadReminders());
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

          if (state is ReminderLoaded) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: kDefaultPadding, horizontal: kLargePadding),
                    child: _buildFilterDropdown(),
                  ),
                ),
                if (state.filteredReminders.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: kLargePadding),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final reminder = state.filteredReminders[index];
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: kDefaultPadding),
                            child: ReminderCard(
                              reminder: reminder,
                              onComplete: () => context
                                  .read<ReminderBloc>()
                                  .add(CompleteReminder(reminder.id)),
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
            );
          }

          return _buildEmptyState();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreate,
        backgroundColor: kPrimaryColor,
        foregroundColor: kWhiteColor,
        icon: const Icon(Icons.add, size: kLargeIconSize),
        label: const Text(
          'Nuevo Recordatorio',
          style: kButtonTextStyle
        ),
        elevation: kHighElevation,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildFilterDropdown() {
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
        const Text('Filtrar por estado:', style: kSubtitleTextStyle),
        const SizedBox(height: kSmallPadding),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: kSmallPadding, vertical: 4),
          decoration: BoxDecoration(
            color: kBackgroundColor,
            borderRadius: BorderRadius.circular(kDefaultBorderRadius),
            border: Border.all(color: kPrimaryColor, width: 2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _currentFilterLabel,
              icon: const Icon(Icons.filter_list,
                  size: kLargeIconSize, color: kPrimaryColor),
              style: kBodyTextStyle.copyWith(fontSize: kMediumFontSize),
              dropdownColor: kWhiteColor,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _currentFilterLabel = newValue);
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
                      style: kBodyTextStyle.copyWith(
                        fontSize: kMediumFontSize,
                        fontWeight: _currentFilterLabel == value
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _currentFilterLabel == value
                            ? kPrimaryColor
                            : kContrastColor,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kExtraLargePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none,
                size: 120, color: Colors.grey[400]),
            const SizedBox(height: kLargePadding),
            Text(
              _currentFilterLabel == 'Todos'
                  ? '¡No hay recordatorios!'
                  : 'No hay recordatorios ${_currentFilterLabel?.toLowerCase()}',
              style: kTitleTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kSmallPadding),
            Text(
              'Toca el botón "Nuevo Recordatorio" para comenzar.',
              style: kBodyTextStyle.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateReminderScreen()),
    ).then((_) => context.read<ReminderBloc>().add(LoadReminders()));
  }

  void _navigateToEdit(Reminder reminder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateReminderScreen(reminder: reminder),
      ),
    ).then((_) => context.read<ReminderBloc>().add(LoadReminders()));
  }

  void _showSubtleSuccessIndicator() {
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding, vertical: kSmallPadding),
            decoration: BoxDecoration(
              color: kSuccessColor,
              borderRadius: BorderRadius.circular(kLargeBorderRadius),
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
                Icon(Icons.check_circle, color: kWhiteColor, size: kSmallIconSize),
                SizedBox(width: kSmallPadding),
                Text('Listo',
                    style: TextStyle(
                      color: kWhiteColor,
                      fontSize: kExtraSmallFontSize,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Timer(const Duration(milliseconds: 1500), () => overlayEntry?.remove());
  }

  void _showDeleteDialog(String id) {
    final currentState = context.read<ReminderBloc>().state;
    if (currentState is! ReminderLoaded) return;

    _deletedReminder = currentState.reminders.firstWhere(
      (r) => r.id == id,
      orElse: () => throw Exception('Recordatorio no encontrado'),
    );

    context.read<ReminderBloc>().add(DeleteReminder(id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_deletedReminder!.title} eliminado'),
        backgroundColor: kContrastColor,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DESHACER',
          textColor: kWhiteColor,
          onPressed: _undoDeletion,
        ),
      ),
    );

    _undoTimer?.cancel();
    _undoTimer = Timer(const Duration(seconds: 5), () {
      _deletedReminder = null;
    });
  }

  void _undoDeletion() {
    if (_deletedReminder == null) return;

    context.read<ReminderBloc>().add(CreateReminder(
          title: _deletedReminder!.title,
          description: _deletedReminder!.description,
          dateTime: _deletedReminder!.dateTime,
          frequency: _deletedReminder!.frequency,
          customDays: _deletedReminder!.customDays,
          customInterval: _deletedReminder!.customInterval,
        ));

    _deletedReminder = null;
    _undoTimer?.cancel();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recordatorio restaurado'),
        backgroundColor: kSuccessColor,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
