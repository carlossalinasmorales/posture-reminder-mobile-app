import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'data/datasources/local_datasource.dart';
import 'data/datasources/notification_service.dart';
import 'data/repositories/reminder_repository_impl_no_firebase.dart';
import 'presentation/bloc/reminder_bloc.dart';
import 'presentation/screens/home_screen.dart';

// Variable global para acceder al BLoC desde el callback de notificaciones
late ReminderBloc globalReminderBloc;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  await _requestPermissions();

  final localDataSource = LocalDataSource();

  try {
    await localDataSource.syncFromSharedPreferences();
  } catch (e) {
    print('Error sincronizando datos locales: $e');
  }

  final repository = ReminderRepositoryImplNoFirebase(
    localDataSource: localDataSource,
    notificationService: notificationService,
  );

  // Crear el BLoC global
  globalReminderBloc = ReminderBloc(repository: repository);

  // Registrar el callback para manejar acciones de notificaciones
  notificationService.onActionReceived = (reminderId, action) {
    print('Acción recibida: $action para recordatorio: $reminderId');

    if (action == 'complete') {
      globalReminderBloc.add(CompleteReminder(reminderId));
    } else if (action == 'postpone') {
      globalReminderBloc
          .add(PostponeReminder(reminderId, const Duration(minutes: 2)));
    }
  };

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
            headlineMedium:
                TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
        home: const HomeScreen(),
      ),
    );
  }
}
