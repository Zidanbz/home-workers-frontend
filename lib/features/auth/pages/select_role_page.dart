import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_workers_fe/core/state/auth_provider.dart';
import 'package:home_workers_fe/features/auth/pages/login_page.dart';
import 'package:home_workers_fe/features/auth/pages/register_customer_page.dart';
import 'package:home_workers_fe/features/auth/pages/register_worker_page.dart';
import 'package:provider/provider.dart';

class SelectRolePage extends StatelessWidget {
  const SelectRolePage({
    super.key,
    this.googleRegistration = false,
    this.googleName,
    this.googleEmail,
  });

  static const _navy = Color(0xFF1A374D);
  static const _background = Color(0xFFF6F8FB);
  static const _customerColor = Color(0xFF2F80ED);
  static const _workerColor = Color(0xFF16A085);

  final bool googleRegistration;
  final String? googleName;
  final String? googleEmail;

  Future<void> _handleBack(BuildContext context) async {
    if (googleRegistration) {
      await context.read<AuthProvider>().cancelGoogleRegistration();
    }
    if (!context.mounted) return;

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _openCustomerRegistration(BuildContext context) {
    context.read<AuthProvider>().showLoginPage();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterCustomerPage(
          googleRegistration: googleRegistration,
          initialName: googleName,
          initialEmail: googleEmail,
        ),
      ),
    );
  }

  void _openWorkerRegistration(BuildContext context) {
    context.read<AuthProvider>().showLoginPage();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterWorkerPage(
          googleRegistration: googleRegistration,
          initialName: googleName,
          initialEmail: googleEmail,
        ),
      ),
    );
  }

  void _openLogin(BuildContext context) {
    context.read<AuthProvider>().showLoginPage();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: Stack(
          children: [
            const Positioned(
              top: -150,
              right: -100,
              child: _BackgroundOrb(size: 310, color: Color(0x142F80ED)),
            ),
            const Positioned(
              bottom: -130,
              left: -110,
              child: _BackgroundOrb(size: 280, color: Color(0x1216A085)),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    key: const Key('select-role-scroll-view'),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight > 40
                            ? constraints.maxHeight - 40
                            : 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TopBar(onBack: () => _handleBack(context)),
                          const SizedBox(height: 30),
                          _PageHeader(googleRegistration: googleRegistration),
                          const SizedBox(height: 28),
                          _RoleCard(
                            key: const Key('customer-role-card'),
                            roleLabel: 'SEBAGAI CUSTOMER',
                            title: 'Saya butuh bantuan',
                            description:
                                'Temukan tenaga ahli tepercaya dan pesan layanan rumah dengan mudah.',
                            imagePath: 'assets/costumer.png',
                            accentColor: _customerColor,
                            onTap: () => _openCustomerRegistration(context),
                            semanticLabel: 'Daftar sebagai Customer',
                          ),
                          const SizedBox(height: 16),
                          _RoleCard(
                            key: const Key('worker-role-card'),
                            roleLabel: 'SEBAGAI MITRA',
                            title: 'Saya ingin menawarkan jasa',
                            description:
                                'Tawarkan keahlian, kelola pesanan, dan kembangkan penghasilan Anda.',
                            imagePath: 'assets/worker.png',
                            accentColor: _workerColor,
                            onTap: () => _openWorkerRegistration(context),
                            semanticLabel: 'Daftar sebagai Mitra Worker',
                          ),
                          if (!googleRegistration) ...[
                            const SizedBox(height: 30),
                            _LoginSection(onLogin: () => _openLogin(context)),
                          ] else ...[
                            const SizedBox(height: 24),
                            const _GoogleRegistrationNote(),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            key: const Key('select-role-back-button'),
            customBorder: const CircleBorder(),
            onTap: onBack,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.arrow_back_rounded,
                color: SelectRolePage._navy,
              ),
            ),
          ),
        ),
        const Spacer(),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE7ECF2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.home_repair_service_rounded,
                    size: 17,
                    color: SelectRolePage._navy,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'HOME WORKERS',
                    style: TextStyle(
                      color: SelectRolePage._navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.googleRegistration});

  final bool googleRegistration;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: SelectRolePage._navy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            googleRegistration ? 'SATU LANGKAH LAGI' : 'MULAI BERGABUNG',
            style: const TextStyle(
              color: SelectRolePage._navy,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          googleRegistration
              ? 'Pilih peran untuk\nakun Anda'
              : 'Apa yang ingin\nAnda lakukan?',
          style: const TextStyle(
            color: Color(0xFF17212B),
            fontSize: 32,
            height: 1.12,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          googleRegistration
              ? 'Pilihan ini menentukan pengalaman dan fitur yang tersedia untuk akun Anda.'
              : 'Pilih peran yang paling sesuai. Kami akan menyiapkan pengalaman terbaik untuk Anda.',
          style: const TextStyle(
            color: Color(0xFF667382),
            fontSize: 15,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    super.key,
    required this.roleLabel,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.accentColor,
    required this.onTap,
    required this.semanticLabel,
  });

  final String roleLabel;
  final String title;
  final String description;
  final String imagePath;
  final Color accentColor;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A374D).withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Ink(
              padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: accentColor.withValues(alpha: 0.16)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, accentColor.withValues(alpha: 0.055)],
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 330;
                  final imageSize = compact ? 68.0 : 82.0;

                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              roleLabel,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              style: const TextStyle(
                                color: Color(0xFF17212B),
                                fontSize: 19,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: const TextStyle(
                                color: Color(0xFF697684),
                                fontSize: 13.5,
                                height: 1.42,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Pilih peran',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: accentColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: imageSize,
                        height: imageSize + 6,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          semanticLabel: '',
                          excludeFromSemantics: true,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginSection extends StatelessWidget {
  const _LoginSection({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('select-role-login-section'),
      children: [
        const Text(
          'Sudah punya akun?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF7A8794),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            key: const Key('select-role-login-button'),
            onPressed: onLogin,
            icon: const Icon(Icons.login_rounded, size: 20),
            label: const Text('Masuk ke akun'),
            style: OutlinedButton.styleFrom(
              foregroundColor: SelectRolePage._navy,
              backgroundColor: Colors.white.withValues(alpha: 0.82),
              side: const BorderSide(color: Color(0xFFCBD5DF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoogleRegistrationNote extends StatelessWidget {
  const _GoogleRegistrationNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('google-registration-note'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SelectRolePage._navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: SelectRolePage._navy,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Peran Worker tetap memerlukan data keahlian dan verifikasi dokumen sebelum akun dapat menerima pekerjaan.',
              style: TextStyle(
                color: Color(0xFF526270),
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundOrb extends StatelessWidget {
  const _BackgroundOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
