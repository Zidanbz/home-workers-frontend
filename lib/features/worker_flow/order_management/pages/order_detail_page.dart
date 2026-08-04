import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:home_workers_fe/shared_widgets/action_tap_guard.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/models/order_model.dart';
import '../../../../core/models/refund_model.dart';
import '../../../../core/models/warranty_model.dart';
import '../../../../core/state/auth_provider.dart';
import '../widgets/completion_submission_sheet.dart';
import '../widgets/refund_response_sheet.dart';
import '../../../../shared_widgets/refund_additional_evidence_sheet.dart';
import '../widgets/warranty_response_sheet.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final ApiService _apiService = ApiService();
  late Future<Order> _orderFuture;
  bool _isProcessing = false;
  RefundRequest? _refundRequest;
  OrderWarranty? _warranty;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      setState(() {
        _orderFuture = _loadOrderAndRefund(authProvider.token!);
      });
    }
  }

  Future<Order> _loadOrderAndRefund(String token) async {
    final results = await Future.wait<Object?>([
      _apiService.getOrderById(token: token, orderId: widget.orderId),
      _apiService.getOrderRefund(token: token, orderId: widget.orderId),
      _loadWarrantySafely(token),
    ]);
    _refundRequest = results[1] as RefundRequest?;
    _warranty = results[2] as OrderWarranty?;
    return results[0] as Order;
  }

  Future<OrderWarranty?> _loadWarrantySafely(String token) async {
    try {
      return await _apiService.getOrderWarranty(
        token: token,
        orderId: widget.orderId,
      );
    } catch (error) {
      debugPrint('Warranty data unavailable for ${widget.orderId}: $error');
      return null;
    }
  }

  Future<void> _handleRejectOrder() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin menolak pesanan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      await ActionTapGuard.run(context, () async {
        setState(() => _isProcessing = true);
        try {
          final token = authProvider.token!;
          await _apiService.rejectOrder(token: token, orderId: widget.orderId);
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text('Pesanan berhasil ditolak.'),
            ),
          );
          navigator.pop(); // Kembali ke halaman sebelumnya
        } catch (e) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                ApiService.readableError(e, action: 'Gagal menolak pesanan'),
              ),
            ),
          );
        } finally {
          if (mounted) setState(() => _isProcessing = false);
        }
      }, label: 'Memproses');
    }
  }

  Future<void> _handleAcceptOrder() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await ActionTapGuard.run(context, () async {
      setState(() => _isProcessing = true);

      try {
        final token = authProvider.token!;
        await _apiService.acceptOrder(token: token, orderId: widget.orderId);
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Pesanan berhasil diterima.'),
          ),
        );
        _loadOrderDetails();
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              ApiService.readableError(e, action: 'Gagal menerima pesanan'),
            ),
          ),
        );
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }, label: 'Memproses');
  }

  Future<void> _handleSendQuote(Order order) async {
    final TextEditingController priceController = TextEditingController();

    final result = await showDialog<num>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajukan Penawaran'),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Harga yang ditawarkan'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = num.tryParse(priceController.text);
              if (price != null) {
                Navigator.pop(context, price);
              }
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );

    if (result != null) {
      if (!mounted) return;
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      await ActionTapGuard.run(context, () async {
        setState(() => _isProcessing = true);
        try {
          await _apiService.proposeQuote(
            token: token,
            orderId: order.id,
            proposedPrice: result,
          );
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text('Penawaran berhasil dikirim.'),
            ),
          );
          _loadOrderDetails(); // Refresh
        } catch (e) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                ApiService.readableError(e, action: 'Gagal mengirim penawaran'),
              ),
            ),
          );
        } finally {
          if (mounted) setState(() => _isProcessing = false);
        }
      }, label: 'Mengirim');
    }
  }

  Future<void> _openCompletionSubmission(String orderId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (sheetContext) => CompletionSubmissionSheet(
        stage: WorkEvidenceStage.after,
        onSubmit: (note, evidence) => _apiService.submitOrderCompletion(
          token: token,
          orderId: orderId,
          note: note,
          evidencePaths: evidence.map((item) => item.path).toList(),
        ),
      ),
    );

    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            'Bukti berhasil dikirim. Menunggu konfirmasi Customer.',
          ),
        ),
      );
      await _loadOrderDetails();
    }
  }

  Future<void> _openWorkStartSubmission(String orderId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token;
    if (token == null) return;

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      builder: (sheetContext) => CompletionSubmissionSheet(
        stage: WorkEvidenceStage.before,
        onSubmit: (_, evidence) => _apiService.startOrderWork(
          token: token,
          orderId: orderId,
          evidencePaths: evidence.map((item) => item.path).toList(),
        ),
      ),
    );

    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Foto before tersimpan. Pekerjaan resmi dimulai.'),
        ),
      );
      await _loadOrderDetails();
    }
  }

  Future<void> _openDirections(Order order) async {
    if (order.coordinates == null) return;

    final lat = order.coordinates!.latitude;
    final lng = order.coordinates!.longitude;
    final directionsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    final opened = await launchUrl(
      directionsUrl,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka aplikasi peta.')),
      );
    }
  }

  Future<void> _openCustomerWhatsApp(Order order) async {
    final contact = order.customerContact;
    if (contact == null || contact.isEmpty) return;
    final digits = contact.replaceAll(RegExp(r'\D'), '');
    final message = Uri.encodeComponent(
      'Halo ${order.customerName}, saya Worker untuk pesanan ${order.serviceName}.',
    );
    final opened = await launchUrl(
      Uri.parse('https://wa.me/$digits?text=$message'),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka WhatsApp.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A374D),
        iconTheme: const IconThemeData(
          color:
              Colors.white, // <-- TAMBAHKAN INI UNTUK MEMBUAT PANAH JADI PUTIH
        ),
      ),
      body: FutureBuilder<Order>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                ApiService.readableError(
                  snapshot.error,
                  action: 'Gagal memuat detail pesanan',
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Detail pesanan tidak ditemukan.'));
          }

          final order = snapshot.data!;
          debugPrint('Status: ${order.status}');
          debugPrint('ServiceType: ${order.serviceType}');

          return RefreshIndicator(
            onRefresh: _loadOrderDetails,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSectionTitle('Informasi Customer'),
                _buildInfoCard(
                  children: [
                    _buildInfoRow(Icons.person_outline, order.customerName),
                    _buildInfoRow(
                      Icons.location_on_outlined,
                      order.customerAddress,
                    ),
                    if (order.customerContact?.isNotEmpty == true) ...[
                      _buildInfoRow(
                        Icons.phone_outlined,
                        order.customerContact!,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          key: const ValueKey('contact-customer-whatsapp'),
                          onPressed: () => _openCustomerWhatsApp(order),
                          icon: const Icon(Icons.chat_rounded),
                          label: const Text('Hubungi via WhatsApp'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF128C7E),
                            side: const BorderSide(color: Color(0xFF128C7E)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                _buildMapView(order),
                const SizedBox(height: 24),
                _buildSectionTitle('Detail Layanan'),
                _buildInfoCard(
                  children: [
                    _buildInfoRow(Icons.work_outline, order.serviceName),
                    _buildInfoRow(Icons.schedule, order.formattedSchedule),
                    _buildInfoRow(
                      Icons.receipt_long_outlined,
                      'Status: ${_getFormattedStatus(order.status)}',
                    ),
                    _buildInfoRow(
                      Icons.category_outlined,
                      'Tipe: ${order.serviceType}',
                    ),
                    if (order.status == 'quote_proposed')
                      _buildInfoRow(
                        Icons.monetization_on_outlined,
                        'Penawaran: Rp ${order.quotedPrice}',
                      ),
                  ],
                ),
                if (order.completionSubmission != null) ...[
                  const SizedBox(height: 24),
                  _buildCompletionSubmissionCard(order),
                ] else if (order.workStartSubmission != null) ...[
                  const SizedBox(height: 24),
                  _buildWorkStartSubmissionCard(order),
                ],
                if (_refundRequest != null) ...[
                  const SizedBox(height: 24),
                  _buildRefundCard(order),
                ],
                if (_warranty?.claim != null) ...[
                  const SizedBox(height: 24),
                  _buildWarrantyCard(order),
                ],
                const SizedBox(height: 40),
                if (_isProcessing)
                  const Center(child: CircularProgressIndicator())
                else
                  _buildActionButtons(order),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapView(Order order) {
    if (order.coordinates == null) {
      return const SizedBox.shrink();
    }

    final LatLng position = order.coordinates!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _buildSectionTitle('Lokasi Pengerjaan'),
        SizedBox(
          height: 250,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: position,
                zoom: 16.0,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('orderLocation'),
                  position: position,
                  infoWindow: InfoWindow(
                    title: order.customerName,
                    snippet: order.customerAddress,
                  ),
                ),
              },
              zoomControlsEnabled: true,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _openDirections(order),
            icon: const Icon(Icons.directions_rounded),
            label: const Text('Tunjukkan Arah'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A374D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Order order) {
    // 1. STATUS: pending => tampilkan Tolak / Terima
    if (order.status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _handleRejectOrder,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Tolak Pesanan'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _handleAcceptOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A374D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Terima Pesanan'),
            ),
          ),
        ],
      );
    }

    // 2. SURVEY: accepted || quote_proposed => Ajukan / Ubah Penawaran
    if ((order.status == 'accepted' || order.status == 'quote_proposed') &&
        order.serviceType == 'survey') {
      return ElevatedButton.icon(
        icon: const Icon(Icons.attach_money),
        label: Text(
          order.status == 'quote_proposed'
              ? 'Ubah Penawaran'
              : 'Ajukan Penawaran',
        ),
        onPressed: () => _handleSendQuote(order),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    // Order fixed lama wajib ikut flow foto before saat mulai.
    if (order.serviceType == 'fixed' && order.status == 'accepted') {
      return ElevatedButton.icon(
        icon: const Icon(Icons.photo_camera_outlined),
        label: const Text('Foto Before & Mulai Pengerjaan'),
        onPressed: () => _openWorkStartSubmission(order.id),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    // Fixed maupun survey masuk ke status ini setelah seluruh pembayaran siap.
    if (order.status == 'ready_to_start') {
      return ElevatedButton.icon(
        icon: const Icon(Icons.photo_camera_outlined),
        label: const Text('Foto Before & Mulai Pengerjaan'),
        onPressed: () => _openWorkStartSubmission(order.id),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    // 4. SURVEY: quote_accepted => bisa Mulai Pengerjaan
    if (order.status == 'quote_accepted') {
      if (order.finalPaymentStatus != 'paid') {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.payments_outlined, color: Colors.orange.shade800),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Menunggu Customer menyelesaikan pembayaran final.',
                ),
              ),
            ],
          ),
        );
      }
      return ElevatedButton.icon(
        icon: const Icon(Icons.photo_camera_outlined),
        label: const Text('Foto Before & Mulai Pengerjaan'),
        onPressed: () => _openWorkStartSubmission(order.id),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    // 5. work_in_progress => tombol Selesaikan Pekerjaan (umum)
    if (order.status == 'work_in_progress') {
      return ElevatedButton.icon(
        icon: const Icon(Icons.photo_camera_back_outlined),
        label: const Text('Foto After & Ajukan Selesai'),
        onPressed: () => _openCompletionSubmission(order.id),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    if (order.status == 'completion_submitted') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_top_rounded, color: Colors.orange.shade800),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Bukti sudah dikirim dan sedang menunggu konfirmasi Customer.',
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _openWarrantyResponse(WarrantyClaim claim) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WarrantyResponseSheet(
        onSubmit: (response, scheduledAt) => _apiService.respondToWarranty(
          token: token,
          claimId: claim.id,
          responseText: response,
          scheduledAt: scheduledAt,
        ),
      ),
    );
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jadwal perbaikan garansi berhasil dikirim.'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadOrderDetails();
    }
  }

  Future<void> _openWarrantyRepairEvidence(
    WarrantyClaim claim, {
    required bool isBefore,
  }) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CompletionSubmissionSheet(
        stage: isBefore ? WorkEvidenceStage.before : WorkEvidenceStage.after,
        onSubmit: (note, evidence) => isBefore
            ? _apiService.startWarrantyRepair(
                token: token,
                claimId: claim.id,
                evidencePaths: evidence.map((item) => item.path).toList(),
              )
            : _apiService.submitWarrantyRepair(
                token: token,
                claimId: claim.id,
                note: note,
                evidencePaths: evidence.map((item) => item.path).toList(),
              ),
      ),
    );
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBefore
                ? 'Perbaikan garansi berhasil dimulai.'
                : 'Hasil perbaikan dikirim kepada Customer.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      await _loadOrderDetails();
    }
  }

  Widget _buildWarrantyCard(Order order) {
    final claim = _warranty!.claim!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Garansi Pekerjaan'),
        _buildInfoCard(
          children: [
            _buildInfoRow(
              Icons.verified_user_outlined,
              'Status: ${claim.statusLabel}',
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(claim.description),
              ),
            ),
            if (claim.adminDecision?['reason'] != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Catatan Admin: ${claim.adminDecision!['reason']}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ),
            if (claim.status == 'awaiting_worker_response')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: FilledButton.icon(
                  onPressed: () => _openWarrantyResponse(claim),
                  icon: const Icon(Icons.event_available_outlined),
                  label: const Text('Tanggapi & Pilih Jadwal'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: const Color(0xFF1A374D),
                  ),
                ),
              )
            else if (claim.status == 'repair_scheduled')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: FilledButton.icon(
                  onPressed: () =>
                      _openWarrantyRepairEvidence(claim, isBefore: true),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Foto Before & Mulai Perbaikan'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: Colors.green.shade700,
                  ),
                ),
              )
            else if (claim.status == 'repair_in_progress')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: FilledButton.icon(
                  onPressed: () =>
                      _openWarrantyRepairEvidence(claim, isBefore: false),
                  icon: const Icon(Icons.photo_camera_back_outlined),
                  label: const Text('Foto After & Ajukan Selesai'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: Colors.blue.shade700,
                  ),
                ),
              )
            else if (claim.status == 'customer_confirmation')
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_top_rounded, color: Colors.blue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Hasil perbaikan sedang menunggu konfirmasi Customer.',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _openRefundResponse(RefundRequest refund) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RefundResponseSheet(
        onSubmit: (response, proposedResolution, evidence) =>
            _apiService.respondToRefund(
              token: token,
              refundId: refund.id,
              responseText: response,
              proposedResolution: proposedResolution,
              evidencePaths: evidence.map((item) => item.path).toList(),
            ),
      ),
    );
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggapan refund berhasil dikirim.'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadOrderDetails();
    }
  }

  Future<void> _openAdditionalRefundEvidence(RefundRequest refund) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    final instruction =
        refund.adminDecision?['reason']?.toString() ??
        'Admin meminta bukti tambahan untuk melanjutkan pemeriksaan.';
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RefundAdditionalEvidenceSheet(
        instruction: instruction,
        onSubmit: (note, evidence) =>
            _apiService.submitRefundAdditionalEvidence(
              token: token,
              refundId: refund.id,
              note: note,
              evidencePaths: evidence.map((item) => item.path).toList(),
            ),
      ),
    );
    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bukti tambahan berhasil dikirim.'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadOrderDetails();
    }
  }

  Widget _buildRefundCard(Order order) {
    final refund = _refundRequest!;
    final canRespond =
        refund.status == 'awaiting_worker_response' &&
        refund.workerResponse == null;
    final canAddEvidence =
        refund.status == 'more_evidence_required' &&
        refund.evidenceRequestedFrom == 'worker';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Komplain Customer'),
        _buildInfoCard(
          children: [
            _buildInfoRow(Icons.info_outline, 'Status: ${refund.statusLabel}'),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(refund.description),
              ),
            ),
            if (canRespond)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: FilledButton.icon(
                  onPressed: () => _openRefundResponse(refund),
                  icon: const Icon(Icons.reply_rounded),
                  label: const Text('Berikan Tanggapan'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: const Color(0xFF1A374D),
                  ),
                ),
              )
            else if (canAddEvidence)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: FilledButton.icon(
                  onPressed: () => _openAdditionalRefundEvidence(refund),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Lengkapi Bukti yang Diminta'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: const Color(0xFF1A374D),
                  ),
                ),
              )
            else if (refund.workerResponse != null)
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Tanggapan Anda sudah dikirim dan sedang ditinjau Admin.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletionSubmissionCard(Order order) {
    final submission = order.completionSubmission!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Bukti Before & After'),
        _buildInfoCard(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'BEFORE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.orange.shade800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildEvidenceGallery(
              order.workStartSubmission?.beforeEvidence ?? const [],
              emptyText: 'Foto before tidak tersedia untuk order lama.',
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'AFTER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.green.shade800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildEvidenceGallery(submission.afterEvidence),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                submission.note,
                style: const TextStyle(fontSize: 15, height: 1.4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkStartSubmissionCard(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Foto Before'),
        _buildInfoCard(
          children: [
            _buildEvidenceGallery(
              order.workStartSubmission?.beforeEvidence ?? const [],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEvidenceGallery(
    List<CompletionEvidence> evidence, {
    String emptyText = 'Foto tidak dapat dimuat.',
  }) {
    if (evidence.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(emptyText, style: TextStyle(color: Colors.grey.shade600)),
      );
    }
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: evidence.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final url = evidence[index].url;
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: url == null || url.isEmpty
                ? Container(
                    width: 100,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image_outlined),
                  )
                : Image.network(
                    url,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 100,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A374D),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1A374D), size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  String _getFormattedStatus(String status) {
    switch (status) {
      case 'quote_proposed':
        return 'Penawaran diajukan';
      case 'quote_rejected':
        return 'Penawaran ditolak';
      case 'quote_accepted':
        return 'Penawaran diterima';
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'accepted':
        return 'Diterima';
      case 'ready_to_start':
        return 'Siap Dimulai';
      case 'work_in_progress':
        return 'Sedang Dikerjakan';
      case 'completion_submitted':
        return 'Menunggu Konfirmasi Customer';
      case 'completed':
        return 'Selesai';
      case 'worker_acceptance_expired':
        return 'Batas penerimaan berakhir';
      default:
        return status;
    }
  }
}
