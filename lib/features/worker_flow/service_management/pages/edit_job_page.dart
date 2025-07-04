import 'dart:io';
import 'package:flutter/material.dart';
import 'package:home_workers_fe/core/services/storage_service_page.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/state/auth_provider.dart';

enum ServiceType { fixed, survey }

class CreateEditJobPage extends StatefulWidget {
  final Service? service;
  const CreateEditJobPage({super.key, this.service});

  @override
  State<CreateEditJobPage> createState() => _CreateEditJobPageState();
}

class _CreateEditJobPageState extends State<CreateEditJobPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  // Controllers
  final _namaLayananController = TextEditingController();
  final _hargaController = TextEditingController();
  final _biayaSurveiController = TextEditingController();
  final _deskripsiController = TextEditingController();

  // State
  late bool _isEditMode;
  bool _isLoading = false;
  bool _isUploading = false;
  ServiceType _serviceType = ServiceType.fixed;
  String? _selectedCategory;
  List<File> _pickedImages = [];
  List<String> _existingImageUrls = [];

  final List<String> _categories = [
    'Kebersihan',
    'Perbaikan',
    'Konstruksi',
    'Layanan Elektronik',
  ];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.service != null;
    if (_isEditMode) {
      _namaLayananController.text = widget.service!.namaLayanan;
      _deskripsiController.text = widget.service!.deskripsiLayanan;
      _selectedCategory = widget.service!.category;
      _serviceType = widget.service!.tipeLayanan == 'survey'
          ? ServiceType.survey
          : ServiceType.fixed;
      if (_serviceType == ServiceType.fixed) {
        _hargaController.text = widget.service!.harga.toStringAsFixed(0);
      } else {
        _biayaSurveiController.text = widget.service!.biayaSurvei as String;
      }
      _existingImageUrls = List<String>.from(widget.service!.photoUrls);
    }
  }

  @override
  void dispose() {
    _namaLayananController.dispose();
    _hargaController.dispose();
    _biayaSurveiController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      final token = authProvider.token;
      final userId = authProvider.user?.uid;
      if (token == null || userId == null)
        throw Exception('Authentication failed.');

      List<String> uploadedImageUrls = [];
      String tempServiceId = _isEditMode
          ? widget.service!.id
          : DateTime.now().millisecondsSinceEpoch.toString();
      for (var imageFile in _pickedImages) {
        final downloadUrl = await _storageService.uploadServicePhoto(
          imageFile,
          tempServiceId,
          userId,
        );
        uploadedImageUrls.add(downloadUrl);
      }

      final allImageUrls = [..._existingImageUrls, ...uploadedImageUrls];

      final serviceData = {
        'namaLayanan': _namaLayananController.text,
        'deskripsiLayanan': _deskripsiController.text,
        'category': _selectedCategory,
        'tipeLayanan': _serviceType == ServiceType.fixed ? 'fixed' : 'survey',
        'harga': _serviceType == ServiceType.fixed
            ? (double.tryParse(_hargaController.text) ?? 0)
            : null,
        'biayaSurvei': _serviceType == ServiceType.survey
            ? (double.tryParse(_biayaSurveiController.text) ?? 0)
            : null,
        'photoUrls': allImageUrls,
        'fotoUtamaUrl': allImageUrls.isNotEmpty ? allImageUrls.first : '',
      };

      if (_isEditMode) {
        await _apiService.updateService(
          token: token,
          serviceId: widget.service!.id,
          dataToUpdate: serviceData,
        );
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Layanan berhasil diperbarui.'),
          ),
        );
      } else {
        await _apiService.createService(token: token, serviceData: serviceData);
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Layanan baru berhasil dibuat.'),
          ),
        );
      }

      navigator.pop(true);
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Gagal: ${e.toString().replaceAll("Exception: ", "")}'),
        ),
      );
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  Future<void> _handlePhotoUpload() async {
    final List<XFile> pickedFiles = await ImagePicker().pickMultiImage(
      imageQuality: 70,
    );
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _pickedImages.addAll(
          pickedFiles.map((file) => File(file.path)).toList(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Pekerjaan' : 'Tambah Pekerjaan'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormField('Nama Layanan', _namaLayananController),
              const SizedBox(height: 16),
              const Text(
                'Tipe Layanan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<ServiceType>(
                      title: const Text('Harga Tetap'),
                      value: ServiceType.fixed,
                      groupValue: _serviceType,
                      onChanged: (v) => setState(() => _serviceType = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<ServiceType>(
                      title: const Text('Cek Dulu'),
                      value: ServiceType.survey,
                      groupValue: _serviceType,
                      onChanged: (v) => setState(() => _serviceType = v!),
                    ),
                  ),
                ],
              ),
              if (_serviceType == ServiceType.fixed)
                _buildFormField(
                  'Harga',
                  _hargaController,
                  keyboardType: TextInputType.number,
                )
              else
                _buildFormField(
                  'Biaya Survei (Opsional)',
                  _biayaSurveiController,
                  keyboardType: TextInputType.number,
                ),

              const SizedBox(height: 16),
              const Text(
                'Kategori',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text('Pilih Kategori'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
                validator: (v) => v == null ? 'Kategori wajib dipilih' : null,
              ),

              const SizedBox(height: 16),
              const Text(
                'Deskripsi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextFormField(controller: _deskripsiController, maxLines: 4),

              const SizedBox(height: 24),
              const Text('Foto', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildPhotoGrid(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                onPressed: _handleSaveChanges,
                child: Text(
                  _isEditMode ? 'Simpan Perubahan' : 'Tambah Pekerjaan',
                ),
              ),
      ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
        validator: (v) =>
            (v == null || v.isEmpty) && label != 'Biaya Survei (Opsional)'
            ? '$label wajib diisi'
            : null,
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _pickedImages.length + 1,
      itemBuilder: (context, index) {
        if (index == _pickedImages.length) {
          return InkWell(
            onTap: _isUploading ? null : _handlePhotoUpload,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade400,
                  style: BorderStyle.solid,
                ),
              ),
              child: _isUploading
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add, color: Colors.grey, size: 30),
            ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(_pickedImages[index], fit: BoxFit.cover),
        );
      },
    );
  }
}
