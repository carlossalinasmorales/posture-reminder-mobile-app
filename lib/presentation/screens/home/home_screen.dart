import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/app_styles.dart';
import '../../bloc/reminder_bloc.dart';
import '../create_reminder/create_reminder_screen.dart';
import '../my_reminders/my_reminders_screen.dart';

// Widgets locales
import 'widgets/user_menu_button.dart';
import 'widgets/loading_indicator.dart';
import 'widgets/welcome_card.dart';
import 'widgets/menu_button.dart';
import 'widgets/tips_card.dart';
import 'widgets/success_indicator_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  void _initializeScreen() {
    final reminderBloc = context.read<ReminderBloc>();
    reminderBloc.add(LoadReminders());
    _checkAndSyncIfAuthenticated();
    reminderBloc.add(WatchReminders());
  }

  Future<void> _checkAndSyncIfAuthenticated() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<ReminderBloc>().add(SyncWithFirebase());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhiteColor,
      appBar: AppBar(
        elevation: kDefaultElevation,
        backgroundColor: kWhiteColor,
        title: const Text('Recordatorios de Postura', style: kTitleTextStyle),
        actions: [
          UserMenuButton(onShowSuccessIndicator: _showSubtleSuccessIndicator),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<ReminderBloc, ReminderState>(
        listener: _handleBlocStateChanges,
        builder: (context, state) {
          if (state is ReminderLoading) return const LoadingIndicator();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(kLargePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const WelcomeCard(),
                const SizedBox(height: 15),
                MenuButton(
                  title: 'Ver Mis Recordatorios',
                  icon: Icons.list_alt,
                  color: kPrimaryColor,
                  onTap: () => _navigateTo(context, const MyRemindersScreen()),
                ),
                const SizedBox(height: 15),
                MenuButton(
                  title: 'Crear Nuevo Recordatorio',
                  icon: Icons.add_circle,
                  color: kSecondaryColor,
                  onTap: () =>
                      _navigateTo(context, const CreateReminderScreen()),
                ),
                const SizedBox(height: 15),
                const TipsCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleBlocStateChanges(BuildContext context, ReminderState state) {
    if (state is ReminderError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (state is ReminderOperationSuccess) {
      _showSubtleSuccessIndicator();
    }
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _showSubtleSuccessIndicator() {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(builder: (_) => const SuccessIndicatorOverlay());
    overlay.insert(entry);
    Timer(const Duration(milliseconds: 1500), entry.remove);
  }
}
