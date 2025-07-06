import 'package:flutter/material.dart';
import 'package:home_workers_fe/features/costumer_flow/booking/pages/payment_options_page.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/state/auth_provider.dart';
// Impor halaman pembayaran yang baru

class BookingPage extends StatefulWidget {
  final Service service;
  const BookingPage({super.key, required this.service});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // State untuk menyimpan pilihan pengguna
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  String _selectedFrequency = 'Layanan Sekali Saja';

  final List<String> _timeSlots = [
    'Pagi 09.00 - 11.00',
    'Siang 12.00 - 15.00',
    'Sore 16.00 - 18.00',
  ];

  // --- FUNGSI BARU UNTUK MEMBUAT PESANAN ---
  Future<void> _handleCreateOrder() async {
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih jam kerja terlebih dahulu.')),
      );
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      final token = authProvider.token;
      if (token == null) throw Exception('Authentication failed.');

      // Gabungkan tanggal dan waktu yang dipilih
      final hour = int.parse(_selectedTimeSlot!.substring(5, 7));
      final finalSchedule = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        hour,
      );

      // Panggil API untuk membuat pesanan
      final result = await _apiService.createOrder(
        token: token,
        serviceId: widget.service.id,
        jadwalPerbaikan: finalSchedule,
      );

      final orderId = result['data']['orderId'] as String;

      // Navigasi ke halaman pembayaran jika berhasil
      navigator.push(
        MaterialPageRoute(
          builder: (context) => PaymentOptionsPage(
            orderId: orderId,
            totalAmount: widget.service.harga,
          ),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Gagal: ${e.toString().replaceAll("Exception: ", "")}'),
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
              'Kapan Anda menginginkan layanan Anda?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildDatePicker(),
            const SizedBox(height: 24),
            const Text(
              'Jam berapa Anda ingin kami mulai?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildTimeSlotPicker(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
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
        TextButton(onPressed: () {}, child: const Text('Lihat Profil >')),
      ],
    );
  }

  Widget _buildFrequencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seberapa sering Anda membutuhkan ini?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedFrequency,
          items: ['Layanan Sekali Saja', 'Mingguan', 'Bulanan']
              .map(
                (label) => DropdownMenuItem(child: Text(label), value: label),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedFrequency = value;
              });
            }
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
        itemCount: 7, // Tampilkan 7 hari ke depan
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final bool isSelected = DateUtils.isSameDay(_selectedDate, date);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
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
                    DateFormat('EEE', 'id_ID').format(date), // Hari (Sen, Sel)
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
    return Wrap(
      spacing: 12.0,
      runSpacing: 12.0,
      children: _timeSlots.map((slot) {
        final bool isSelected = _selectedTimeSlot == slot;
        return ChoiceChip(
          label: Text(slot),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedTimeSlot = selected ? slot : null;
            });
          },
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

  Widget _buildBottomBar() {
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
                  widget.service.formattedPrice,
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
                    onPressed: _handleCreateOrder, // Panggil fungsi yang baru
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E232C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                    child: const Text('Lanjut ke Pembayaran'),
                  ),
          ],
        ),
      ),
    );
  }
}
