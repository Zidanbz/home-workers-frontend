import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:home_workers_fe/features/auth/pages/login_page.dart';
import 'package:home_workers_fe/features/onborading/pages/onboarding_page.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/state/auth_provider.dart'; // Impor halaman baru
import 'features/auth/pages/welcome_page.dart';
import 'features/main_page.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
    await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        locale: const Locale('id', 'ID'),

        title: 'Home Workers',
        theme: ThemeData(/* ... */ fontFamily: 'OpenSans'),
        // Gunakan AuthWrapper sebagai home, ia akan menangani semua logika
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// AuthWrapper sekarang memeriksa 3 kondisi: sudah login, sudah lihat onboarding, atau baru pertama kali.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<String> _getInitialRoute() async {
    final authProvider = AuthProvider(); // Buat instance sementara
    await authProvider.tryAutoLogin(); // Coba auto-login

    if (authProvider.isLoggedIn) {
      return '/main'; // Rute jika sudah login
    }

    // Jika tidak login, cek apakah sudah pernah lihat onboarding
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (hasSeenOnboarding) {
      return '/welcome'; // Rute jika sudah lihat onboarding tapi belum login
    } else {
      return '/onboarding'; // Rute untuk pengguna baru
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan Consumer untuk "mendengarkan" perubahan di AuthProvider
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        // Saat aplikasi pertama kali dibuka dan sedang memeriksa semuanya
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

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
