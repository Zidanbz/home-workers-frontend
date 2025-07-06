import 'dart:io';
import 'package:flutter/material.dart';
import 'package:home_workers_fe/core/models/category_model.dart';
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

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            shrinkWrap: true,
            children: categories.map((item) {
              final isSelected = _selectedCategory == item.name;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = item.name;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.shade100
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, size: 30, color: Colors.blueGrey),
                      const SizedBox(height: 8),
                      Text(
                        item.name,
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

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
              const SizedBox(height: 8),
              const Text(
                'Edit Pekerjaan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Foto & Category di 1 baris
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Foto',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (_existingImageUrls.isNotEmpty)
                        _buildThumbnailImage(_existingImageUrls.first)
                      else if (_pickedImages.isNotEmpty)
                        _buildLocalThumbnail(_pickedImages.first),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Kategori',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      InkWell(
                        onTap: _showCategoryPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_selectedCategory ?? 'Pilih Kategori'),
                              const Icon(Icons.keyboard_arrow_down),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _buildFormField(
                'Harga',
                _hargaController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              _buildFormField('Detail', _namaLayananController),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deskripsiController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Detail pekerjaan',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Metode Pembayaran',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: 'Cash & Cashless',
                readOnly: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Text('Foto', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
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
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _handleSaveChanges,
                child: Text(
                  _isEditMode ? 'Simpan Perubahan' : 'Tambah Pekerjaan',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
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

Widget _buildThumbnailImage(String url) => ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: Image.network(url, height: 70, width: 70, fit: BoxFit.cover),
);

Widget _buildLocalThumbnail(File file) => ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: Image.file(file, height: 70, width: 70, fit: BoxFit.cover),
);
