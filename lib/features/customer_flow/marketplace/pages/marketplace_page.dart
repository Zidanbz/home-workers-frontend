import 'package:flutter/material.dart';
import 'package:home_workers_fe/features/customer_flow/chat/pages/customer_chat_list_page.dart';
import 'package:home_workers_fe/features/customer_flow/marketplace/widgets/marketplace_service_card.dart';
import 'package:home_workers_fe/features/customer_flow/marketplace/widgets/nearest_address_loading_overlay.dart';
import 'package:home_workers_fe/features/notifications/pages/notification_page.dart';
import 'package:home_workers_fe/features/profile/pages/add_address_page.dart';
import 'package:provider/provider.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/models/address_model.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/state/auth_provider.dart';

class MarketplacePage extends StatefulWidget {
  final double bottomNavigationClearance;

  const MarketplacePage({super.key, this.bottomNavigationClearance = 0});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage>
    with AutomaticKeepAliveClientMixin {
  static const Color _primaryColor = Color(0xFF163B52);
  static const Color _accentColor = Color(0xFF0F8B78);
  static const Color _backgroundColor = Color(0xFFF5F8FA);
  static const Color _surfaceColor = Color(0xFFFFFFFF);
  static const Color _mutedColor = Color(0xFF6B7D87);

  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Service>> _servicesFuture;
  String _searchQuery = '';
  String _selectedSort = 'default';
  Address? _selectedAddress;
  bool _isPreparingNearest = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final future =
        _selectedSort == 'nearest' && _selectedAddress != null && token != null
        ? _apiService.getNearbyApprovedServices(
            token: token,
            addressId: _selectedAddress!.id,
          )
        : _apiService.getAllApprovedServices();
    setState(() {
      _servicesFuture = future;
    });
    try {
      await future;
    } catch (_) {
      // Error tetap disimpan pada Future dan ditampilkan oleh FutureBuilder.
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Service> _filteredServices(List<Service> services) {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final filtered = services.where((service) {
      if (normalizedQuery.isEmpty) return true;
      final workerName = service.workerInfo['nama']?.toString() ?? '';
      return service.namaLayanan.toLowerCase().contains(normalizedQuery) ||
          service.category.toLowerCase().contains(normalizedQuery) ||
          workerName.toLowerCase().contains(normalizedQuery);
    }).toList();

    if (_selectedSort == 'harga-asc') {
      filtered.sort((a, b) => _effectivePrice(a).compareTo(_effectivePrice(b)));
    } else if (_selectedSort == 'harga-desc') {
      filtered.sort((a, b) => _effectivePrice(b).compareTo(_effectivePrice(a)));
    } else if (_selectedSort == 'nearest') {
      filtered.sort(
        (a, b) => (a.distanceKm ?? double.infinity).compareTo(
          b.distanceKm ?? double.infinity,
        ),
      );
    }
    return filtered;
  }

  num _effectivePrice(Service service) {
    return service.tipeLayanan == 'survey'
        ? service.biayaSurvei ?? 0
        : service.harga;
  }

  String get _sortLabel {
    switch (_selectedSort) {
      case 'harga-asc':
        return 'Harga terendah';
      case 'harga-desc':
        return 'Harga tertinggi';
      case 'nearest':
        final label = _selectedAddress?.label.trim();
        return label == null || label.isEmpty
            ? 'Terdekat'
            : 'Terdekat dari $label';
      default:
        return 'Rekomendasi';
    }
  }

  double _bottomContentInset(BuildContext context) {
    return widget.bottomNavigationClearance +
        MediaQuery.viewPaddingOf(context).bottom +
        20;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cari Pekerja',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: _primaryColor,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Temukan layanan sesuai kebutuhanmu',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: _mutedColor,
              ),
            ),
          ],
        ),
        backgroundColor: _surfaceColor,
        surfaceTintColor: _surfaceColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          _buildHeaderAction(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notifikasi',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          _buildHeaderAction(
            icon: Icons.chat_bubble_outline_rounded,
            tooltip: 'Chat',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CustomerChatListPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildDiscoveryBar(),
              Expanded(
                child: FutureBuilder<List<Service>>(
                  future: _servicesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingList();
                    }
                    if (snapshot.hasError) {
                      return _buildStateList(
                        icon: Icons.cloud_off_rounded,
                        title: 'Marketplace belum dapat dimuat',
                        message: ApiService.readableError(
                          snapshot.error,
                          action: 'Gagal memuat marketplace',
                        ),
                        actionLabel: 'Coba Lagi',
                        onAction: _loadServices,
                      );
                    }

                    final allServices = snapshot.data ?? [];
                    final filteredServices = _filteredServices(allServices);
                    if (allServices.isEmpty) {
                      return _buildStateList(
                        icon: _selectedSort == 'nearest'
                            ? Icons.location_off_outlined
                            : Icons.home_repair_service_outlined,
                        title: _selectedSort == 'nearest'
                            ? 'Belum ada layanan yang menjangkau alamat ini'
                            : 'Belum ada layanan',
                        message: _selectedSort == 'nearest'
                            ? 'Coba gunakan alamat tersimpan lain atau pilih rekomendasi.'
                            : 'Layanan yang sudah disetujui akan tampil di halaman ini.',
                        actionLabel: 'Muat Ulang',
                        onAction: _loadServices,
                      );
                    }
                    if (filteredServices.isEmpty) {
                      return _buildStateList(
                        icon: Icons.search_off_rounded,
                        title: 'Layanan tidak ditemukan',
                        message:
                            'Coba gunakan nama layanan, kategori, atau nama Worker lain.',
                        actionLabel: 'Hapus Pencarian',
                        onAction: _clearSearch,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _loadServices,
                      color: _primaryColor,
                      backgroundColor: _surfaceColor,
                      child: ListView.separated(
                        key: const PageStorageKey('marketplace-list'),
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          16,
                          18,
                          16,
                          _bottomContentInset(context),
                        ),
                        itemCount: filteredServices.length + 1,
                        separatorBuilder: (_, index) =>
                            SizedBox(height: index == 0 ? 14 : 12),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildResultHeader(filteredServices.length);
                          }
                          return MarketplaceServiceCard(
                            service: filteredServices[index - 1],
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (_isPreparingNearest)
            const Positioned.fill(child: NearestAddressLoadingOverlay()),
        ],
      ),
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: _primaryColor, size: 23),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoveryBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: _surfaceColor,
        border: Border(bottom: BorderSide(color: Color(0xFFE6ECEF))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                color: _primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Cari layanan atau Worker',
                hintStyle: const TextStyle(
                  color: _mutedColor,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _mutedColor,
                ),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus pencarian',
                        onPressed: _clearSearch,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: _mutedColor,
                          size: 20,
                        ),
                      ),
                filled: true,
                fillColor: _backgroundColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE1E8EC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: _primaryColor,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          PopupMenuButton<String>(
            initialValue: _selectedSort,
            tooltip: 'Urutkan layanan',
            onSelected: (value) {
              _handleSortSelected(value);
            },
            color: _surfaceColor,
            surfaceTintColor: _surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'default',
                child: _SortMenuItem(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Rekomendasi',
                ),
              ),
              PopupMenuItem(
                value: 'harga-asc',
                child: _SortMenuItem(
                  icon: Icons.south_rounded,
                  label: 'Harga terendah',
                ),
              ),
              PopupMenuItem(
                value: 'harga-desc',
                child: _SortMenuItem(
                  icon: Icons.north_rounded,
                  label: 'Harga tertinggi',
                ),
              ),
              PopupMenuItem(
                value: 'nearest',
                child: _SortMenuItem(
                  icon: Icons.near_me_outlined,
                  label: 'Terdekat',
                ),
              ),
            ],
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: _selectedSort == 'default'
                    ? _backgroundColor
                    : const Color(0xFFE8F5F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedSort == 'default'
                      ? const Color(0xFFE1E8EC)
                      : _accentColor,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    _isPreparingNearest
                        ? Icons.hourglass_top_rounded
                        : Icons.tune_rounded,
                    color: _selectedSort == 'default'
                        ? _primaryColor
                        : _accentColor,
                  ),
                  if (_selectedSort != 'default')
                    const Positioned(
                      top: 10,
                      right: 10,
                      child: CircleAvatar(
                        radius: 3,
                        backgroundColor: _accentColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultHeader(int count) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _searchQuery.trim().isEmpty
                    ? 'Layanan untukmu'
                    : 'Hasil pencarian',
                style: const TextStyle(
                  color: _primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$count layanan • $_sortLabel',
                style: const TextStyle(
                  color: _mutedColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.swipe_up_rounded, color: Color(0xFF9AABB4), size: 20),
      ],
    );
  }

  Widget _buildLoadingList() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 18, 16, _bottomContentInset(context)),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const MarketplaceServiceCardSkeleton(),
    );
  }

  Widget _buildStateList({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required Future<void> Function() onAction,
  }) {
    return RefreshIndicator(
      onRefresh: _loadServices,
      color: _primaryColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24, 64, 24, _bottomContentInset(context)),
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE1E8EC)),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF4F7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, color: _primaryColor, size: 30),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _mutedColor,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(actionLabel),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearSearch() async {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  Future<void> _handleSortSelected(String value) async {
    if (value == 'nearest') {
      await _activateNearestSort();
      return;
    }

    final wasNearest = _selectedSort == 'nearest';
    setState(() => _selectedSort = value);
    if (wasNearest) {
      await _loadServices();
    }
  }

  Future<void> _activateNearestSort() async {
    if (_isPreparingNearest) return;
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      _showMessage('Silakan login kembali untuk menggunakan filter terdekat.');
      return;
    }

    setState(() => _isPreparingNearest = true);
    try {
      var addresses = await _apiService.getMyAddresses(token);
      var validAddresses = addresses.where(_hasValidCoordinate).toList();

      if (validAddresses.isEmpty) {
        if (!mounted) return;
        setState(() => _isPreparingNearest = false);
        _showMessage(
          addresses.isEmpty
              ? 'Tambahkan alamat terlebih dahulu untuk mencari Worker terdekat.'
              : 'Alamat lama belum memiliki titik peta. Tambahkan alamat baru.',
        );
        final created = await Navigator.of(
          context,
        ).push<bool>(MaterialPageRoute(builder: (_) => const AddAddressPage()));
        if (created != true || !mounted) return;
        setState(() => _isPreparingNearest = true);
        addresses = await _apiService.getMyAddresses(token);
        validAddresses = addresses.where(_hasValidCoordinate).toList();
      }

      if (validAddresses.isEmpty || !mounted) return;
      setState(() => _isPreparingNearest = false);
      final address = validAddresses.length == 1
          ? validAddresses.first
          : await _showAddressPicker(validAddresses);
      if (address == null || !mounted) return;

      setState(() {
        _selectedAddress = address;
        _selectedSort = 'nearest';
      });
      await _loadServices();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isPreparingNearest = false);
      _showMessage(
        ApiService.readableError(
          error,
          action: 'Gagal menyiapkan filter terdekat',
        ),
      );
    } finally {
      if (mounted) setState(() => _isPreparingNearest = false);
    }
  }

  bool _hasValidCoordinate(Address address) {
    final latitude = address.latitude;
    final longitude = address.longitude;
    return latitude != null &&
        longitude != null &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }

  Future<Address?> _showAddressPicker(List<Address> addresses) {
    return showModalBottomSheet<Address>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: _surfaceColor,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih alamat layanan',
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Jarak Worker akan dihitung dari alamat ini.',
                  style: TextStyle(color: _mutedColor, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: addresses.length,
                    itemBuilder: (_, index) {
                      final address = addresses[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE8F5F2),
                          child: Icon(
                            Icons.location_on_outlined,
                            color: _accentColor,
                          ),
                        ),
                        title: Text(
                          address.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          address.fullAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.of(sheetContext).pop(address),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SortMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SortMenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: const Color(0xFF163B52)),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}
