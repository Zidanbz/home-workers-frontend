import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_workers_fe/core/models/service_catalog_model.dart';
import 'package:home_workers_fe/core/services/storage_service_page.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/state/auth_provider.dart';
import '../../profile/pages/worker_operational_area_page.dart';
import '../utils/service_availability_form.dart';

enum ServiceType { fixed, survey }

class CreateEditJobPage extends StatefulWidget {
  final Service? service;
  const CreateEditJobPage({super.key, this.service});

  @override
  State<CreateEditJobPage> createState() => _CreateEditJobPageState();
}

enum PaymentMethod { cashless, cash }

const int _thumbnailCacheSize = 512;

class _CreateEditJobPageState extends State<CreateEditJobPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

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
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cashless;
  ServiceCatalog? _catalog;
  String? _selectedCatalogGroupId;
  String? _selectedCatalogAssetId;
  String? _selectedCatalogItemId;
  bool _isLoadingCatalog = true;
  String? _catalogError;
  List<File> _pickedImages = [];
  List<String> _existingImageUrls = [];
  String? _operationalAreaLabel;
  int? _serviceRadiusKm;
  bool _isLoadingOperationalArea = true;

  final List<String> _jamPilihan = [
    'Pagi 09.00 - 11.00',
    'Siang 12.00 - 15.00',
    'Sore 16.00 - 18.00',
  ];

  Map<String, Set<String>> _selectedAvailability =
      buildServiceAvailabilitySelection(const []);

  final List<String> _hari = serviceAvailabilityDays;

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
      _deskripsiController.text = widget.service!.deskripsiLayanan;
      _selectedCatalogGroupId = widget.service!.catalogGroupId;
      _selectedCatalogAssetId = widget.service!.catalogAssetId;
      _selectedCatalogItemId = widget.service!.catalogItemId;
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
      _selectedAvailability = buildServiceAvailabilitySelection(
        widget.service!.availability,
      );
      if (_serviceType == ServiceType.survey) {
        _selectedPaymentMethod =
            widget.service!.metodePembayaran.any(
              (method) => method.toString().toLowerCase() == 'cek dulu',
            )
            ? PaymentMethod.cash
            : PaymentMethod.cashless;
      }
    }
    _animationController.forward();
    _loadOperationalArea();
    _loadServiceCatalog();
  }

  @override
  void dispose() {
    _animationController.dispose();
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

  Future<void> _loadOperationalArea() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      if (mounted) setState(() => _isLoadingOperationalArea = false);
      return;
    }
    try {
      final profile = await _apiService.getMyWorkerProfile(token);
      if (!mounted) return;
      setState(() {
        _operationalAreaLabel = profile['operationalAreaLabel']
            ?.toString()
            .trim();
        _serviceRadiusKm = int.tryParse(
          profile['serviceRadiusKm']?.toString() ?? '',
        );
        _isLoadingOperationalArea = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingOperationalArea = false);
    }
  }

  Future<void> _loadServiceCatalog() async {
    try {
      final catalog = await _apiService.getActiveServiceCatalog();
      if (!mounted) return;

      String? groupId = _selectedCatalogGroupId;
      String? assetId = _selectedCatalogAssetId;
      String? itemId = _selectedCatalogItemId;
      ServiceCatalogItem? selectedItem;

      if (itemId != null) {
        selectedItem = catalog.items
            .where((item) => item.id == itemId)
            .firstOrNull;
      }
      if (selectedItem == null && _isEditMode) {
        final legacyName = widget.service!.namaLayanan.trim().toLowerCase();
        final legacyCategory = widget.service!.category.trim().toLowerCase();
        selectedItem = catalog.items.where((item) {
          final group = catalog.groups
              .where((entry) => entry.id == item.groupId)
              .firstOrNull;
          return item.name.trim().toLowerCase() == legacyName &&
              group?.name.trim().toLowerCase() == legacyCategory;
        }).firstOrNull;
      }
      if (selectedItem != null) {
        itemId = selectedItem.id;
        groupId = selectedItem.groupId;
        assetId = selectedItem.assetId;
      } else {
        itemId = null;
        groupId = null;
        assetId = null;
      }

      setState(() {
        _catalog = catalog;
        _selectedCatalogGroupId = groupId;
        _selectedCatalogAssetId = assetId;
        _selectedCatalogItemId = itemId;
        _isLoadingCatalog = false;
        _catalogError = catalog.items.isEmpty
            ? 'Katalog layanan belum diisi oleh Admin.'
            : null;
      });
      _ensureAllowedServiceType();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingCatalog = false;
        _catalogError = ApiService.readableError(
          error,
          action: 'Katalog gagal dimuat',
        );
      });
    }
  }

  Future<void> _openOperationalAreaSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WorkerOperationalAreaPage()),
    );
    if (mounted) {
      setState(() => _isLoadingOperationalArea = true);
      await _loadOperationalArea();
    }
  }

  Widget _buildOperationalAreaConfirmation() {
    final hasArea =
        _operationalAreaLabel?.isNotEmpty == true && _serviceRadiusKm != null;
    return _buildModernSection(
      'Area Layanan',
      Icons.location_on_outlined,
      Colors.teal,
      _isLoadingOperationalArea
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasArea ? Colors.teal.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasArea
                      ? Colors.teal.shade200
                      : Colors.orange.shade200,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        hasArea
                            ? Icons.check_circle_rounded
                            : Icons.warning_amber_rounded,
                        color: hasArea
                            ? Colors.teal.shade700
                            : Colors.orange.shade700,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasArea
                                  ? _operationalAreaLabel!
                                  : 'Area operasional belum lengkap',
                              style: TextStyle(
                                color: hasArea
                                    ? Colors.teal.shade900
                                    : Colors.orange.shade900,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasArea
                                  ? 'Melayani hingga $_serviceRadiusKm km'
                                  : 'Lengkapi area sebelum layanan dipublikasi.',
                              style: TextStyle(
                                color: hasArea
                                    ? Colors.teal.shade700
                                    : Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openOperationalAreaSettings,
                      icon: const Icon(Icons.edit_location_alt_outlined),
                      label: Text(hasArea ? 'Ubah di Profil' : 'Lengkapi Area'),
                    ),
                  ),
                ],
              ),
            ),
    );
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

  ServiceCatalogItem? get _selectedCatalogItem => _catalog?.items
      .where((item) => item.id == _selectedCatalogItemId)
      .firstOrNull;

  List<ServiceCatalogItem> get _itemsForSelectedGroup {
    final groupId = _selectedCatalogGroupId;
    if (groupId == null) return const [];
    return _catalog?.items
            .where((item) => item.groupId == groupId)
            .toList(growable: false) ??
        const [];
  }

  List<ServiceCatalogAsset> get _assetsForSelectedGroup {
    final assetIds = _itemsForSelectedGroup.map((item) => item.assetId).toSet();
    return _catalog?.assets
            .where((asset) => assetIds.contains(asset.id))
            .toList(growable: false) ??
        const [];
  }

  List<ServiceCatalogItem> get _itemsForSelectedAsset {
    final assetId = _selectedCatalogAssetId;
    if (assetId == null) return const [];
    return _itemsForSelectedGroup
        .where((item) => item.assetId == assetId)
        .toList(growable: false);
  }

  void _ensureAllowedServiceType() {
    final item = _selectedCatalogItem;
    if (item == null || item.allows(_serviceType.name)) return;
    final nextType = item.allows(ServiceType.fixed.name)
        ? ServiceType.fixed
        : ServiceType.survey;
    if (mounted) setState(() => _serviceType = nextType);
  }

  Widget _buildCatalogSelection() {
    if (_isLoadingCatalog) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 22),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_catalogError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade800,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _catalogError!,
                    style: TextStyle(color: Colors.orange.shade900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoadingCatalog = true;
                  _catalogError = null;
                });
                _loadServiceCatalog();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    InputDecoration decoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange.shade700),
        filled: true,
        fillColor: Colors.orange.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.orange.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.orange.shade200),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nama layanan ditentukan dari katalog resmi agar mudah ditemukan '
          'Customer dan dapat dibandingkan secara konsisten.',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          key: ValueKey('catalog-group-$_selectedCatalogGroupId'),
          initialValue: _selectedCatalogGroupId,
          isExpanded: true,
          decoration: decoration('1. Kelompok pekerjaan', Icons.account_tree),
          items: _catalog!.groups
              .map(
                (group) => DropdownMenuItem(
                  value: group.id,
                  child: Text(group.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() {
            _selectedCatalogGroupId = value;
            _selectedCatalogAssetId = null;
            _selectedCatalogItemId = null;
          }),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey(
            'catalog-asset-$_selectedCatalogGroupId-$_selectedCatalogAssetId',
          ),
          initialValue: _selectedCatalogAssetId,
          isExpanded: true,
          decoration: decoration(
            '2. Objek/peralatan',
            Icons.home_repair_service,
          ),
          items: _assetsForSelectedGroup
              .map(
                (asset) => DropdownMenuItem(
                  value: asset.id,
                  child: Text(asset.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: _selectedCatalogGroupId == null
              ? null
              : (value) => setState(() {
                  _selectedCatalogAssetId = value;
                  _selectedCatalogItemId = null;
                }),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey(
            'catalog-item-$_selectedCatalogAssetId-$_selectedCatalogItemId',
          ),
          initialValue: _selectedCatalogItemId,
          isExpanded: true,
          decoration: decoration('3. Layanan standar', Icons.checklist_rounded),
          items: _itemsForSelectedAsset
              .map(
                (item) => DropdownMenuItem(
                  value: item.id,
                  child: Text(item.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: _selectedCatalogAssetId == null
              ? null
              : (value) {
                  setState(() => _selectedCatalogItemId = value);
                  _ensureAllowedServiceType();
                },
        ),
        if (_isEditMode && widget.service!.catalogItemId == null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _selectedCatalogItemId == null
                  ? 'Layanan lama “${widget.service!.namaLayanan}” belum '
                        'dipetakan. Pilih katalog saat ingin menstandarkan nama.'
                  : 'Layanan lama akan dipetakan ke katalog dan kembali '
                        'menunggu persetujuan Admin.',
              style: TextStyle(
                color: Colors.blue.shade800,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleSaveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!_isEditMode) {
      final validationMessage = _validateCreateFields();
      if (validationMessage != null) {
        _showErrorSnack(scaffoldMessenger, validationMessage);
        return;
      }
    }

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

      final serviceData = _buildServicePayload(
        paymentMethods: paymentMethods,
        allImageUrls: allImageUrls,
      );

      if (_isEditMode) {
        if (serviceData.isEmpty) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Tidak ada perubahan yang perlu disimpan.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
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
      _showErrorSnack(
        scaffoldMessenger,
        ApiService.readableError(e, action: 'Gagal menyimpan layanan'),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _buildServicePayload({
    required List<String> paymentMethods,
    required List<String> allImageUrls,
  }) {
    final type = _serviceType == ServiceType.fixed ? 'fixed' : 'survey';
    final price = double.tryParse(_hargaController.text.trim()) ?? 0;
    final surveyFee = double.tryParse(_biayaSurveiController.text.trim()) ?? 0;
    final description = _deskripsiController.text.trim();
    final availability = serializeServiceAvailability(_selectedAvailability);

    if (!_isEditMode) {
      return {
        if (_selectedCatalogItemId != null)
          'catalogItemId': _selectedCatalogItemId,
        'deskripsiLayanan': description,
        'tipeLayanan': type,
        'harga': type == 'fixed' ? price : null,
        'biayaSurvei': type == 'survey' ? surveyFee : null,
        'photoUrls': allImageUrls,
        'fotoUtamaUrl': allImageUrls.isNotEmpty ? allImageUrls.first : '',
        'availability': availability,
        'metodePembayaran': paymentMethods,
      };
    }

    final original = widget.service!;
    final payload = <String, dynamic>{};

    if (_selectedCatalogItemId != original.catalogItemId &&
        _selectedCatalogItemId != null) {
      payload['catalogItemId'] = _selectedCatalogItemId;
    }
    if (description != original.deskripsiLayanan.trim()) {
      payload['deskripsiLayanan'] = description;
    }
    if (type != original.tipeLayanan) {
      payload['tipeLayanan'] = type;
    }
    if (type == 'fixed' &&
        (type != original.tipeLayanan || price != original.harga.toDouble())) {
      payload['harga'] = price;
    }
    if (type == 'survey' &&
        (type != original.tipeLayanan ||
            surveyFee != (original.biayaSurvei ?? 0).toDouble())) {
      payload['biayaSurvei'] = surveyFee;
    }
    if (_pickedImages.isNotEmpty) {
      payload['photoUrls'] = allImageUrls;
      payload['fotoUtamaUrl'] = allImageUrls.isNotEmpty
          ? allImageUrls.first
          : '';
    }
    if (!serviceAvailabilityMatches(
      original.availability,
      _selectedAvailability,
    )) {
      payload['availability'] = availability;
    }
    if (!_sameStringSet(paymentMethods, original.metodePembayaran)) {
      payload['metodePembayaran'] = paymentMethods;
    }

    return payload;
  }

  bool _sameStringSet(List<String> left, List<dynamic> right) {
    final leftSet = left.map((value) => value.trim().toLowerCase()).toSet();
    final rightSet = right
        .map((value) => value.toString().trim().toLowerCase())
        .toSet();
    return leftSet.length == rightSet.length && leftSet.containsAll(rightSet);
  }

  String? _validateCreateFields() {
    if (_isLoadingOperationalArea) {
      return 'Tunggu hingga area operasional selesai dimuat.';
    }
    if (_operationalAreaLabel?.isEmpty != false || _serviceRadiusKm == null) {
      return 'Lengkapi area operasional sebelum membuat layanan.';
    }
    if (_isLoadingCatalog) return 'Tunggu katalog layanan selesai dimuat.';
    if (_catalogError != null) return _catalogError;
    if (_selectedCatalogItemId == null) {
      return 'Pilih kelompok, objek, dan layanan standar.';
    }

    final hasImages = _pickedImages.isNotEmpty || _existingImageUrls.isNotEmpty;
    if (!hasImages) return 'Foto utama wajib diisi.';

    final hasAvailability = _selectedAvailability.values.any(
      (slots) => slots.isNotEmpty,
    );
    if (!hasAvailability) return 'Jadwal ketersediaan wajib diisi.';

    if (_serviceType == ServiceType.fixed) {
      final harga = double.tryParse(_hargaController.text.trim()) ?? 0;
      if (harga <= 0) return 'Harga wajib diisi.';
    } else {
      final biaya = double.tryParse(_biayaSurveiController.text.trim()) ?? 0;
      if (biaya <= 0) return 'Biaya survei wajib diisi.';
    }

    return null;
  }

  void _showErrorSnack(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade600,
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handlePhotoUpload() async {
    if (_isUploading) return;

    setState(() => _isUploading = true);

    final messenger = ScaffoldMessenger.of(context);

    try {
      final List<XFile> pickedFiles = await ImagePicker().pickMultiImage(
        imageQuality: 70,
        maxWidth: 1600,
        maxHeight: 1600,
        requestFullMetadata: false,
      );

      if (!mounted || pickedFiles.isEmpty) return;

      setState(() {
        _pickedImages.addAll(pickedFiles.map((file) => File(file.path)));
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showErrorSnack(
        messenger,
        e.message ?? 'Gagal membuka galeri. Coba pilih gambar lagi.',
      );
    } catch (_) {
      if (!mounted) return;
      _showErrorSnack(
        messenger,
        'Terjadi kendala saat memilih gambar. Coba lagi.',
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
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

                  _buildOperationalAreaConfirmation(),

                  const SizedBox(height: 20),

                  // Main Image Section
                  _buildModernSection(
                    'Foto Utama',
                    Icons.photo_camera,
                    Colors.blue,
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isUploading ? null : _handlePhotoUpload,
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
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
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Service catalog mapping
                  _buildModernSection(
                    'Pemetaan Layanan',
                    Icons.account_tree_rounded,
                    Colors.orange,
                    _buildCatalogSelection(),
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

                  if (_serviceType == ServiceType.fixed) ...[
                    // Payment Method Section (only for fixed price)
                    _buildModernSection(
                      'Metode Pembayaran',
                      Icons.payment,
                      Colors.teal,
                      Container(
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
                  ],

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
    final isAllowed =
        _selectedCatalogItem?.allows(type.name) ??
        (_selectedCatalogItemId == null);
    return GestureDetector(
      onTap: isAllowed ? () => setState(() => _serviceType = type) : null,
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
        child: Opacity(
          opacity: isAllowed ? 1 : 0.42,
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
                isAllowed ? description : 'Tidak tersedia',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white70 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
                  cacheWidth: _thumbnailCacheSize,
                  cacheHeight: _thumbnailCacheSize,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey.shade600,
                    ),
                  ),
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
        cacheWidth: _thumbnailCacheSize,
        cacheHeight: _thumbnailCacheSize,
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
      child: Image.file(
        file,
        fit: BoxFit.cover,
        cacheWidth: _thumbnailCacheSize,
        cacheHeight: _thumbnailCacheSize,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade200,
          child: Icon(Icons.broken_image, color: Colors.grey.shade600),
        ),
      ),
    ),
  );
}
