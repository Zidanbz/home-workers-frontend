import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'package:home_workers_fe/core/state/auth_provider.dart' as AppAuth;
import 'package:home_workers_fe/features/auth/pages/email_verification_pending_page.dart';

class RegisterWorkerPage extends StatefulWidget {
  const RegisterWorkerPage({super.key});

  @override
  State<RegisterWorkerPage> createState() => _RegisterWorkerPageState();
}

class _RegisterWorkerPageState extends State<RegisterWorkerPage>
    with TickerProviderStateMixin {
  // Page / anim
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeCtrl;
  late AnimationController _progressCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _progressAnim;

  // Form ctrls
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ktpNumberController = TextEditingController();
  final _linkPortofolioController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _keahlianController = TextEditingController();

  String? _fcmToken;
  File? _ktpFile;
  File? _fotoDiriFile;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isAgreed = false;

  // Colors
  static const Color primaryColor = Color(0xFF1A374D);
  static const Color secondaryColor = Color(0xFFD9D9D9);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color accentColor = Color(0xFF406882);

  @override
  void initState() {
    super.initState();
    _initAnim();
    _initFcm();
  }

  void _initAnim() {
    _fadeCtrl = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressCtrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: 0.25, // step 1 of 4
    );

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _slideAnim = Tween<double>(
      begin: 40,
      end: 0,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));
    _progressAnim = CurvedAnimation(
      parent: _progressCtrl,
      curve: Curves.easeInOut,
    );

    _fadeCtrl.forward();
  }

  Future<void> _initFcm() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      if (mounted) setState(() => _fcmToken = token);
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (mounted) setState(() => _fcmToken = newToken);
        final auth = context.read<AppAuth.AuthProvider>();
        if (auth.isLoggedIn) {
          await auth.syncFcmToken(newToken);
        }
      });
    } catch (e) {
      debugPrint('FCM init error: $e');
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _progressCtrl.dispose();
    _pageController.dispose();
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ktpNumberController.dispose();
    _linkPortofolioController.dispose();
    _deskripsiController.dispose();
    _keahlianController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Step Nav
  // ---------------------------------------------------------------------------
  void _goToPage(int index) {
    if (index == _currentPage) return;
    _fadeCtrl.reset();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _fadeCtrl.forward();
    _progressCtrl.animateTo((index + 1) / 4);
  }

  void _nextPage() {
    if (!_validateCurrentStep()) return;
    if (_currentPage < 3) {
      _goToPage(_currentPage + 1);
    } else {
      _submitRegistration();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) _goToPage(_currentPage - 1);
  }

  bool _validateCurrentStep() {
    switch (_currentPage) {
      case 0:
        final email = _emailController.text.trim();
        final nama = _namaController.text.trim();
        final pass = _passwordController.text;
        final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
        if (email.isEmpty || !emailRegex.hasMatch(email)) {
          _snack('Email tidak valid.', error: true);
          return false;
        }
        if (nama.isEmpty) {
          _snack('Nama wajib diisi.', error: true);
          return false;
        }
        if (pass.length < 6) {
          _snack('Password minimal 6 karakter.', error: true);
          return false;
        }
        return true;
      case 1:
        if (_fotoDiriFile == null) {
          _snack('Foto diri wajib diunggah.', error: true);
          return false;
        }
        if (_ktpFile == null) {
          _snack('Foto KTP wajib diunggah.', error: true);
          return false;
        }
        if (_ktpNumberController.text.trim().isEmpty) {
          _snack('Nomor KTP wajib diisi.', error: true);
          return false;
        }
        return true;
      case 2:
        // optional fields; always valid
        return true;
      case 3:
        if (!_isAgreed) {
          _snack('Harap setujui Syarat & Ketentuan.', error: true);
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  // ---------------------------------------------------------------------------
  // Pickers
  // ---------------------------------------------------------------------------
  Future<void> _pickKtpFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() => _ktpFile = File(result.files.single.path!));
    }
  }

  Future<void> _pickFotoDiriFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() => _fotoDiriFile = File(result.files.single.path!));
    }
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------
  Future<void> _submitRegistration() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AppAuth.AuthProvider>();

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final nama = _namaController.text.trim();
    final noKtp = _ktpNumberController.text.trim();
    final deskripsi = _deskripsiController.text.trim();
    final link = _linkPortofolioController.text.trim().isEmpty
        ? null
        : _linkPortofolioController.text.trim();
    final skills = _keahlianController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    try {
      await auth.registerWorker(
        email: email,
        password: password,
        nama: nama,
        keahlian: skills,
        deskripsi: deskripsi,
        ktpFile: _ktpFile!,
        fotoDiriFile: _fotoDiriFile!,
        portfolioLink: link,
        noKtp: noKtp,
        fcmToken: _fcmToken,
      );

      if (!mounted) return;
      _snack(
        'Registrasi worker berhasil! Cek email untuk verifikasi.',
        error: false,
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => EmailVerificationPendingPage(email: email),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _snack(
        'Registrasi gagal: ${e.toString().replaceAll("Exception: ", "")}',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // UI Helpers
  // ---------------------------------------------------------------------------
  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: error ? Colors.red[600] : primaryColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final steps = ['Akun', 'Dokumen', 'Portofolio', 'Selesai'];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(steps),
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) {
                  setState(() => _currentPage = i);
                  _progressCtrl.animateTo((i + 1) / 4);
                  _fadeCtrl
                    ..reset()
                    ..forward();
                },
                children: [
                  _buildStep1CreateAccount(),
                  _buildStep2UploadKtp(),
                  _buildStep3UploadPortfolio(),
                  _buildStep4TermsOfService(),
                ],
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(List<String> steps) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentPage > 0)
                GestureDetector(
                  onTap: _prevPage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                )
              else
                const SizedBox(width: 36),
              Expanded(
                child: Text(
                  'Langkah ${_currentPage + 1} dari 4',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (index) {
              final isActive = index == _currentPage;
              final isCompleted = index < _currentPage;
              return Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isActive || isCompleted
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: primaryColor,
                                size: 20,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive ? primaryColor : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      steps[index],
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? Colors.white : Colors.white70,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      height: 6,
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: AnimatedBuilder(
        animation: _progressAnim,
        builder: (context, _) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progressAnim.value,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [primaryColor, accentColor]),
                borderRadius: BorderRadius.all(Radius.circular(3)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep1CreateAccount() {
    return AnimatedBuilder(
      animation: _fadeAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: Opacity(
            opacity: _fadeAnim.value,
            child: _buildCardWrapper(
              title: 'Buat Akun Baru',
              subtitle: 'Masukkan informasi dasar Anda',
              icon: Icons.person_add_outlined,
              children: [
                _input(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  kb: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _input(
                  controller: _namaController,
                  label: 'Nama Lengkap',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _input(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscure: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: primaryColor,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep2UploadKtp() {
    return AnimatedBuilder(
      animation: _fadeAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: Opacity(
            opacity: _fadeAnim.value,
            child: _buildCardWrapper(
              title: 'Upload Dokumen',
              subtitle: 'Unggah KTP dan Foto Diri Anda',
              icon: Icons.upload_file,
              children: [
                _filePicker(
                  label: 'Pilih Foto Diri Anda',
                  file: _fotoDiriFile,
                  onTap: _pickFotoDiriFile,
                ),
                const SizedBox(height: 24),
                _filePicker(
                  label: 'Pilih Foto KTP',
                  file: _ktpFile,
                  onTap: _pickKtpFile,
                ),
                const SizedBox(height: 16),
                _input(
                  controller: _ktpNumberController,
                  label: 'Nomor KTP',
                  icon: Icons.credit_card,
                  kb: TextInputType.number,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep3UploadPortfolio() {
    return AnimatedBuilder(
      animation: _fadeAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: Opacity(
            opacity: _fadeAnim.value,
            child: _buildCardWrapper(
              title: 'Data Tambahan',
              subtitle: 'Informasi tambahan untuk profil Anda',
              icon: Icons.info_outline,
              children: [
                _input(
                  controller: _linkPortofolioController,
                  label: 'Link Portofolio (Opsional)',
                  icon: Icons.link,
                  kb: TextInputType.url,
                ),
                const SizedBox(height: 16),
                _input(
                  controller: _keahlianController,
                  label: 'Keahlian (pisahkan dengan koma)',
                  icon: Icons.build,
                ),
                const SizedBox(height: 16),
                _input(
                  controller: _deskripsiController,
                  label: 'Deskripsi Diri',
                  icon: Icons.description,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep4TermsOfService() {
    return AnimatedBuilder(
      animation: _fadeAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: Opacity(
            opacity: _fadeAnim.value,
            child: _buildCardWrapper(
              title: 'Syarat & Ketentuan',
              subtitle: 'Baca dan setujui syarat kami',
              icon: Icons.assignment,
              children: [
                Container(
                  height: 250,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const SingleChildScrollView(
                    child: Text('''
Syarat dan Ketentuan Penggunaan Aplikasi Home Workers

1. Definisi
2. Pendaftaran Akun
3. Penggunaan Layanan
4. Pembayaran dan Pembatalan
5. Kewajiban Worker
6. Kewajiban Customer
7. Privasi dan Keamanan

Dengan melanjutkan, Anda menyatakan telah membaca dan menyetujui semua Syarat & Ketentuan di atas.
''', style: TextStyle(fontSize: 14, height: 1.5)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _isAgreed,
                      onChanged: (v) => setState(() => _isAgreed = v ?? false),
                      activeColor: primaryColor,
                    ),
                    const Expanded(
                      child: Text(
                        'Saya telah membaca dan menyetujui Syarat & Ketentuan.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Reusable input
  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType kb = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: kb,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: secondaryColor.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _filePicker({
    required String label,
    required File? file,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: secondaryColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor),
        ),
        child: file != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : Center(
                child: Text(label, style: const TextStyle(color: primaryColor)),
              ),
      ),
    );
  }

  Widget _buildCardWrapper({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primaryColor, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final isLast = _currentPage == 3;
    final disabled = _isLoading || (isLast && !_isAgreed);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ElevatedButton.icon(
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(isLast ? Icons.check : Icons.arrow_forward),
        onPressed: disabled ? null : _nextPage,
        label: Text(isLast ? 'Daftar' : 'Lanjut'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }
}
