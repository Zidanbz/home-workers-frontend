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
  CategoryItem("Kebersihan", Icons.cleaning_services, Colors.blue),
  CategoryItem("Perbaikan", Icons.handyman, Colors.orange),
  CategoryItem("Instalasi", Icons.download, Colors.green),
  CategoryItem("Renovasi", Icons.home_repair_service, Colors.purple),
  CategoryItem("Elektronik", Icons.electrical_services, Colors.amber),
  CategoryItem("Otomotif", Icons.directions_car, Colors.red),
  CategoryItem("Perawatan Taman", Icons.local_florist, Colors.teal),
  CategoryItem("Pembangunan", Icons.construction, Colors.brown),
  CategoryItem("Gadget", Icons.phone_android, Colors.indigo),
];

class CategoryItem {
  final String name;
  final IconData icon;
  final Color color;

  CategoryItem(this.name, this.icon, this.color);
}

class CreateEditJobPage extends StatefulWidget {
  final Service? service;
  const CreateEditJobPage({super.key, this.service});

  @override
  State<CreateEditJobPage> createState() => _CreateEditJobPageState();
}

enum PaymentMethod { cashless, cash }

PaymentMethod _selectedPaymentMethod = PaymentMethod.cashless;

class _CreateEditJobPageState extends State<CreateEditJobPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  final _namaLayananController = TextEditingController();
  final _hargaController = TextEditingController();
  final _biayaSurveiController = TextEditingController();
  final _deskripsiController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

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
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _namaLayananController.dispose();
    _hargaController.dispose();
    _biayaSurveiController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  String format24(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildAvailabilitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.schedule, color: Colors.indigo.shade700),
              ),
              const SizedBox(width: 12),
              Text(
                'Jadwal Ketersediaan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._hari.map((hari) {
            final selectedSlots = _selectedAvailability[hari] ?? {};
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hari,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _jamPilihan.map((slot) {
                      final isSelected = selectedSlots.contains(slot);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedAvailability[hari]!.remove(slot);
                              } else {
                                _selectedAvailability[hari]!.add(slot);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      colors: [
                                        Colors.indigo.shade300,
                                        Colors.indigo.shade600,
                                      ],
                                    )
                                  : null,
                              color: isSelected ? null : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.indigo
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              slot,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade700,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.category, color: Colors.indigo.shade700),
                    const SizedBox(width: 12),
                    Text(
                      'Pilih Kategori',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.all(20),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: categories.map((item) {
                    final isSelected = _selectedCategory == item.name;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = item.name;
                        });
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    item.color.withOpacity(0.8),
                                    item.color,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.grey.shade100,
                                    Colors.grey.shade200,
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? item.color.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item.icon,
                              size: 40,
                              color: isSelected ? Colors.white : item.color,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
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

      List<String> paymentMethods;
      if (_serviceType == ServiceType.fixed) {
        // Untuk layanan harga tetap, UI mengindikasikan 'Cashless' wajib
        paymentMethods = ['Cashless'];
      } else {
        // Untuk layanan berbasis survei, gunakan pilihan pengguna
        // Petakan enum ke nilai string yang diharapkan oleh backend
        if (_selectedPaymentMethod == PaymentMethod.cashless) {
          paymentMethods = ['Cashless'];
        } else {
          // PaymentMethod.cash
          paymentMethods = ['Cek Dulu'];
        }
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
        'metodePembayaran': paymentMethods,
      };

      if (_isEditMode) {
        await _apiService.updateService(
          token: token,
          serviceId: widget.service!.id,
          dataToUpdate: serviceData,
        );
        scaffoldMessenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade600,
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Layanan berhasil diperbarui!'),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        await _apiService.createService(token: token, serviceData: serviceData);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade600,
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Layanan baru berhasil dibuat!'),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      navigator.pop(true);
    } catch (e) {
      print("==== KESALAHAN UPLOAD FOTO ====");
      print(e); // Baris ini akan menunjukkan error spesifiknya
      print("================================");
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade600,
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gagal: ${e.toString().replaceAll("Exception: ", "")}',
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          behavior: SnackBarBehavior.floating,
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.indigo),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? 'Edit Layanan' : 'Buat Layanan',
          style: const TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                top: 100,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.indigo.shade600,
                          Colors.indigo.shade800,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _isEditMode ? Icons.edit : Icons.add_business,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isEditMode
                                        ? 'Edit Layanan'
                                        : 'Buat Layanan Baru',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isEditMode
                                        ? 'Perbarui informasi layanan Anda'
                                        : 'Tambahkan layanan baru untuk pelanggan',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Main Image Section
                  _buildModernSection(
                    'Foto Utama',
                    Icons.photo_camera,
                    Colors.blue,
                    Row(
                      children: [
                        if (_existingImageUrls.isNotEmpty)
                          _buildModernThumbnail(_existingImageUrls.first)
                        else if (_pickedImages.isNotEmpty)
                          _buildModernLocalThumbnail(_pickedImages.first)
                        else
                          _buildModernImagePlaceholder(),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _existingImageUrls.isNotEmpty ||
                                    _pickedImages.isNotEmpty
                                ? 'Foto utama sudah dipilih'
                                : 'Pilih foto utama untuk layanan Anda',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Category Section
                  _buildModernSection(
                    'Kategori',
                    Icons.category,
                    Colors.orange,
                    GestureDetector(
                      onTap: _showCategoryPicker,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade50,
                              Colors.orange.shade100,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _selectedCategory != null
                                    ? categories
                                          .firstWhere(
                                            (cat) =>
                                                cat.name == _selectedCategory,
                                          )
                                          .icon
                                    : Icons.category,
                                color: Colors.orange.shade700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedCategory ?? 'Pilih Kategori',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.orange.shade700,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Service Type Section
                  _buildModernSection(
                    'Tipe Layanan',
                    Icons.settings,
                    Colors.purple,
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernServiceTypeCard(
                                ServiceType.fixed,
                                'Harga Tetap',
                                Icons.attach_money,
                                Colors.green,
                                'Harga sudah pasti',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildModernServiceTypeCard(
                                ServiceType.survey,
                                'Butuh Survei',
                                Icons.assignment,
                                Colors.blue,
                                'Survei terlebih dahulu',
                              ),
                            ),
                          ],
                        ),
                        if (_serviceType == ServiceType.survey)
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info,
                                  color: Colors.blue.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Customer hanya membayar biaya survei. Biaya lainnya ditentukan setelah survei.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Payment Method Section
                  _buildModernSection(
                    'Metode Pembayaran',
                    Icons.payment,
                    Colors.teal,
                    _serviceType == ServiceType.survey
                        ? Row(
                            children: [
                              Expanded(
                                child: _buildModernPaymentCard(
                                  PaymentMethod.cashless,
                                  'Cashless',
                                  Icons.credit_card,
                                  Colors.indigo,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildModernPaymentCard(
                                  PaymentMethod.cash,
                                  'Cek Dulu',
                                  Icons.visibility,
                                  Colors.orange,
                                ),
                              ),
                            ],
                          )
                        : Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.indigo.shade50,
                                  Colors.indigo.shade100,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.indigo.shade200),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.credit_card,
                                    color: Colors.indigo.shade700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Cashless (wajib)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.indigo.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),

                  const SizedBox(height: 20),

                  // Price/Survey Cost Field
                  _buildModernFormField(
                    _serviceType == ServiceType.fixed
                        ? 'Harga'
                        : 'Biaya Survei',
                    _serviceType == ServiceType.fixed
                        ? _hargaController
                        : _biayaSurveiController,
                    icon: _serviceType == ServiceType.fixed
                        ? Icons.attach_money
                        : Icons.assignment,
                    keyboardType: TextInputType.number,
                    color: Colors.green,
                  ),

                  const SizedBox(height: 16),

                  // Service Name Field
                  _buildModernFormField(
                    'Nama Layanan',
                    _namaLayananController,
                    icon: Icons.work,
                    color: Colors.blue,
                  ),

                  const SizedBox(height: 16),

                  // Description Field
                  _buildModernFormField(
                    'Deskripsi',
                    _deskripsiController,
                    icon: Icons.description,
                    isTextArea: true,
                    color: Colors.purple,
                  ),

                  const SizedBox(height: 20),

                  // Additional Photos Section
                  _buildModernSection(
                    'Foto Tambahan',
                    Icons.photo_library,
                    Colors.pink,
                    _buildModernPhotoGrid(),
                  ),

                  const SizedBox(height: 20),

                  // Availability Section
                  _buildAvailabilitySection(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.indigo.shade600,
                  ),
                ),
              )
            : ElevatedButton(
                onPressed: _handleSaveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                  shadowColor: Colors.indigo.withOpacity(0.3),
                ),
                child: Container(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isEditMode ? Icons.save : Icons.add, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isEditMode ? 'Simpan Perubahan' : 'Tambah Layanan',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildModernSection(
    String title,
    IconData icon,
    Color color,
    Widget content,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildModernFormField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    bool isTextArea = false,
    TextInputType? keyboardType,
    Color color = Colors.blue,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: isTextArea ? 4 : 1,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: color),
          prefixIcon: icon != null
              ? Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: color, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.red.shade300),
          ),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? '$label wajib diisi' : null,
      ),
    );
  }

  Widget _buildModernServiceTypeCard(
    ServiceType type,
    String label,
    IconData icon,
    Color color,
    String description,
  ) {
    final isSelected = _serviceType == type;
    return GestureDetector(
      onTap: () => setState(() => _serviceType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color.withOpacity(0.8), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Colors.grey.shade100, Colors.grey.shade200],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: isSelected ? Colors.white : color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? Colors.white : Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white70 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernPaymentCard(
    PaymentMethod type,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedPaymentMethod == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color.withOpacity(0.8), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Colors.grey.shade100, Colors.grey.shade200],
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: isSelected ? Colors.white : color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? Colors.white : Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernImagePlaceholder() {
    return Container(
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade200, Colors.grey.shade300],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade400,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            color: Colors.grey.shade600,
            size: 30,
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih Foto',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPhotoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _pickedImages.length + 1,
      itemBuilder: (context, index) {
        if (index == _pickedImages.length) {
          return GestureDetector(
            onTap: _isUploading ? null : _handlePhotoUpload,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.blue.shade200],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade300, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isUploading
                  ? Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue.shade600,
                        ),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.blue.shade600, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          'Tambah',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        }
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _pickedImages[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _pickedImages.removeAt(index);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

Widget _buildModernThumbnail(String url) {
  return Container(
    height: 80,
    width: 80,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey.shade200,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade200,
          child: Icon(Icons.error, color: Colors.grey.shade600),
        ),
      ),
    ),
  );
}

Widget _buildModernLocalThumbnail(File file) {
  return Container(
    height: 80,
    width: 80,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(file, fit: BoxFit.cover),
    ),
  );
}
