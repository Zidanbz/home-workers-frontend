import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:home_workers_fe/core/helper/voucher_helper.dart';
import 'package:home_workers_fe/core/models/address_model.dart';
import 'package:home_workers_fe/core/models/availability_model.dart';
import 'package:home_workers_fe/features/costumer_flow/booking/pages/snapPayment_page.dart';
import 'package:home_workers_fe/features/workerprofile/pages/worker_profile_page.dart';
import 'package:home_workers_fe/shared_widgets/action_tap_guard.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:home_workers_fe/core/api/api_service.dart';
import 'package:home_workers_fe/core/models/service_model.dart';
import 'package:home_workers_fe/core/state/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

enum BookingLocationMode { saved, other }

class BookingPage extends StatefulWidget {
  final Service service;
  const BookingPage({super.key, required this.service});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;

  String? _selectedVoucher; // kode voucher dipilih user
  String? _appliedVoucherCode; // voucher yang sudah dicek dan diterapkan
  int _basePrice = 0; // harga dasar layanan
  int _discount = 0; // diskon dari voucher
  int _finalPrice = 0; // harga setelah diskon
  String? _voucherMessage;

  List<Map<String, dynamic>> _vouchers = []; // List voucher untuk dropdown
  List<String> _bookedSlots = [];
  Address? _defaultAddress;
  BookingLocationMode _locationMode = BookingLocationMode.saved;
  final TextEditingController _otherLocationController = TextEditingController();
  bool _isAddressLoading = false;
  final String _googlePlacesApiKey = "AIzaSyCRe7xfKI2OzPUp9pUWxR2QHH8zsdhoWTw";
  String _locationSessionToken = const Uuid().v4();
  List<dynamic> _locationPredictions = [];
  double? _otherLocationLatitude;
  double? _otherLocationLongitude;
  Timer? _slotRefreshTimer;

  List<String> get _availableTimeSlots {
    final weekday = DateFormat(
      'EEEE',
      'id_ID',
    ).format(_selectedDate).toLowerCase();
    final availability = widget.service.availability.firstWhere(
      (a) => a.day.toLowerCase() == weekday,
      orElse: () => Availability(day: weekday, slots: []),
    );
    return availability.slots;
  }

  @override
  void initState() {
    super.initState();
    _basePrice = widget.service.harga ?? 0;
    _finalPrice = _basePrice;
    _loadBookedSlots();
    _fetchVouchers();
    _loadSavedAddresses();
    _startSlotRefreshTimer();
  }

  @override
  void dispose() {
    _slotRefreshTimer?.cancel();
    _otherLocationController.dispose();
    super.dispose();
  }

