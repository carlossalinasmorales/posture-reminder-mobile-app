import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'data/datasources/local_datasource.dart';
import 'data/datasources/notification_service.dart';
import 'data/repositories/reminder_repository_impl_no_firebase.dart';
import 'presentation/bloc/reminder_bloc.dart';
import 'presentation/screens/home_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar servicios
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  // Solicitar permisos
  await _requestPermissions();

  // Inicializar datasource local
  final localDataSource = LocalDataSource();

  // Sincronizar datos locales al inicio
  try {
    await localDataSource.syncFromSharedPreferences();
  } catch (e) {
    print('Error sincronizando datos locales: $e');
  }

  // Crear repositorio SIN Firebase
  final repository = ReminderRepositoryImplNoFirebase(
    localDataSource: localDataSource,
    notificationService: notificationService,
  );

  runApp(MyApp(repository: repository));
}

Future<void> _requestPermissions() async {
  // Permisos de notificaciones
  await Permission.notification.request();

  // Permisos de alarmas exactas (Android 12+)
  if (await Permission.scheduleExactAlarm.isDenied) {
    await Permission.scheduleExactAlarm.request();
  }
}

class MyApp extends StatelessWidget {
  final ReminderRepositoryImplNoFirebase repository;

  const MyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReminderBloc(repository: repository),
      child: MaterialApp(
        title: 'Recordatorios de Postura',
        debugShowCheckedModeBanner: false,

        // AGREGAR ESTAS LÍNEAS:
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
            displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
            displayMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            displaySmall: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            headlineMedium:
                TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            bodyLarge: TextStyle(fontSize: 20),
            bodyMedium: TextStyle(fontSize: 18),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
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
