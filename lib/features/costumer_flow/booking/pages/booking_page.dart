import 'package:flutter/material.dart';
import 'package:home_workers_fe/core/helper/voucher_helper.dart';
import 'package:home_workers_fe/core/models/availability_model.dart';
import 'package:home_workers_fe/features/costumer_flow/booking/pages/snapPayment_page.dart';
import 'package:home_workers_fe/features/workerprofile/pages/worker_profile_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:home_workers_fe/core/api/api_service.dart';
import 'package:home_workers_fe/core/models/service_model.dart';
import 'package:home_workers_fe/core/state/auth_provider.dart';

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
  bool _checkingVoucher = false;
  String? _voucherMessage;

  List<Map<String, dynamic>> _vouchers = []; // List voucher untuk dropdown
  List<String> _bookedSlots = [];

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
        });
      }
    } catch (e) {
      debugPrint('Gagal ambil booked slots: $e');
    }
  }

  Future<void> _checkVoucher() async {
    if (_selectedVoucher == null || _selectedVoucher!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kode voucher terlebih dahulu.')),
      );
      return;
    }

    setState(() {
      _checkingVoucher = true;
      _voucherMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    try {
      final result = await _apiService.validateVoucherCode(
        token: token!,
        voucherCode: _selectedVoucher!,
        orderAmount: _basePrice,
      );

      final discount = (result['discount'] ?? 0) as int;
      final finalTotal =
          (result['finalTotal'] ?? (_basePrice - discount)) as int;

      setState(() {
        _discount = discount;
        _finalPrice = finalTotal < 0 ? 0 : finalTotal;
        _appliedVoucherCode = result['voucherCode'] ?? _selectedVoucher;
        _voucherMessage = result['message'] ?? 'Voucher diterapkan.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voucher diterapkan: -${_formatCurrency(discount)}'),
        ),
      );
    } catch (e) {
      setState(() {
        _discount = 0;
        _finalPrice = _basePrice;
        _appliedVoucherCode = null;
        _voucherMessage = e.toString().replaceFirst('Exception: ', 'Gagal: ');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_voucherMessage!), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _checkingVoucher = false);
    }
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

      print('🎯 [BookingPage] Calling createOrderWithPayment...');
      final response = await _apiService.createOrderWithPayment(
        token: token,
        serviceId: widget.service.id,
        jadwalPerbaikan: schedule,
        catatan: 'Permintaan survei dulu ya kak!',
        voucherCode: _appliedVoucherCode,
      );

      print('🎯 [BookingPage] API Response received: $response');
      print('🎯 [BookingPage] Response type: ${response.runtimeType}');

      // Check if response is null
      if (response == null) {
        print('❌ [BookingPage] Response is null!');
        throw Exception('Server returned null response');
      }

      // Check if response is a Map
      if (response is! Map<String, dynamic>) {
        print('❌ [BookingPage] Response is not a Map: ${response.runtimeType}');
        throw Exception('Invalid response format from server');
      }

      print('🎯 [BookingPage] Response keys: ${response.keys.toList()}');

      final snapToken = response['snapToken'];
      print('🎯 [BookingPage] Snap Token: $snapToken');

      if (snapToken == null) {
        print('❌ [BookingPage] Snap token is null!');
        throw Exception('Payment token not received from server');
      }

      final snapRedirectUrl =
          "https://app.sandbox.midtrans.com/snap/v2/vtweb/$snapToken";

      print('🎯 [BookingPage] Redirect URL: $snapRedirectUrl');
      print('🎯 [BookingPage] Navigating to payment page...');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SnapPaymentPage(redirectUrl: snapRedirectUrl),
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
            'Gagal: ${e.toString().replaceFirst('Exception: ', '')}',
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
    await Future.wait([_loadBookedSlots(), _fetchVouchers()]);
  }

  @override
  Widget build(BuildContext context) {
    final isSurvey = widget.service.tipeLayanan == 'survey';

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
              if (!isSurvey) _buildVoucherSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(isSurvey),
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
        final isBooked = _bookedSlots.contains(slot);

        final match = RegExp(r'(\d{2})\.(\d{2})').firstMatch(slot);
        final slotHour = int.parse(match?.group(1) ?? '0');
        final slotMinute = int.parse(match?.group(2) ?? '0');
        final slotTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          slotHour,
          slotMinute,
        );

        final isPast = isToday && slotTime.isBefore(now);
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

  Widget _buildVoucherSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Voucher',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedVoucher,
          items: _vouchers.map((v) {
            final code = v['code'] as String;
            final discountType = v['discountType'];
            final value = v['value'];
            final label = discountType == 'percent'
                ? '$code • ${value}%'
                : '$code • ${_formatCurrency(value is int ? value : int.tryParse(value.toString()) ?? 0)}';
            return DropdownMenuItem<String>(value: code, child: Text(label));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedVoucher = value;
              _discount = 0;
              _finalPrice = _basePrice;
              _appliedVoucherCode = null;
              _voucherMessage = null;
            });
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Pilih voucher',
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _checkingVoucher ? null : _checkVoucher,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E232C),
            foregroundColor: Colors.white,
          ),
          child: _checkingVoucher
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Cek Voucher'),
        ),
        if (_appliedVoucherCode != null)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _appliedVoucherCode = null;
                _discount = 0;
                _finalPrice = _basePrice;
                _voucherMessage = 'Voucher dibatalkan.';
              });
            },
            icon: const Icon(Icons.close),
            label: const Text('Batalkan Voucher'),
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

  Widget _buildBottomBar(bool isSurvey) {
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Total Biaya', style: TextStyle(color: Colors.grey)),
                Text(
                  isSurvey ? 'Menunggu Penawaran' : _formatCurrency(totalPrice),
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
                    onPressed: _handleCreateOrder,
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
      ),
    );
  }
}