  void _startSlotRefreshTimer() {
    _slotRefreshTimer?.cancel();
    _slotRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      _clearInvalidSelectedSlot();
      setState(() {});
    });
  }

  String _normalizeTimeSlot(String slot) => slot.trim().replaceAll(':', '.');

  DateTime? _parseSlotDateTime(String slot, DateTime date) {
    final match = RegExp(r'(\d{2})[.:](\d{2})').firstMatch(slot.trim());
    if (match == null) return null;

    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null || minute == null) return null;

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  bool _isSlotInvalidByTimeOrBooking(String slot) {
    final normalizedSlot = _normalizeTimeSlot(slot);
    final isBooked = _bookedSlots.map(_normalizeTimeSlot).contains(normalizedSlot);
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(_selectedDate, now);
    final slotTime = _parseSlotDateTime(slot, _selectedDate);
    final isPast = isToday && slotTime != null && slotTime.isBefore(now);
    return isBooked || isPast;
  }

  void _clearInvalidSelectedSlot() {
    final selected = _selectedTimeSlot;
    if (selected == null) return;
    if (_isSlotInvalidByTimeOrBooking(selected)) {
      _selectedTimeSlot = null;
    }
  }

  void _onOtherLocationQueryChanged(String input) {
    _otherLocationLatitude = null;
    _otherLocationLongitude = null;
    if (input.trim().isEmpty) {
      setState(() => _locationPredictions = []);
      return;
    }
    _getLocationPredictions(input.trim());
  }

  Future<void> _getLocationPredictions(String input) async {
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=$input'
      '&key=$_googlePlacesApiKey'
      '&sessiontoken=$_locationSessionToken'
      '&components=country:id',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _locationPredictions = List<dynamic>.from(body['predictions'] ?? []);
      });
    } catch (_) {
      // Keep silent to avoid noisy UI while typing.
    }
  }

  Future<void> _pickOtherLocationFromPrediction(String placeId) async {
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&key=$_googlePlacesApiKey'
      '&sessiontoken=$_locationSessionToken',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final result = body['result'] as Map<String, dynamic>?;
      final geometry = result?['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      final lat = (location?['lat'] as num?)?.toDouble();
      final lng = (location?['lng'] as num?)?.toDouble();
      final formattedAddress = (result?['formatted_address'] ?? '').toString();
      if (!mounted) return;

      setState(() {
        _otherLocationController.text = formattedAddress;
        _otherLocationLatitude = lat;
        _otherLocationLongitude = lng;
        _locationPredictions = [];
        _locationSessionToken = const Uuid().v4();
      });
    } catch (_) {
      // Keep silent to avoid blocking booking flow.
    }
  }

  Future<void> _loadSavedAddresses() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    setState(() => _isAddressLoading = true);
    try {
      final addresses = await _apiService.getMyAddresses(token);
      if (!mounted) return;
      setState(() {
        _defaultAddress = addresses.isNotEmpty ? addresses.first : null;
        if (_defaultAddress == null) {
          _locationMode = BookingLocationMode.other;
        }
      });
    } catch (e) {
      debugPrint('Gagal memuat alamat tersimpan: $e');
    } finally {
      if (mounted) {
        setState(() => _isAddressLoading = false);
      }
    }
  }

  Future<void> _fetchVouchers() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    try {
      final raw = await _apiService.getAvailableVouchers(token: token);
      final normalized = normalizeVouchers(raw);
      if (mounted) {
        setState(() {
          _vouchers = normalized;
        });
      }
    } catch (e) {
      debugPrint('Gagal ambil voucher: $e');
    }
  }

  Future<void> _loadBookedSlots() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final workerId = widget.service.workerInfo['id'];

    if (token == null || workerId == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      final booked = await _apiService.getBookedSlots(
        token: token,
        workerId: workerId,
        date: dateStr,
      );
      if (mounted) {
        setState(() {
          _bookedSlots = booked;
          _clearInvalidSelectedSlot();
        });
      }
    } catch (e) {
      debugPrint('Gagal ambil booked slots: $e');
    }
  }

  Future<void> _validateAndApplyVoucher(String voucherCode) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    try {
      final result = await _apiService.validateVoucherCode(
        token: token!,
        voucherCode: voucherCode,
        orderAmount: _basePrice,
      );

      final discount = (result['discount'] ?? 0) as int;
      final finalTotal =
          (result['finalTotal'] ?? (_basePrice - discount)) as int;

      setState(() {
        _discount = discount;
        _finalPrice = finalTotal < 0 ? 0 : finalTotal;
        _appliedVoucherCode = result['voucherCode'] ?? voucherCode;
        _voucherMessage = result['message'] ?? 'Voucher diterapkan.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voucher diterapkan: -${_formatCurrency(discount)}'),
        ),
      );
    } catch (e) {
      // Reset voucher state and selected voucher if validation fails
      String errorMessage = ApiService.readableError(
        e,
        action: 'Validasi voucher gagal',
      );
      final lowerErrorMessage = errorMessage.toLowerCase();
      if (lowerErrorMessage.contains('validation error') ||
          lowerErrorMessage.contains('validasi voucher gagal') ||
          lowerErrorMessage.contains('data yang dimasukkan tidak valid')) {
        errorMessage =
            'Voucher tidak memenuhi syarat minimum order atau sudah kadaluarsa.';
      }
      setState(() {
        _selectedVoucher = null;
        _resetVoucher();
        _voucherMessage = errorMessage;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_voucherMessage!), backgroundColor: Colors.red),
      );
    }
  }

  void _resetVoucher() {
    _discount = 0;
    _finalPrice = _basePrice;
    _appliedVoucherCode = null;
    _voucherMessage = null;
  }

  Future<void> _handleCreateOrder() async {
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih jam kerja terlebih dahulu.')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);

    try {
      final token = authProvider.token;
      if (token == null) throw Exception('Anda belum login.');

      print('🎯 [BookingPage] Starting order creation process');
      print('🎯 [BookingPage] Service ID: ${widget.service.id}');
      print('🎯 [BookingPage] Service Type: ${widget.service.tipeLayanan}');
      print('🎯 [BookingPage] Token available: ${token.isNotEmpty}');

      final regex = RegExp(r'(\d{2})\.(\d{2})');
      final match = regex.firstMatch(_selectedTimeSlot!);
      if (match == null) throw Exception('Format jam tidak valid');

      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);

      final schedule = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        hour,
        minute,
      );

      print('🎯 [BookingPage] Schedule: $schedule');
      print('🎯 [BookingPage] Applied voucher: $_appliedVoucherCode');

      String locationMode;
      String? savedAddressId;
      String? customAddress;
      double? customLatitude;
      double? customLongitude;

      if (_locationMode == BookingLocationMode.saved) {
        if (_defaultAddress == null) {
          throw Exception(
            'Alamat tersimpan belum tersedia. Pilih lokasi lain atau tambah alamat tersimpan.',
          );
        }
        locationMode = 'saved';
        savedAddressId = _defaultAddress!.id;
      } else {
        final otherAddress = _otherLocationController.text.trim();
        if (otherAddress.isEmpty) {
          throw Exception('Alamat lokasi lain wajib diisi.');
        }
        locationMode = 'other';
        customAddress = otherAddress;
        customLatitude = _otherLocationLatitude;
        customLongitude = _otherLocationLongitude;
      }

      print('🎯 [BookingPage] Calling createOrderWithPayment...');
      final response = await _apiService.createOrderWithPayment(
        token: token,
        serviceId: widget.service.id,
        jadwalPerbaikan: schedule,
        catatan: 'Permintaan survei dulu ya kak!',
        voucherCode: _appliedVoucherCode,
        locationMode: locationMode,
        savedAddressId: savedAddressId,
        customAddress: customAddress,
        customLatitude: customLatitude,
        customLongitude: customLongitude,
      );

      print('🎯 [BookingPage] API Response received: $response');
      print('🎯 [BookingPage] Response type: ${response.runtimeType}');

      // Check if response is null
      if (response == null) {
        print('❌ [BookingPage] Response is null!');
        throw Exception('Server tidak merespons. Silakan coba lagi.');
      }

      // Check if response is a Map
      if (response is! Map<String, dynamic>) {
        print('❌ [BookingPage] Response is not a Map: ${response.runtimeType}');
        throw Exception('Format respons server tidak valid.');
      }

      print('🎯 [BookingPage] Response keys: ${response.keys.toList()}');

      final snapToken = response['snapToken']?.toString();
      print('🎯 [BookingPage] Snap Token: $snapToken');

      if (snapToken == null) {
        print('❌ [BookingPage] Snap token is null!');
        throw Exception('Token pembayaran tidak diterima dari server.');
      }

      final orderId = response['orderId']?.toString();
      final midtransOrderId =
          response['midtransOrderId']?.toString() ?? orderId;
      final redirectUrlFromServer = response['redirectUrl']?.toString();
      final snapHost = dotenv.env['MIDTRANS_SNAP_HOST'] ?? 'app.midtrans.com';
      final snapRedirectUrl =
          (redirectUrlFromServer != null && redirectUrlFromServer.isNotEmpty)
          ? redirectUrlFromServer
          : "https://$snapHost/snap/v2/vtweb/$snapToken";

      // Guard: kalau app run sandbox tapi backend masih mengembalikan URL production.
      const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'prod');
      final isSandboxApp = appEnv.toLowerCase() == 'sandbox';
      final redirectHost = Uri.tryParse(snapRedirectUrl)?.host ?? '';
      final isSandboxRedirect = redirectHost.contains('sandbox.midtrans.com');
      if (isSandboxApp && !isSandboxRedirect) {
        print(
          '⚠️ [BookingPage] APP_ENV=sandbox tapi redirectUrl production. '
          'Cek API_BASE_URL & deploy backend dev (howek-dev) + MIDTRANS_IS_PRODUCTION=false.',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Mode sandbox aktif, tapi link pembayaran masih production. Cek API_BASE_URL dan pastikan backend dev memakai Midtrans sandbox.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        });
      }

      final resolvedHost = Uri.tryParse(snapRedirectUrl)?.host;
      if (resolvedHost != null &&
          resolvedHost.isNotEmpty &&
          resolvedHost != snapHost) {
        print(
          '⚠️ [BookingPage] Redirect host mismatch. envHost=$snapHost, redirectHost=$resolvedHost',
        );
      }

      print('🎯 [BookingPage] Redirect URL: $snapRedirectUrl');
      print('🎯 [BookingPage] Navigating to payment page...');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SnapPaymentPage(
            redirectUrl: snapRedirectUrl,
            orderId: midtransOrderId,
          ),
        ),
      );
    } catch (e) {
      print('❌ [BookingPage] Exception caught: $e');
      print('❌ [BookingPage] Exception type: ${e.runtimeType}');
      print('❌ [BookingPage] Stack trace: ${StackTrace.current}');

      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            ApiService.readableError(e, action: 'Gagal membuat pesanan'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(int value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(value);
  }

  Future<void> _refreshBookingData() async {
    await Future.wait([_loadBookedSlots(), _fetchVouchers(), _loadSavedAddresses()]);
  }

  @override
  Widget build(BuildContext context) {
    final isSurvey = widget.service.tipeLayanan == 'survey';

    // Check if payment method contains "cek dulu" (case-insensitive)
    final hasCekDulu = widget.service.metodePembayaran.any(
      (method) => method.toString().toLowerCase().contains('cek dulu'),
    );

    // Debug print
    print(
      '🔍 [BookingPage] Metode Pembayaran: ${widget.service.metodePembayaran}',
    );
    print('🔍 [BookingPage] isSurvey: $isSurvey');
    print('🔍 [BookingPage] hasCekDulu: $hasCekDulu');
    print('🔍 [BookingPage] Show Voucher: ${!isSurvey && !hasCekDulu}');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Tanggal dan Waktu Pekerjaan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshBookingData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWorkerInfo(),
              const SizedBox(height: 24),
              const Text(
                'Kapan Anda menginginkan layanan?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 24),
              const Text(
                'Jam berapa Anda ingin layanan dimulai?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildTimeSlotPicker(),
              const SizedBox(height: 24),
              _buildLocationSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(isSurvey, !isSurvey && !hasCekDulu),
    );
  }

  Widget _buildWorkerInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundImage: NetworkImage(
            widget.service.workerInfo['avatarUrl'] ?? '',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.service.workerInfo['nama'] ?? 'Nama Worker',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        TextButton(
          onPressed: () {
            final workerId = widget.service.workerInfo['id'] as String?;
            if (workerId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ID Worker tidak ditemukan')),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkerProfilePage(workerId: workerId),
              ),
            );
          },
          child: const Text('Lihat Profil >'),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(_selectedDate, date);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
                _selectedTimeSlot = null;
              });
              _loadBookedSlots();
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3A3F51) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE', 'id_ID').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSlotPicker() {
    final slots = _availableTimeSlots;
    if (slots.isEmpty) {
      return const Text(
        'Tidak ada waktu tersedia pada hari ini.',
        style: TextStyle(color: Colors.red),
      );
    }

    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(_selectedDate, now);

    return Wrap(
      spacing: 12.0,
      runSpacing: 12.0,
      children: slots.map((slot) {
        final isSelected = _selectedTimeSlot == slot;
        final normalizedSlot = _normalizeTimeSlot(slot);
        final isBooked = _bookedSlots
            .map(_normalizeTimeSlot)
            .contains(normalizedSlot);

        final slotTime = _parseSlotDateTime(slot, _selectedDate);

        final isPast = isToday && slotTime != null && slotTime.isBefore(now);
        final isDisabled = isBooked || isPast;

        return ChoiceChip(
          label: Text(slot),
          selected: isSelected,
          onSelected: isDisabled
              ? null
              : (selected) =>
                    setState(() => _selectedTimeSlot = selected ? slot : null),
          selectedColor: const Color(0xFF3A3F51),
          labelStyle: TextStyle(
            color: isDisabled
                ? Colors.grey
                : (isSelected ? Colors.white : Colors.black),
            decoration: isDisabled
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
          backgroundColor: isDisabled ? Colors.grey.shade200 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDisabled ? Colors.grey.shade300 : Colors.grey.shade400,
            ),
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _buildLocationSection() {
    final hasSavedAddress = _defaultAddress != null;
    final subtitleColor = Colors.grey.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lokasi Pengerjaan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        if (_isAddressLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: LinearProgressIndicator(minHeight: 3),
          ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ChoiceChip(
              label: const Text('Lokasi saat ini'),
              selected: _locationMode == BookingLocationMode.saved,
              onSelected: hasSavedAddress
                  ? (_) {
                      setState(() {
                        _locationMode = BookingLocationMode.saved;
                        _locationPredictions = [];
                      });
                    }
                  : null,
              selectedColor: const Color(0xFF1A374D),
              disabledColor: Colors.grey.shade200,
              labelStyle: TextStyle(
                color: hasSavedAddress
                    ? (_locationMode == BookingLocationMode.saved
                          ? Colors.white
                          : Colors.black87)
                    : Colors.grey,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: hasSavedAddress
                      ? Colors.grey.shade400
                      : Colors.grey.shade300,
                ),
              ),
              showCheckmark: false,
            ),
            ChoiceChip(
              label: const Text('Lokasi lain'),
              selected: _locationMode == BookingLocationMode.other,
              onSelected: (_) {
                setState(() {
                  _locationMode = BookingLocationMode.other;
                });
              },
              selectedColor: const Color(0xFF1A374D),
              labelStyle: TextStyle(
                color: _locationMode == BookingLocationMode.other
                    ? Colors.white
                    : Colors.black87,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              showCheckmark: false,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_locationMode == BookingLocationMode.saved)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasSavedAddress ? Colors.white : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasSavedAddress ? Colors.grey.shade300 : Colors.grey.shade200,
              ),
            ),
            child: hasSavedAddress
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _defaultAddress!.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A374D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _defaultAddress!.fullAddress,
                        style: TextStyle(color: subtitleColor),
                      ),
                    ],
                  )
                : Text(
                    'Belum ada alamat tersimpan. Tambahkan alamat dari menu Profil > Alamat Tersimpan.',
                    style: TextStyle(color: subtitleColor),
                  ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _otherLocationController,
                maxLines: 1,
                onChanged: _onOtherLocationQueryChanged,
                decoration: InputDecoration(
                  hintText: 'Cari alamat lokasi lain...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: _otherLocationController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _otherLocationController.clear();
                              _locationPredictions = [];
                              _otherLocationLatitude = null;
                              _otherLocationLongitude = null;
                            });
                          },
                        )
                      : null,
                ),
              ),
              if (_locationPredictions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _locationPredictions.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),
                    itemBuilder: (context, index) {
                      final prediction =
                          _locationPredictions[index] as Map<String, dynamic>;
                      final description =
                          (prediction['description'] ?? '').toString();
                      final placeId = (prediction['place_id'] ?? '').toString();

                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text(description, maxLines: 2),
                        onTap: placeId.isEmpty
                            ? null
                            : () => _pickOtherLocationFromPrediction(placeId),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _buildVoucherSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_offer_rounded, color: Color(0xFF1A374D)),
            const SizedBox(width: 8),
            const Text(
              'Voucher',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const Spacer(),
            if (_appliedVoucherCode != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedVoucher = null;
                    _appliedVoucherCode = null;
                    _discount = 0;
                    _finalPrice = _basePrice;
                    _voucherMessage = 'Voucher dibatalkan.';
                  });
                },
                child: const Text('Batalkan'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_vouchers.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: const Text(
              'Tidak ada voucher yang tersedia saat ini',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          InkWell(
            onTap: _showVoucherPickerBottomSheet,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedVoucher == null
                          ? 'Pilih voucher untuk diskon'
                          : 'Voucher dipilih: $_selectedVoucher',
                      style: TextStyle(
                        color: _selectedVoucher == null
                            ? Colors.grey.shade600
                            : const Color(0xFF1A374D),
                        fontWeight: _selectedVoucher == null
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded),
                ],
              ),
            ),
          ),
        if (_voucherMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _voucherMessage!,
              style: TextStyle(
                color: _appliedVoucherCode != null ? Colors.green : Colors.red,
              ),
              ),
            ),
        if (_discount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Diskon: ${_formatCurrency(_discount)}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showVoucherPickerBottomSheet() async {
    final selectedCode = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Voucher',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _vouchers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final v = _vouchers[index];
                      final code = v['code'] as String;
                      final discountType = v['discountType'];
                      final value = v['value'];
                      final label = discountType == 'percent'
                          ? '$code • ${value}%'
                          : '$code • ${_formatCurrency(value is int ? value : int.tryParse(value.toString()) ?? 0)}';

                      return ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        title: Text(
                          label,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: _selectedVoucher == code
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFF1A374D),
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(code),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedCode == null) return;
    setState(() {
      _selectedVoucher = selectedCode;
    });
    await _validateAndApplyVoucher(selectedCode);
  }

  Widget _buildBottomBar(bool isSurvey, bool showVoucher) {
    final totalPrice = isSurvey ? 0 : _finalPrice;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showVoucher) ...[
              _buildVoucherSection(),
              const SizedBox(height: 14),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Total Biaya',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      isSurvey
                          ? 'Menunggu Penawaran'
                          : _formatCurrency(totalPrice),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () {
                          ActionTapGuard.run(
                            context,
                            _handleCreateOrder,
                            label: 'Membuat pesanan',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E232C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
                        child: Text(
                          isSurvey ? 'Kirim Permintaan' : 'Lanjut ke Pembayaran',
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
