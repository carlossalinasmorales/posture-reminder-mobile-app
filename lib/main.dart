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
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/login/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_styles.dart';

late ReminderBloc globalReminderBloc;
final GlobalKey<_AuthWrapperState> authWrapperKey = GlobalKey<_AuthWrapperState>();

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
            seedColor: kPrimaryColor,
            brightness: Brightness.light,
          ),
          fontFamily: 'Roboto',
          textTheme: TextTheme(
            displayLarge: kTitleTextStyle.copyWith(fontSize: 32),
            displayMedium: kTitleTextStyle.copyWith(fontSize: 28),
            displaySmall: kTitleTextStyle,
            headlineMedium: kSubtitleTextStyle,
            bodyLarge: kBodyTextStyle.copyWith(fontSize: 18),
            bodyMedium: kBodyTextStyle,
            bodySmall: kCaptionTextStyle,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: kPrimaryButtonStyle,
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: kSecondaryButtonStyle,
          ),
          cardTheme: CardThemeData(
            elevation: kDefaultElevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kLargeBorderRadius),
            ),
          ),
          appBarTheme: kAppBarTheme,
          snackBarTheme: kSnackBarTheme,
        ),
        home: AuthWrapper(key: authWrapperKey),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  
  void refresh() {
    if (mounted) {
      setState(() {});
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Verificar modo invitado de forma síncrona usando FutureBuilder interno
        return FutureBuilder<bool>(
          future: _checkGuestMode(),
          builder: (context, guestSnapshot) {
            if (guestSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Si está en modo invitado, mostrar HomeScreen
            if (guestSnapshot.data == true) {
              return const HomeScreen();
            }

            // Si está autenticado con Firebase, mostrar HomeScreen y sincronizar
            if (snapshot.hasData && snapshot.data != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.read<ReminderBloc>().add(SyncWithFirebase());
                }
              });
              return const HomeScreen();
            }

            // Si no hay autenticación, mostrar LoginScreen
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
