import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/auth_provider.dart';

class RegisterCustomerPage extends StatefulWidget {
  const RegisterCustomerPage({super.key});

  @override
  State<RegisterCustomerPage> createState() => _RegisterCustomerPageState();
}

class _RegisterCustomerPageState extends State<RegisterCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() => _isLoading = true);

    try {
      await authProvider.registerCustomer(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nama: _namaController.text.trim(),
      );

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Registrasi berhasil. Silakan login.'),
        ),
      );

      await Future.delayed(const Duration(seconds: 1));

      // Pindah ke halaman login menggunakan Provider
      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false).showLoginPage();
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Registrasi gagal: ${e.toString().replaceAll("Exception: ", "")}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Daftar Customer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Image.asset('assets/logo_howe.png', height: 180),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _namaController,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Nama wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email wajib diisi';
                        }
                        final emailRegex = RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$',
                        );
                        if (!emailRegex.hasMatch(value)) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _handleRegister(),
                    ),
                    const SizedBox(height: 32),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton.icon(
                              onPressed: _handleRegister,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: Colors.blueGrey,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                elevation: 4,
                              ),
                              icon: const Icon(Icons.person_add_alt_1),
                              label: const Text(
                                'Daftar Sekarang',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
