import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/reminder.dart';
import '../../bloc/reminder_bloc.dart';
import 'widgets/reminder_card.dart';
import '/presentation/screens/create_reminder/create_reminder_screen.dart';
import '../../../theme/app_styles.dart';
import 'reminder_list_controller.dart';
import 'widgets/filter_dropdown.dart';
import 'widgets/empty_state.dart';
import 'widgets/success_indicator.dart';

class MyRemindersScreen extends StatefulWidget {
  const MyRemindersScreen({super.key});

  @override
  State<MyRemindersScreen> createState() => _MyRemindersScreenState();
}

class _MyRemindersScreenState extends State<MyRemindersScreen> {
  late ReminderListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReminderListController();
    context.read<ReminderBloc>().add(LoadReminders());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: _buildAppBar(),
      body: BlocConsumer<ReminderBloc, ReminderState>(
        listener: _handleBlocListener,
        builder: _buildBlocContent,
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: kDefaultElevation,
      backgroundColor: kWhiteColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back,
            color: kContrastColor, size: kLargeIconSize),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Mis Recordatorios', style: kTitleTextStyle),
    );
  }

  void _handleBlocListener(BuildContext context, ReminderState state) {
    if (state is ReminderError) {
      _showErrorSnackBar(state.message);
    } else if (state is ReminderOperationSuccess) {
      SuccessIndicatorHelper.show(context);
      context.read<ReminderBloc>().add(LoadReminders());
    }
  }

  Widget _buildBlocContent(BuildContext context, ReminderState state) {
    if (state is ReminderLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 4, color: kPrimaryColor),
      );
    }

    if (state is ReminderLoaded) {
      return _buildReminderList(state);
    }

    return EmptyStateWidget(filterLabel: _controller.currentFilterLabel);
  }

  Widget _buildReminderList(ReminderLoaded state) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: kWhiteColor,
            padding: const EdgeInsets.symmetric(
              vertical: kDefaultPadding,
              horizontal: kLargePadding,
            ),
            child: FilterDropdownWidget(
              currentFilter: _controller.currentFilterLabel,
              onFilterChanged: (newFilter) {
                setState(() => _controller.updateFilter(newFilter));
                context.read<ReminderBloc>().add(
                      FilterReminders(_controller.getFilterStatus(newFilter)),
                    );
              },
            ),
          ),
        ),
        if (state.filteredReminders.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child:
                EmptyStateWidget(filterLabel: _controller.currentFilterLabel),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: kLargePadding),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildReminderItem(state.filteredReminders[index]),
                childCount: state.filteredReminders.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildReminderItem(Reminder reminder) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kDefaultPadding),
      child: ReminderCard(
        reminder: reminder,
        onComplete: () =>
            context.read<ReminderBloc>().add(CompleteReminder(reminder.id)),
        onSkip: () =>
            context.read<ReminderBloc>().add(SkipReminder(reminder.id)),
        onEdit: () => _navigateToEdit(reminder),
        onDelete: () => _handleDelete(reminder.id),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _navigateToCreate,
      backgroundColor: kPrimaryColor,
      foregroundColor: kWhiteColor,
      icon: const Icon(Icons.add, size: kLargeIconSize),
      label: const Text('Nuevo Recordatorio', style: kButtonTextStyle),
      elevation: kHighElevation,
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

  void _handleDelete(String id) {
    final currentState = context.read<ReminderBloc>().state;
    if (currentState is! ReminderLoaded) return;

    final reminder = currentState.reminders.firstWhere(
      (r) => r.id == id,
      orElse: () => throw Exception('Recordatorio no encontrado'),
    );

    _controller.saveDeletedReminder(reminder);
    context.read<ReminderBloc>().add(DeleteReminder(id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${reminder.title} eliminado'),
        backgroundColor: kContrastColor,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DESHACER',
          textColor: kWhiteColor,
          onPressed: _undoDeletion,
        ),
      ),
    );
  }

  void _undoDeletion() {
    final deletedReminder = _controller.getDeletedReminder();
    if (deletedReminder == null) return;

    context.read<ReminderBloc>().add(CreateReminder(
          title: deletedReminder.title,
          description: deletedReminder.description,
          dateTime: deletedReminder.dateTime,
          frequency: deletedReminder.frequency,
          customDays: deletedReminder.customDays,
          customInterval: deletedReminder.customInterval,
        ));

    _controller.clearDeletedReminder();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recordatorio restaurado'),
        backgroundColor: kSuccessColor,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.contains('sincronizar')
              ? 'Error de sincronización'
              : 'Error inesperado',
          style: kBodyTextStyle,
        ),
        backgroundColor: kErrorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
