import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/state/auth_provider.dart';

class EditProfilePage extends StatefulWidget {
  final User user;
  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final ApiService _apiService = ApiService();
  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  // Tambahkan controller lain jika ada field lain

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Isi form dengan data pengguna saat ini
    _nameController = TextEditingController(text: widget.user.nama);
    _contactController = TextEditingController(text: widget.user.contact ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateProfile() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final token = authProvider.token;
      if (token == null) throw Exception('Authentication failed.');

      // Siapkan data yang akan dikirim
      final dataToUpdate = {
        'nama': _nameController.text,
        'contact': _contactController.text,
      };

      await _apiService.updateMyProfile(
        token: token,
        dataToUpdate: dataToUpdate,
      );

      // Refresh data pengguna di AuthProvider
      await authProvider.refreshUserData();

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Profil berhasil diperbarui.'),
        ),
      );

      navigator.pop(); // Kembali ke halaman profil
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Gagal memperbarui profil: ${e.toString().replaceAll("Exception: ", "")}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildFormField('Nama Lengkap', _nameController),
          const SizedBox(height: 24),
          _buildFormField(
            'Nomor Kontak',
            _contactController,
            keyboardType: TextInputType.phone,
          ),
          // Tambahkan field lain di sini (misal: Gender)
          const SizedBox(height: 40),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _handleUpdateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E232C),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Simpan Perubahan',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
