import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'data/datasources/local_datasource.dart';
import 'data/datasources/firebase_datasource.dart';
import 'data/datasources/notification_service.dart';
import 'data/repositories/reminder_repository_impl.dart';
import 'presentation/bloc/reminder_bloc.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

late ReminderBloc globalReminderBloc;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp();

  final notificationService = NotificationService();
  await _requestPermissions();

  final localDataSource = LocalDataSource();
  final firebaseDataSource = FirebaseDataSource();

  try {
    await localDataSource.syncFromSharedPreferences();
  } catch (e) {
    print('Error sincronizando datos locales: $e');
  }

  final repository = ReminderRepositoryImpl(
    localDataSource: localDataSource,
    firebaseDataSource: firebaseDataSource,
    notificationService: notificationService,
  );

  globalReminderBloc = ReminderBloc(repository: repository);

  notificationService.onActionReceived = (reminderId, action) {
    print('Acción recibida: $action para recordatorio: $reminderId');

    if (action == 'complete') {
      globalReminderBloc.add(CompleteReminder(reminderId));
    } else if (action == 'postpone') {
      globalReminderBloc
          .add(PostponeReminder(reminderId, const Duration(minutes: 2)));
    }
  };

  await notificationService.initialize();
  await notificationService.requestPermissions();

  runApp(MyApp(bloc: globalReminderBloc));
}

Future<void> _requestPermissions() async {
  await Permission.notification.request();

  if (await Permission.scheduleExactAlarm.isDenied) {
    await Permission.scheduleExactAlarm.request();
  }
}

class MyApp extends StatelessWidget {
  final ReminderBloc bloc;

  const MyApp({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: MaterialApp(
        title: 'Recordatorios de Postura',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'),
        ],
        locale: const Locale('es', 'ES'),
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3498DB),
            brightness: Brightness.light,
          ),
          fontFamily: 'Roboto',
          textTheme: const TextTheme(
            displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            bodyLarge: TextStyle(fontSize: 18),
            bodyMedium: TextStyle(fontSize: 16),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkGuestMode(),
      builder: (context, guestSnapshot) {
        if (guestSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si está en modo invitado, ir directo al HomeScreen
        if (guestSnapshot.data == true) {
          return const HomeScreen();
        }

        // Si no, verificar autenticación de Firebase
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasData && snapshot.data != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<ReminderBloc>().add(SyncWithFirebase());
              });
              return const HomeScreen();
            }

            return const LoginScreen();
          },
        );
      },
    );
  }

  Future<bool> _checkGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('guest_mode') ?? false;
  }
}