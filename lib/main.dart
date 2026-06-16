import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:home_workers_fe/features/auth/pages/login_page.dart';
import 'package:home_workers_fe/features/onborading/pages/onboarding_page.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/state/auth_provider.dart'; // Impor halaman baru
import 'core/services/encryption_service.dart';
import 'core/services/realtime_notification_service.dart';
import 'core/services/chat_service.dart';
import 'features/auth/pages/welcome_page.dart';
import 'features/main_page.dart';
import 'firebase_env_options.dart';
import 'core/widgets/app_version_gate.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await initializeDateFormatting('id_ID');
  const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'prod');
  final envFile = appEnv.toLowerCase() == 'sandbox' ? '.env.sandbox' : '.env';
  final firebaseOptions = AppFirebaseOptions.forAppEnv(appEnv);
  print('🧩 [main] APP_ENV=$appEnv → loading $envFile');
  await dotenv.load(fileName: envFile);
  print(
    '🔥 [main] Firebase project=${AppFirebaseOptions.projectIdFor(appEnv)}',
  );
  try {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Android uses google-services*.json selected at build-time.
      await Firebase.initializeApp();
    } else {
      await Firebase.initializeApp(options: firebaseOptions);
    }
    print('🔥 [main] Firebase initialized successfully');
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
    final existing = Firebase.app();
    print(
      '🔥 [main] Reusing existing Firebase app: ${existing.options.projectId}',
    );
  }

  // Initialize services
  EncryptionService().initialize();
  print('🔐 [main] EncryptionService initialized successfully');

  try {
    await RealtimeNotificationService.initialize();
  } catch (e) {
    print('❌ [main] RealtimeNotificationService init failed: $e');
  }

  try {
    await ChatService.initialize();
  } catch (e) {
    print('❌ [main] ChatService init failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(
          create: (context) => RealtimeNotificationService(),
        ),
        ChangeNotifierProvider(create: (context) => ChatService()),
      ],
      child: MaterialApp(
        locale: const Locale('id', 'ID'),
        title: 'Home Workers',
        theme: ThemeData(/* ... */ fontFamily: 'OpenSans'),
        // Pembaruan wajib (Android): lihat docs/environment-and-mandatory-update.md
        home: const AppVersionGate(child: AuthWrapper()),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// AuthWrapper sekarang memeriksa 3 kondisi: sudah login, sudah lihat onboarding, atau baru pertama kali.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _nativeSplashRemoved = false;

  void _removeNativeSplash() {
    if (_nativeSplashRemoved) return;
    _nativeSplashRemoved = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan Consumer untuk "mendengarkan" perubahan di AuthProvider
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        // Saat aplikasi pertama kali dibuka dan sedang memeriksa semuanya
        if (auth.isLoading) {
          return const SizedBox.shrink();
        }

        _removeNativeSplash();

        // Jika sudah login, langsung ke halaman utama
        if (auth.isLoggedIn) {
          return MainPage(userRole: auth.user!.role);
        }

        // Jika belum login, periksa status onboarding
        if (auth.hasSeenOnboarding) {
          // Jika sudah lihat onboarding, tampilkan halaman auth yang sesuai
          switch (auth.authScreen) {
            case AuthScreen.login:
              return const LoginPage();
            case AuthScreen.welcome:
            default:
              return const WelcomePage();
          }
        } else {
          // Jika belum pernah lihat onboarding, tampilkan OnboardingPage
          return const OnboardingPage();
        }
      },
    );
  }
}
