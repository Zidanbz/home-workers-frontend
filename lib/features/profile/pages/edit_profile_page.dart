import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_service.dart';
import '../../../core/models/user_model.dart';
import '../../../core/state/auth_provider.dart';
import '../../../core/utils/contact_input_policy.dart';

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
  late final TextEditingController _skillsController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _portfolioController;

  bool _isLoading = false;
  bool _isInitialLoading = false;
  File? _certificateFile;
  File? _portfolioFile;
  String? _existingCertificateName;
  String? _existingPortfolioName;

  bool get _isWorker => widget.user.role.toLowerCase() == 'worker';

  @override
  void initState() {
    super.initState();
    // Isi form dengan data pengguna saat ini
    _nameController = TextEditingController(text: widget.user.nama);
    _contactController = TextEditingController(text: widget.user.contact ?? '');
    _skillsController = TextEditingController();
    _descriptionController = TextEditingController();
    _portfolioController = TextEditingController();
    if (_isWorker) _loadWorkerProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _skillsController.dispose();
    _descriptionController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkerProfile() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() => _isInitialLoading = true);
    try {
      final data = await _apiService.getMyWorkerProfile(token);
      if (!mounted) return;
      final rawSkills = data['keahlian'];
      _skillsController.text = rawSkills is List
          ? rawSkills.map((item) => item.toString()).join(', ')
          : '';
      _descriptionController.text = data['deskripsi']?.toString() ?? '';
      _portfolioController.text = data['portfolioLink']?.toString() ?? '';
      setState(() {
        _existingCertificateName = data['certificateFileName']?.toString();
        _existingPortfolioName = data['portfolioFileName']?.toString();
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              ApiService.readableError(
                error,
                action: 'Gagal memuat profil Worker',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _pickCertificate() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result?.files.single.path != null && mounted) {
      setState(() => _certificateFile = File(result!.files.single.path!));
    }
  }

  Future<void> _pickPortfolio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result?.files.single.path != null && mounted) {
      setState(() => _portfolioFile = File(result!.files.single.path!));
    }
  }

  Future<void> _handleUpdateProfile() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final contactError = validateIndonesianWhatsApp(_contactController.text);
    if (contactError != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text(contactError)),
      );
      return;
    }
    if (_nameController.text.trim().length < 2) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Nama minimal 2 karakter.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final token = authProvider.token;
      if (token == null) throw Exception('Authentication failed.');

      final dataToUpdate = <String, dynamic>{
        'nama': _nameController.text.trim(),
        'contact': _contactController.text.trim(),
      };

      if (_isWorker) {
        final skills = _skillsController.text
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
        if (skills.isEmpty) {
          throw Exception('Minimal satu keahlian wajib diisi.');
        }
        dataToUpdate.addAll({
          'keahlian': skills,
          'deskripsi': _descriptionController.text.trim(),
          'portfolioLink': _portfolioController.text.trim(),
        });
        await _apiService.updateMyWorkerProfile(
          token: token,
          dataToUpdate: dataToUpdate,
          certificateFile: _certificateFile,
          portfolioFile: _portfolioFile,
        );
      } else {
        await _apiService.updateMyProfile(
          token: token,
          dataToUpdate: dataToUpdate,
        );
      }

      authProvider.updateLocalProfile(
        nama: _nameController.text.trim(),
        contact: _contactController.text.trim(),
      );

      // Refresh data pengguna di AuthProvider
      // await authProvider.refreshUserData();

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
            ApiService.readableError(e, action: 'Gagal memperbarui profil'),
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
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                _buildFormField('Nama Lengkap', _nameController),
                const SizedBox(height: 24),
                _buildFormField(
                  'Nomor WhatsApp',
                  _contactController,
                  keyboardType: TextInputType.phone,
                ),
                if (_isWorker) ...[
                  const SizedBox(height: 24),
                  _buildFormField(
                    'Keahlian (pisahkan dengan koma)',
                    _skillsController,
                  ),
                  const SizedBox(height: 24),
                  _buildFormField(
                    'Deskripsi Diri',
                    _descriptionController,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  _buildFormField(
                    'Link Portofolio (HTTPS)',
                    _portfolioController,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    key: const ValueKey('worker-portfolio-picker'),
                    onPressed: _pickPortfolio,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      _portfolioFile?.path.split(Platform.pathSeparator).last ??
                          _existingPortfolioName ??
                          'Upload Portofolio PDF/JPG/PNG (opsional)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Sertifikat (Opsional)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const ValueKey('worker-certificate-picker'),
                    onPressed: _pickCertificate,
                    icon: const Icon(Icons.workspace_premium_outlined),
                    label: Text(
                      _certificateFile?.path
                              .split(Platform.pathSeparator)
                              .last ??
                          _existingCertificateName ??
                          'Pilih PDF/JPG/PNG (maks. 8 MB)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sertifikat baru akan berstatus belum diverifikasi sampai ditinjau Admin.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
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
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
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
