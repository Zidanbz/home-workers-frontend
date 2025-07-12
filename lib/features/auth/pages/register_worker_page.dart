import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

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

  File? _ktpFile;

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

  Future<void> _submitRegistration() async {
    // TODO: Lakukan validasi dan kirim data ke backend
    print('Email: ${_emailController.text}');
    print('Nama: ${_namaController.text}');
    print('Password: ${_passwordController.text}');
    print('KTP No: ${_ktpNumberController.text}');
    print('Portofolio: ${_linkPortofolioController.text}');
    print('File KTP: ${_ktpFile?.path}');
  }

  @override
  Widget build(BuildContext context) {
    final steps = ['Akun', 'KTP', 'Portofolio', 'Syarat'];
    final theme = Theme.of(context);

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
          icon: Icon(_currentPage < 3 ? Icons.arrow_forward : Icons.check),
          onPressed: _nextPage,
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
      title: 'Upload KTP Anda',
      children: [
        const Text('Pilih Foto KTP', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickKtpFile,
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey),
            ),
            child: Center(
              child: _ktpFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_ktpFile!, fit: BoxFit.cover),
                    )
                  : const Text('Klik untuk pilih file KTP'),
            ),
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

  Widget _buildStep3UploadPortfolio() {
    return _buildCardWrapper(
      title: 'Link Portofolio (Opsional)',
      children: [
        TextFormField(
          controller: _linkPortofolioController,
          decoration: const InputDecoration(
            hintText: 'https://portfolio.example.com',
            prefixIcon: Icon(Icons.link),
          ),
          keyboardType: TextInputType.url,
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
