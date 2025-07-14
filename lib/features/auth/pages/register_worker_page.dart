import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:home_workers_fe/core/api/api_service.dart';
import 'package:home_workers_fe/features/auth/pages/login_page.dart';

class RegisterWorkerPage extends StatefulWidget {
  const RegisterWorkerPage({super.key});

  @override
  State<RegisterWorkerPage> createState() => _RegisterWorkerPageState();
}

class _RegisterWorkerPageState extends State<RegisterWorkerPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ktpNumberController = TextEditingController();
  final _linkPortofolioController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _keahlianController = TextEditingController();

  File? _ktpFile;
  File? _fotoDiriFile;
  bool _isLoading = false;

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitRegistration();
    }
  }

  Future<void> _pickKtpFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _ktpFile = File(result.files.single.path!);
      });
    }
  }

    Future<void> _pickFotoDiriFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _fotoDiriFile = File(result.files.single.path!);
      });
    }
  }

 Future<void> _submitRegistration() async {
    // Perbarui validasi
    if (_ktpFile == null || _fotoDiriFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan unggah file KTP dan Foto Diri')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final keahlianList = _keahlianController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    try {
      await ApiService().registerWorker(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nama: _namaController.text.trim(),
        noKtp: _ktpNumberController.text.trim(),
        deskripsi: _deskripsiController.text.trim(),
        keahlian: keahlianList,
        ktpFile: _ktpFile!,
        fotoDiriFile: _fotoDiriFile!, // <-- 3. KIRIM FOTO DIRI
        portfolioLink: _linkPortofolioController.text.trim(),
      );

      if (mounted) {
        await _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal registrasi: $e')));
        print(e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showSuccessDialog() async {
    final navigator = Navigator.of(context);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.mark_email_read_outlined,
                  color: Colors.green,
                  size: 70,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Registrasi Berhasil!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Akun Anda telah dibuat dan sedang dalam proses peninjauan oleh Admin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Oke, Saya Mengerti',
                      style: TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      navigator.pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = ['Akun', 'KTP', 'Portofolio', 'Syarat'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Langkah ${_currentPage + 1} dari 4'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(steps.length, (index) {
                final isActive = index == _currentPage;
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isActive
                          ? Colors.blueGrey
                          : Colors.grey[300],
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[index],
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? Colors.blueGrey : Colors.black54,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          const Divider(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildStep1CreateAccount(),
                _buildStep2UploadKtp(),
                _buildStep3UploadPortfolio(),
                _buildStep4TermsOfService(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
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
              : Icon(_currentPage < 3 ? Icons.arrow_forward : Icons.check),
          onPressed: _isLoading ? null : _nextPage,
          label: Text(_currentPage < 3 ? 'Lanjut' : 'Daftar'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.blueGrey,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildStep1CreateAccount() {
    return _buildCardWrapper(
      title: 'Buat Akun Baru',
      children: [
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _namaController,
          decoration: const InputDecoration(
            labelText: 'Nama Lengkap',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
      ],
    );
  }

    Widget _buildStep2UploadKtp() {
    return _buildCardWrapper(
      title: 'Upload Dokumen',
      children: [
        // Picker untuk Foto Diri
        const Text('Pilih Foto Diri Anda', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickFotoDiriFile,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
            ),
            child: _fotoDiriFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _fotoDiriFile!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : const Center(child: Text('Klik untuk pilih Foto Diri')),
          ),
        ),
        const SizedBox(height: 24),

        // Picker untuk KTP
        const Text('Pilih Foto KTP', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickKtpFile,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
            ),
            child: _ktpFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _ktpFile!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : const Center(child: Text('Klik untuk pilih file KTP')),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _ktpNumberController,
          decoration: const InputDecoration(
            labelText: 'Nomor KTP',
            prefixIcon: Icon(Icons.credit_card),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  // Ganti fungsi lama Anda dengan yang ini

  Widget _buildStep3UploadPortfolio() {
    return _buildCardWrapper(
      title: 'Data Tambahan',
      children: [
        // Kolom untuk Link Portofolio
        TextFormField(
          controller: _linkPortofolioController,
          decoration: const InputDecoration(
            labelText: 'Link Portofolio (Opsional)',
            prefixIcon: Icon(Icons.link),
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),

        // Kolom untuk Keahlian (YANG HILANG)
        TextFormField(
          controller: _keahlianController,
          decoration: const InputDecoration(
            labelText: 'Keahlian (pisahkan dengan koma)',
            prefixIcon: Icon(Icons.build),
            hintText: 'Contoh: tukang listrik, ahli pipa, dll.',
          ),
        ),
        const SizedBox(height: 16),

        // Kolom untuk Deskripsi Diri (YANG HILANG)
        TextFormField(
          controller: _deskripsiController,
          decoration: const InputDecoration(
            labelText: 'Deskripsi Diri',
            prefixIcon: Icon(Icons.description),
            hintText: 'Jelaskan pengalaman dan keunggulan Anda.',
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildStep4TermsOfService() {
    return _buildCardWrapper(
      title: 'Syarat & Ketentuan',
      children: const [
        Text(
          'Dengan mendaftar, Anda menyetujui syarat dan ketentuan layanan kami.',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 12),
        Text('1. Anda harus memberikan data yang valid.'),
        Text('2. Anda tidak boleh menyalahgunakan platform ini.'),
        Text('3. Data Anda akan dilindungi dengan ketentuan privasi.'),
      ],
    );
  }

  Widget _buildCardWrapper({
    required String title,
    required List<Widget> children,
  }) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        ...children,
      ],
    );
  }
}
