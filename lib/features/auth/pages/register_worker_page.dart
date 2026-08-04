import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:home_workers_fe/core/api/api_service.dart';
import 'package:home_workers_fe/core/legal/worker_terms.dart';
import 'package:home_workers_fe/core/models/operational_location_model.dart';
import 'package:home_workers_fe/core/services/google_auth_service.dart';
import 'package:home_workers_fe/core/widgets/google_auth_button.dart';
import 'package:home_workers_fe/features/legal/pages/worker_terms_page.dart';
import 'package:home_workers_fe/features/main_page.dart';
import 'package:home_workers_fe/features/location/pages/operational_location_picker_page.dart';

import 'package:home_workers_fe/core/state/auth_provider.dart' as AppAuth;
import 'package:home_workers_fe/features/auth/pages/email_verification_pending_page.dart';
import 'package:home_workers_fe/features/auth/pages/login_page.dart';
import 'package:home_workers_fe/features/auth/pages/worker_registration_status_page.dart';
import 'package:home_workers_fe/features/auth/policies/worker_registration_submission_policy.dart';
import 'package:home_workers_fe/core/utils/contact_input_policy.dart';

class RegisterWorkerPage extends StatefulWidget {
  const RegisterWorkerPage({
    super.key,
    this.googleRegistration = false,
    this.initialName,
    this.initialEmail,
  });

  final bool googleRegistration;
  final String? initialName;
  final String? initialEmail;

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
  final _contactController = TextEditingController();
  final _linkPortofolioController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _keahlianController = TextEditingController();

  String? _fcmToken;
  File? _ktpFile;
  File? _fotoDiriFile;
  File? _certificateFile;
  OperationalLocation? _operationalLocation;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isAgreed = false;
  bool _hasReviewedTerms = false;
  late bool _isGoogleRegistration;
  final WorkerRegistrationSubmissionGate _submissionGate =
      WorkerRegistrationSubmissionGate();
  final String _registrationRequestId = const Uuid().v4();

  // Colors
  static const Color primaryColor = Color(0xFF1A374D);
  static const Color secondaryColor = Color(0xFFD9D9D9);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color accentColor = Color(0xFF406882);

