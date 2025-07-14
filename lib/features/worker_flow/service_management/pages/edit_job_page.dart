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

final List<CategoryItem> categories = [
  CategoryItem("Kebersihan", Icons.cleaning_services),
  CategoryItem("Perbaikan", Icons.handyman),
  CategoryItem("Instalasi", Icons.download),
  CategoryItem("Renovasi", Icons.home_repair_service),
  CategoryItem("Elektronik", Icons.electrical_services),
  CategoryItem("Otomotif", Icons.directions_car),
  CategoryItem("Perawatan Taman", Icons.local_florist),
  CategoryItem("Pembangunan", Icons.construction),
  CategoryItem("Gadget", Icons.phone_android),
];

class CategoryItem {
  final String name;
  final IconData icon;

  CategoryItem(this.name, this.icon);
}

class CreateEditJobPage extends StatefulWidget {
  final Service? service;
  const CreateEditJobPage({super.key, this.service});

  @override
  State<CreateEditJobPage> createState() => _CreateEditJobPageState();
}

enum PaymentMethod { cashless, cash }

PaymentMethod _selectedPaymentMethod = PaymentMethod.cashless;

class _CreateEditJobPageState extends State<CreateEditJobPage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  final _namaLayananController = TextEditingController();
  final _hargaController = TextEditingController();
  final _biayaSurveiController = TextEditingController();
  final _deskripsiController = TextEditingController();

  late bool _isEditMode;
  bool _isLoading = false;
  bool _isUploading = false;
  ServiceType _serviceType = ServiceType.fixed;
  String? _selectedCategory;
  List<File> _pickedImages = [];
  List<String> _existingImageUrls = [];

  final List<String> _jamPilihan = [
    'Pagi 09.00 - 11.00',
    'Siang 12.00 - 15.00',
    'Sore 16.00 - 18.00',
  ];

  Map<String, Set<String>> _selectedAvailability = {
    'Senin': {},
    'Selasa': {},
    'Rabu': {},
    'Kamis': {},
    'Jumat': {},
    'Sabtu': {},
    'Minggu': {},
  };

  final List<String> _hari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  final List<String> _categories = [
    'Kebersihan',
    'Perbaikan',
    'Konstruksi',
    'Layanan Elektronik',
  ];

  String format24(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Jam berapa Anda ingin layanan dimulai?'),
        const SizedBox(height: 8),
        ..._hari.map((hari) {
          final selectedSlots = _selectedAvailability[hari] ?? {};

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hari, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _jamPilihan.map((slot) {
                  final isSelected = selectedSlots.contains(slot);
                  return ChoiceChip(
                    label: Text(slot),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        if (isSelected) {
                          _selectedAvailability[hari]!.remove(slot);
                        } else {
                          _selectedAvailability[hari]!.add(slot);
                        }
                      });
                    },
                    selectedColor: Colors.indigo.shade100,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.indigo : Colors.black,
                    ),
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ],
    );
  }

  Future<List<TimeOfDay>?> showTimeRangePicker(String hari) async {
    TimeOfDay? start = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 9, minute: 0),
    );
    if (start == null) return null;

    TimeOfDay? end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: start.hour + 1, minute: 0),
    );
    if (end == null) return null;

    return [start, end];
  }

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
        _biayaSurveiController.text =
            widget.service!.biayaSurvei?.toString() ?? '';
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
        'availability': _selectedAvailability.map(
          (day, slots) => MapEntry(day, slots.toList()),
        ),
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
      if (mounted) setState(() => _isLoading = false);
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Layanan' : 'Buat Layanan'),
        backgroundColor: Colors.indigo,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditMode
                    ? 'Perbarui Informasi Layanan Anda'
                    : 'Buat Layanan Baru',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('Foto Utama'),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_existingImageUrls.isNotEmpty)
                    _buildThumbnailImage(_existingImageUrls.first)
                  else if (_pickedImages.isNotEmpty)
                    _buildLocalThumbnail(_pickedImages.first)
                  else
                    _buildImagePlaceholder(),
                ],
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Kategori'),
              InkWell(
                onTap: _showCategoryPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.indigo.shade100),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategory ?? 'Pilih Kategori',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Icon(Icons.keyboard_arrow_down),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Tipe Layanan'),
              Row(
                children: [
                  Expanded(
                    child: _buildCustomRadio(ServiceType.fixed, 'Harga Tetap'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCustomRadio(
                      ServiceType.survey,
                      'Butuh Survei',
                    ),
                  ),
                ],
              ),
              if (_serviceType == ServiceType.survey)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Customer hanya membayar biaya survei. Biaya lainnya ditentukan setelah survei.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              if (_serviceType == ServiceType.survey)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildSectionTitle('Metode Pembayaran'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPaymentRadio(
                            PaymentMethod.cashless,
                            'Cashless',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildPaymentRadio(
                            PaymentMethod.cash,
                            'Cek Dulu',
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildSectionTitle('Metode Pembayaran'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        border: Border.all(color: Colors.indigo),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.payment, color: Colors.indigo),
                          SizedBox(width: 8),
                          Text(
                            'Cashless (wajib)',
                            style: TextStyle(color: Colors.indigo),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              _serviceType == ServiceType.fixed
                  ? _buildFormField(
                      'Harga',
                      _hargaController,
                      icon: Icons.price_change,
                    )
                  : _buildFormField(
                      'Biaya Survei',
                      _biayaSurveiController,
                      icon: Icons.assignment,
                    ),

              _buildFormField(
                'Nama Layanan',
                _namaLayananController,
                icon: Icons.home_repair_service,
              ),
              _buildFormField(
                'Deskripsi',
                _deskripsiController,
                icon: Icons.description,
                isTextArea: true,
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Foto Tambahan'),
              _buildPhotoGrid(),
              const SizedBox(height: 80),
              _buildAvailabilitySection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton.icon(
                icon: Icon(_isEditMode ? Icons.save : Icons.add),
                label: Text(
                  _isEditMode ? 'Simpan Perubahan' : 'Tambah Pekerjaan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                ),
                onPressed: _handleSaveChanges,
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildFormField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    bool isTextArea = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: isTextArea ? 4 : 1,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? '$label wajib diisi' : null,
      ),
    );
  }

  Widget _buildCustomRadio(ServiceType type, String label) {
    return GestureDetector(
      onTap: () => setState(() => _serviceType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: _serviceType == type ? Colors.indigo.shade50 : Colors.white,
          border: Border.all(
            color: _serviceType == type ? Colors.indigo : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _serviceType == type
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: _serviceType == type ? Colors.indigo : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: _serviceType == type ? Colors.indigo : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRadio(PaymentMethod type, String label) {
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: _selectedPaymentMethod == type
              ? Colors.indigo.shade50
              : Colors.white,
          border: Border.all(
            color: _selectedPaymentMethod == type
                ? Colors.indigo
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedPaymentMethod == type
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: _selectedPaymentMethod == type
                  ? Colors.indigo
                  : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: _selectedPaymentMethod == type
                    ? Colors.indigo
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() => Container(
    height: 70,
    width: 70,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.image, color: Colors.grey),
  );

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
                border: Border.all(color: Colors.grey.shade400),
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
