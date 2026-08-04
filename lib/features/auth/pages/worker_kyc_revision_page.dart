import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:home_workers_fe/core/api/api_service.dart';
import 'package:home_workers_fe/core/models/kyc_revision_model.dart';
import 'package:home_workers_fe/core/state/auth_provider.dart';
import 'package:home_workers_fe/features/auth/pages/login_page.dart';
import 'package:provider/provider.dart';

class WorkerKycRevisionPage extends StatefulWidget {
  const WorkerKycRevisionPage({super.key, this.apiService});

  final ApiService? apiService;

  @override
  State<WorkerKycRevisionPage> createState() => _WorkerKycRevisionPageState();
}

class _WorkerKycRevisionPageState extends State<WorkerKycRevisionPage> {
  late final ApiService _api;
  final TextEditingController _portfolioController = TextEditingController();
  KycRevisionStatus? _revision;
  File? _ktpFile;
  File? _selfieFile;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  static const _fieldLabels = <String, String>{
    'ktp': 'Foto KTP',
    'selfie': 'Foto selfie',
    'portfolio': 'Link portofolio',
  };

  static const _reasonLabels = <String, String>{
    'BLURRY': 'Foto buram',
    'CROPPED': 'Bagian dokumen terpotong',
    'UNREADABLE': 'Data tidak terbaca',
    'INVALID_DOCUMENT': 'Dokumen tidak valid',
    'DATA_MISMATCH': 'Data tidak sesuai',
    'TOO_DARK': 'Foto terlalu gelap',
    'FACE_NOT_CLEAR': 'Wajah tidak terlihat jelas',
    'FACE_MISMATCH': 'Wajah tidak sesuai identitas',
    'INACCESSIBLE': 'Link tidak dapat dibuka',
    'IRRELEVANT': 'Isi tidak relevan',
    'INCOMPLETE': 'Portofolio belum lengkap',
    'OTHER': 'Alasan lain',
  };

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? ApiService();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _portfolioController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() {
        _loading = false;
        _error = 'Sesi berakhir. Silakan login kembali.';
      });
      return;
    }
    try {
      final revision = await _api.getMyKycRevision(token);
      if (!mounted) return;
      setState(() {
        _revision = revision;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.readableError(
          error,
          action: 'Gagal memuat perbaikan KYC',
        );
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<File?> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    final length = await file.length();
    if (length <= 0 || length > 8 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ukuran foto harus antara 1 byte dan 8 MB.'),
          ),
        );
      }
      return null;
    }
    return file;
  }

  bool _requires(String field) =>
      _revision?.review?.corrections.any((item) => item.field == field) == true;

  void _logoutAndReturnToLogin() {
    // Ambil dependency sebelum logout memicu rebuild/dispose halaman ini.
    final navigator = Navigator.of(context);
    final auth = context.read<AuthProvider>();

    // AuthProvider memutus token dan user secara sinkron. Cleanup Firebase dan
    // secure storage tetap berjalan dengan timeout, sehingga navigasi tidak
    // ikut tertahan oleh operasi native yang lambat.
    unawaited(auth.logout());
    unawaited(
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      ),
    );
  }

  Future<void> _submit() async {
    final revision = _revision;
    final review = revision?.review;
    final token = context.read<AuthProvider>().token;
    if (revision == null || review == null || token == null) return;

    if (_requires('ktp') && _ktpFile == null) {
      setState(() => _error = 'Pilih foto KTP pengganti.');
      return;
    }
    if (_requires('selfie') && _selfieFile == null) {
      setState(() => _error = 'Pilih foto selfie pengganti.');
      return;
    }
    String? portfolio;
    if (_requires('portfolio')) {
      portfolio = _portfolioController.text.trim();
      final uri = Uri.tryParse(portfolio);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        setState(
          () => _error = 'Link portofolio harus berupa URL HTTPS yang valid.',
        );
        return;
      }
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _api.resubmitMyKycRevision(
        token: token,
        reviewVersion: review.version,
        ktpFile: _requires('ktp') ? _ktpFile : null,
        selfieFile: _requires('selfie') ? _selfieFile : null,
        portfolioLink: portfolio,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            'Perbaikan berhasil dikirim. Silakan login kembali setelah Admin menyelesaikan review.',
          ),
        ),
      );
      // Halaman ini merupakan route langsung hasil login. Reset seluruh route
      // agar submit sukses selalu berakhir di halaman login.
      _logoutAndReturnToLogin();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.readableError(
          error,
          action: 'Gagal mengirim perbaikan KYC',
        );
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _fileInput({
    required String field,
    required File? file,
    required VoidCallback onPick,
  }) {
    return OutlinedButton.icon(
      onPressed: _submitting ? null : onPick,
      icon: const Icon(Icons.upload_file_rounded),
      label: Text(
        file == null
            ? 'Pilih ${_fieldLabels[field]}'
            : file.path.split(Platform.pathSeparator).last,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final corrections =
        _revision?.review?.corrections ?? const <KycCorrection>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Perbaikan Data KYC'),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _logoutAndReturnToLogin,
            child: const Text('Logout'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Icon(
                Icons.fact_check_outlined,
                size: 64,
                color: Color(0xFF1A374D),
              ),
              const SizedBox(height: 16),
              const Text(
                'Admin meminta data diperbaiki',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Kirim ulang hanya bagian di bawah ini. Dokumen lama tidak langsung dihapus dan akses dashboard akan terbuka setelah Admin menyetujui hasil review.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF667085), height: 1.5),
              ),
              if (_error != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (corrections.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'Detail perbaikan belum tersedia. Tarik ke bawah untuk memuat ulang.',
                    ),
                  ),
                ),
              ...corrections.map(
                (correction) => Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fieldLabels[correction.field] ?? correction.field,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _reasonLabels[correction.reasonCode] ??
                              correction.reasonCode,
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (correction.note.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            correction.note,
                            style: const TextStyle(color: Color(0xFF667085)),
                          ),
                        ],
                        const SizedBox(height: 14),
                        if (correction.field == 'ktp')
                          _fileInput(
                            field: 'ktp',
                            file: _ktpFile,
                            onPick: () async {
                              final file = await _pickImage();
                              if (file != null && mounted) {
                                setState(() => _ktpFile = file);
                              }
                            },
                          ),
                        if (correction.field == 'selfie')
                          _fileInput(
                            field: 'selfie',
                            file: _selfieFile,
                            onPick: () async {
                              final file = await _pickImage();
                              if (file != null && mounted) {
                                setState(() => _selfieFile = file);
                              }
                            },
                          ),
                        if (correction.field == 'portfolio')
                          TextField(
                            controller: _portfolioController,
                            enabled: !_submitting,
                            keyboardType: TextInputType.url,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              labelText: 'Link portofolio HTTPS',
                              hintText: 'https://...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: corrections.isEmpty || _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  backgroundColor: const Color(0xFF1A374D),
                  foregroundColor: Colors.white,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Kirim Perbaikan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