  @override
  void initState() {
    super.initState();
    _isGoogleRegistration = widget.googleRegistration;
    _namaController.text = widget.initialName ?? '';
    _emailController.text = widget.initialEmail ?? '';
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
      value: 0.2, // step 1 of 5
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
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint('FCM disabled on iOS for now.');
      return;
    }

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
    _contactController.dispose();
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
    _progressCtrl.animateTo((index + 1) / 5);
  }

  void _nextPage() {
    if (_isLoading || _submissionGate.isBusy) return;
    if (!_validateCurrentStep()) return;
    if (_currentPage < 4) {
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
        final contactError = validateIndonesianWhatsApp(
          _contactController.text,
        );
        if (contactError != null) {
          _snack(contactError, error: true);
          return false;
        }
        if (!_isGoogleRegistration && pass.length < 6) {
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
        if (_keahlianController.text
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .isEmpty) {
          _snack('Minimal satu keahlian wajib diisi.', error: true);
          return false;
        }
        return true;
      case 3:
        if (_operationalLocation?.isValid != true) {
          _snack(
            'Tentukan area operasional dan radius layanan terlebih dahulu.',
            error: true,
          );
          return false;
        }
        return true;
      case 4:
        if (!_hasReviewedTerms) {
          _snack(
            'Buka dan baca Syarat & Ketentuan lengkap terlebih dahulu.',
            error: true,
          );
          return false;
        }
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

  Future<void> _pickCertificateFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _certificateFile = File(result.files.single.path!));
    }
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------
  Future<void> _submitRegistration() async {
    if (_isLoading || _submissionGate.isBusy) return;
    if (!_validateCurrentStep()) return;
    if (!_submissionGate.tryStart()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AppAuth.AuthProvider>();

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final nama = _namaController.text.trim();
    final contact = _contactController.text.trim();
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
      if (_isGoogleRegistration) {
        await auth.registerGoogleWorker(
          nama: nama,
          contact: contact,
          keahlian: skills,
          deskripsi: deskripsi,
          ktpFile: _ktpFile!,
          fotoDiriFile: _fotoDiriFile!,
          certificateFile: _certificateFile,
          portfolioLink: link,
          noKtp: noKtp,
          fcmToken: _fcmToken,
          operationalLocation: _operationalLocation!,
          termsVersion: WorkerTerms.version,
          registrationRequestId: _registrationRequestId,
        );
      } else {
        await auth.registerWorker(
          email: email,
          password: password,
          nama: nama,
          contact: contact,
          keahlian: skills,
          deskripsi: deskripsi,
          ktpFile: _ktpFile!,
          fotoDiriFile: _fotoDiriFile!,
          certificateFile: _certificateFile,
          portfolioLink: link,
          noKtp: noKtp,
          fcmToken: _fcmToken,
          operationalLocation: _operationalLocation!,
          termsVersion: WorkerTerms.version,
          registrationRequestId: _registrationRequestId,
        );
      }

      if (!mounted) return;
      _snack(
        _isGoogleRegistration
            ? 'Registrasi Worker berhasil dan sedang diverifikasi.'
            : 'Registrasi worker berhasil! Cek email untuk verifikasi.',
        error: false,
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => _isGoogleRegistration
              ? const WorkerRegistrationStatusPage()
              : EmailVerificationPendingPage(email: email),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _snack(
        ApiService.readableError(e, action: 'Registrasi worker gagal'),
        error: true,
      );
    } finally {
      _submissionGate.finish();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startGoogleWorkerRegistration() async {
    if (_isLoading || !_submissionGate.tryStart()) return;
    final auth = context.read<AppAuth.AuthProvider>();
    setState(() => _isLoading = true);
    try {
      final result = await auth.authenticateWithGoogle(fcmToken: _fcmToken);
      if (!mounted) return;

      if (result.nextAction == AppAuth.GoogleAuthNextAction.openApp) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => MainPage(userRole: auth.user?.role ?? 'CUSTOMER'),
          ),
          (_) => false,
        );
        return;
      }

      if (result.nextAction == AppAuth.GoogleAuthNextAction.selectRole ||
          result.nextAction == AppAuth.GoogleAuthNextAction.completeWorkerKyc) {
        setState(() {
          _isGoogleRegistration = true;
          _namaController.text = result.nama ?? _namaController.text;
          _emailController.text = result.email ?? _emailController.text;
          _passwordController.clear();
        });
        _snack('Akun Google terverifikasi. Lengkapi dokumen KYC Worker.');
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => WorkerRegistrationStatusPage(
            status:
                result.nextAction == AppAuth.GoogleAuthNextAction.showRejection
                ? 'rejected'
                : (result.workerStatus ?? 'pending'),
            rejectionReason: result.rejectionReason,
          ),
        ),
        (_) => false,
      );
    } on GoogleSignInCancelledException {
      // User menutup pemilih akun.
    } catch (e) {
      if (!mounted) return;
      _snack(
        ApiService.readableError(e, action: 'Registrasi Google gagal'),
        error: true,
      );
    } finally {
      _submissionGate.finish();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickOperationalLocation() async {
    final result = await Navigator.of(context).push<OperationalLocation>(
      MaterialPageRoute(
        builder: (_) =>
            OperationalLocationPickerPage(initialValue: _operationalLocation),
      ),
    );
    if (result != null && mounted) {
      setState(() => _operationalLocation = result);
    }
  }

  Future<void> _openWorkerTerms() async {
    final reviewed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const WorkerTermsPage()));
    if (reviewed == true && mounted) {
      setState(() => _hasReviewedTerms = true);
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
    final steps = ['Akun', 'Dokumen', 'Keahlian', 'Lokasi', 'Selesai'];

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
                  _progressCtrl.animateTo((i + 1) / 5);
                  _fadeCtrl
                    ..reset()
                    ..forward();
                },
                children: [
                  _buildStep1CreateAccount(),
                  _buildStep2UploadKtp(),
                  _buildStep3UploadPortfolio(),
                  _buildStep4OperationalArea(),
                  _buildStep5TermsOfService(),
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
                GestureDetector(
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    if (navigator.canPop()) {
                      navigator.pop();
                      return;
                    }
                    if (_isGoogleRegistration) {
                      await context
                          .read<AppAuth.AuthProvider>()
                          .cancelGoogleRegistration();
                    }
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  'Langkah ${_currentPage + 1} dari 5',
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
                  readOnly: _isGoogleRegistration,
                ),
                const SizedBox(height: 16),
                _input(
                  controller: _namaController,
                  label: 'Nama Lengkap',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _input(
                  controller: _contactController,
                  label: 'Nomor WhatsApp',
                  icon: Icons.phone_outlined,
                  kb: TextInputType.phone,
                ),
                if (!_isGoogleRegistration) ...[
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
                if (!_isGoogleRegistration) ...[
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('atau'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GoogleAuthButton(
                    label: 'Daftar Worker dengan Google',
                    isLoading: _isLoading,
                    onPressed: _startGoogleWorkerRegistration,
                  ),
                ],
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
                const SizedBox(height: 16),
                _filePicker(
                  label: 'Upload Sertifikat (Opsional, PDF/JPG/PNG)',
                  file: _certificateFile,
                  onTap: _pickCertificateFile,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep4OperationalArea() {
    final location = _operationalLocation;
    return AnimatedBuilder(
      animation: _fadeAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: Opacity(
            opacity: _fadeAnim.value,
            child: _buildCardWrapper(
              title: 'Area Operasional',
              subtitle: 'Tentukan wilayah tempat Anda menerima pekerjaan',
              icon: Icons.location_on_outlined,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: location == null
                        ? const Color(0xFFF5F8FA)
                        : const Color(0xFFEAF7F3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: location == null
                          ? const Color(0xFFDCE5EA)
                          : const Color(0xFF8ACBBB),
                    ),
                  ),
                  child: location == null
                      ? const Column(
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 48,
                              color: accentColor,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Belum ada area operasional',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Gunakan lokasi saat ini atau cari alamat '
                              'melalui Google Maps.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF6B7D87)),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFFD6F1E9),
                              child: Icon(
                                Icons.check_rounded,
                                color: Color(0xFF0F8B78),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    location.areaLabel,
                                    style: const TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Melayani hingga ${location.serviceRadiusKm} km',
                                    style: const TextStyle(
                                      color: Color(0xFF0F8B78),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickOperationalLocation,
                    icon: Icon(
                      location == null
                          ? Icons.add_location_alt_outlined
                          : Icons.edit_location_alt_outlined,
                    ),
                    label: Text(
                      location == null
                          ? 'Pilih Area Operasional'
                          : 'Ubah Area Operasional',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: Color(0xFF0F8B78),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Koordinat persis disimpan secara privat. Customer '
                        'hanya melihat nama area dan perkiraan jarak.',
                        style: TextStyle(
                          color: Color(0xFF6B7D87),
                          fontSize: 12,
                          height: 1.4,
                        ),
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

  Widget _buildStep5TermsOfService() {
    return AnimatedBuilder(
      animation: _fadeAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: Opacity(
            opacity: _fadeAnim.value,
            child: _buildCardWrapper(
              title: 'Syarat & Ketentuan',
              subtitle: 'Tinjau ketentuan Worker sebelum mendaftar',
              icon: Icons.assignment,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F8FA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDCE5EA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            color: Color(0xFF0F8B78),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              WorkerTerms.title,
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Versi ${WorkerTerms.version} • '
                        'Berlaku ${WorkerTerms.effectiveDate}',
                        style: TextStyle(
                          color: Color(0xFF71838D),
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (final highlight in WorkerTerms.highlights)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: CircleAvatar(
                                  radius: 2.5,
                                  backgroundColor: Color(0xFF0F8B78),
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  highlight,
                                  style: const TextStyle(
                                    color: Color(0xFF40545F),
                                    fontSize: 12.5,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _openWorkerTerms,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: const BorderSide(color: primaryColor),
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            _hasReviewedTerms
                                ? Icons.check_circle_rounded
                                : Icons.menu_book_rounded,
                            color: _hasReviewedTerms
                                ? const Color(0xFF0F8B78)
                                : primaryColor,
                          ),
                          label: Text(
                            _hasReviewedTerms
                                ? 'Sudah Dibaca — Buka Kembali'
                                : 'Baca Syarat & Ketentuan Lengkap',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: _hasReviewedTerms
                        ? const Color(0xFFEAF7F3)
                        : const Color(0xFFF1F3F4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: CheckboxListTile(
                    value: _isAgreed,
                    onChanged: _hasReviewedTerms
                        ? (value) => setState(() => _isAgreed = value ?? false)
                        : null,
                    activeColor: const Color(0xFF0F8B78),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(
                      _hasReviewedTerms
                          ? 'Saya telah membaca, memahami, dan menyetujui '
                                'Syarat & Ketentuan Worker versi ini.'
                          : 'Buka dokumen lengkap terlebih dahulu untuk '
                                'mengaktifkan persetujuan.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: _hasReviewedTerms
                            ? primaryColor
                            : const Color(0xFF7B858B),
                        fontWeight: _hasReviewedTerms
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
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
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: kb,
      maxLines: maxLines,
      readOnly: readOnly,
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
    final isLast = _currentPage == 4;
    final disabled = _isLoading || (isLast && !_isAgreed);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        child: SizedBox(
          width: double.infinity,
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
              minimumSize: const Size.fromHeight(52),
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
            ),
          ),
        ),
      ),
    );
  }
}
