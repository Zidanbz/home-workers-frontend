import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:home_workers_fe/features/auth/pages/login_page.dart';
import 'package:home_workers_fe/features/onboarding/pages/onboarding_page.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/state/auth_provider.dart'; // Impor halaman baru
import 'core/services/encryption_service.dart';
import 'core/services/realtime_notification_service.dart';
import 'core/services/chat_service.dart';
import 'features/auth/pages/welcome_page.dart';
import 'features/auth/pages/worker_kyc_revision_page.dart';
import 'features/auth/pages/worker_registration_status_page.dart';
import 'features/main_page.dart';
import 'features/profile/pages/address_management_page.dart';
import 'firebase_env_options.dart';
import 'core/widgets/app_version_gate.dart';
import 'core/navigation/app_navigator.dart';
import 'core/widgets/notification_order_detail_route.dart';

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
    await Firebase.initializeApp(options: firebaseOptions);
    print('🔥 [main] Firebase initialized successfully');
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
    final existing = Firebase.app();
    final expectedProjectId = firebaseOptions.projectId;
    final actualProjectId = existing.options.projectId;
    if (actualProjectId != expectedProjectId) {
      await existing.delete();
      await Firebase.initializeApp(options: firebaseOptions);
      print(
        '🔥 [main] Reinitialized Firebase project=$expectedProjectId '
        'after duplicate app mismatch from $actualProjectId',
      );
    } else {
      print(
        '🔥 [main] Reusing existing Firebase app: ${existing.options.projectId}',
      );
    }
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
        navigatorKey: AppNavigator.navigatorKey,
        locale: const Locale('id', 'ID'),
        title: 'Home Workers',
        theme: ThemeData(/* ... */ fontFamily: 'OpenSans'),
        // Pembaruan wajib (Android): lihat docs/environment-and-mandatory-update.md
        home: const AppVersionGate(child: AuthWrapper()),
        routes: {
          '/address-management': (context) => const AddressManagementPage(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/order-detail') {
            final orderId = settings.arguments?.toString().trim() ?? '';
            if (orderId.isEmpty) return null;
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => NotificationOrderDetailRoute(orderId: orderId),
            );
          }
          return null;
        },
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
          AppNavigator.setAuthenticatedRouteReady(false);
          return const SizedBox.shrink();
        }

        _removeNativeSplash();

        // Jika sudah login, langsung ke halaman utama
        if (auth.isLoggedIn) {
          AppNavigator.setAuthenticatedRouteReady(false);
          if (auth.user!.role.toUpperCase() == 'WORKER') {
            final status = auth.user!.workerStatus?.toLowerCase();
            if (status == 'revision_required') {
              return const WorkerKycRevisionPage();
            }
            if (status == 'pending' || status == 'resubmitted') {
              return WorkerRegistrationStatusPage(status: status!);
            }
            if (status == 'rejected') {
              return WorkerRegistrationStatusPage(
                status: status!,
                rejectionReason: auth.user!.rejectionReason,
              );
            }
            if (status != 'approved') {
              return WorkerRegistrationStatusPage(
                status: status ?? 'registration_incomplete',
                rejectionReason: auth.user!.rejectionReason,
              );
            }
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppNavigator.setAuthenticatedRouteReady(true);
          });
          return MainPage(userRole: auth.user!.role);
        }

        // Jika belum login, periksa status onboarding
        AppNavigator.setAuthenticatedRouteReady(false);
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
