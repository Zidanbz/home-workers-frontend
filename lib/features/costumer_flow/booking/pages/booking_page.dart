import 'package:flutter/material.dart';
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
  String _selectedFrequency = 'Layanan Sekali Saja';

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

      if (widget.service.tipeLayanan == 'fixed') {
        final response = await _apiService.createOrderWithPayment(
          token: token,
          serviceId: widget.service.id,
          jadwalPerbaikan: schedule,
        );

        final snapToken = response['snapToken'];
        final snapRedirectUrl =
            "https://app.sandbox.midtrans.com/snap/v2/vtweb/$snapToken";

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SnapPaymentPage(redirectUrl: snapRedirectUrl),
          ),
        );
      } else {
        // survey
        final response = await _apiService.createOrder(
          token: token,
          serviceId: widget.service.id,
          jadwalPerbaikan: schedule,
        );

        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Permintaan Berhasil Dikirim'),
            content: const Text(
              'Worker akan mengirimkan penawaran harga berdasarkan hasil survei. Mohon tunggu konfirmasi selanjutnya.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Kembali ke Beranda'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Gagal: ${e.toString().replaceAll('Exception: ', '')}'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWorkerInfo(),
            const SizedBox(height: 24),
            _buildFrequencySelector(),
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
          ],
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
          onPressed: () async {
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );
            final token = authProvider.token;
            final workerId = widget.service.workerInfo['id'];

            if (token == null || workerId == null) return;

            try {
              final workerData = await _apiService.getWorkerProfile(
                token: token,
                workerId: workerId,
              );
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkerProfilePage(workerInfo: workerData),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal membuka profil: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Lihat Profil >'),
        ),
      ],
    );
  }

  Widget _buildFrequencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seberapa sering Anda membutuhkan layanan ini?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedFrequency,
          items: ['Layanan Sekali Saja', 'Mingguan', 'Bulanan']
              .map(
                (label) => DropdownMenuItem(value: label, child: Text(label)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedFrequency = value);
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
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
            onTap: () => setState(() => _selectedDate = date),
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
    return Wrap(
      spacing: 12.0,
      runSpacing: 12.0,
      children: slots.map((slot) {
        final isSelected = _selectedTimeSlot == slot;
        return ChoiceChip(
          label: Text(slot),
          selected: isSelected,
          onSelected: (selected) =>
              setState(() => _selectedTimeSlot = selected ? slot : null),
          selectedColor: const Color(0xFF3A3F51),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar(bool isSurvey) {
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
                  isSurvey
                      ? 'Menunggu Penawaran'
                      : widget.service.formattedPrice,
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
