import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/models/order_model.dart';

class RefundRequestSheet extends StatefulWidget {
  const RefundRequestSheet({
    super.key,
    required this.order,
    required this.onSubmit,
  });

  final Order order;
  final Future<void> Function({
    required String reasonCode,
    required String resolutionRequested,
    required String description,
    required String paymentTarget,
    required bool contactedWorker,
    required bool declarationAccepted,
    num? requestedAmount,
    required List<XFile> evidence,
  })
  onSubmit;

  @override
  State<RefundRequestSheet> createState() => _RefundRequestSheetState();
}

class _RefundRequestSheetState extends State<RefundRequestSheet> {
  static const _maxPhotos = 5;
  static const _maxPhotoBytes = 5 * 1024 * 1024;

  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _photos = [];

  String _reasonCode = 'worker_no_show';
  String _resolution = 'full_refund';
  late String _paymentTarget;
  bool _contactedWorker = false;
  bool _declarationAccepted = false;
  bool _submitting = false;
  int _currentStep = 0;
  String? _error;

  bool get _isSurvey => widget.order.serviceType.toLowerCase() == 'survey';

  bool get _hasFinalPayment => widget.order.finalPaymentStatus == 'paid';

  bool get _canRequestRework {
    final fullyPaid =
        widget.order.paymentStatus == 'paid' &&
        (!_isSurvey || _hasFinalPayment);
    final workStarted = {
      'work_in_progress',
      'completion_submitted',
    }.contains(widget.order.status);
    final hasBeforeEvidence =
        widget.order.workStartSubmission?.beforeEvidence.isNotEmpty == true;
    final hasPayout = widget.order.payoutStatus != null;
    return fullyPaid && workStarted && hasBeforeEvidence && !hasPayout;
  }

  bool get _evidenceRequired => {
    'work_not_as_agreed',
    'property_damage',
    'work_not_completed',
  }.contains(_reasonCode);

  bool get _shouldAskContactedWorker => !{
    'awaiting_payment',
    'pending',
    'worker_acceptance_expired',
  }.contains(widget.order.status);

  @override
  void initState() {
    super.initState();
    _paymentTarget = _isSurvey && _hasFinalPayment ? 'final_quote' : 'initial';
    if (_canRequestRework) {
      _reasonCode = 'work_not_as_agreed';
      _resolution = 'rework';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final photo = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (photo == null || !mounted) return;
      if (await photo.length() > _maxPhotoBytes) {
        setState(() => _error = 'Setiap foto maksimal 5 MB.');
        return;
      }
      setState(() {
        _photos.add(photo);
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Gagal memilih foto bukti.');
    }
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    if (description.length < 50) {
      setState(() => _error = 'Kronologi masalah minimal 50 karakter.');
      return;
    }
    if (_evidenceRequired && _photos.isEmpty) {
      setState(() => _error = 'Alasan ini membutuhkan minimal 1 foto bukti.');
      return;
    }
    num? amount;
    if (_resolution == 'partial_refund') {
      amount = num.tryParse(
        _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      );
      if (amount == null || amount <= 0) {
        setState(() => _error = 'Masukkan nominal refund sebagian.');
        return;
      }
    }
    if (!_declarationAccepted) {
      setState(() => _error = 'Setujui pernyataan kebenaran data.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
        reasonCode: _reasonCode,
        resolutionRequested: _resolution,
        description: description,
        paymentTarget: _paymentTarget,
        contactedWorker: _contactedWorker,
        declarationAccepted: _declarationAccepted,
        requestedAmount: amount,
        evidence: List<XFile>.unmodifiable(_photos),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;
    final sheetHeight = (maxHeight - bottomInset).clamp(440.0, maxHeight);
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: sheetHeight,
        decoration: const BoxDecoration(
          color: Color(0xFFF4F7F9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildStepIndicator(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: SingleChildScrollView(
                  key: ValueKey(_currentStep),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: switch (_currentStep) {
                    0 => _buildProblemStep(),
                    1 => _buildResolutionStep(),
                    _ => _buildConfirmationStep(),
                  },
                ),
              ),
            ),
            _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 14, 14),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD3DDE2),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEAE8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Color(0xFFB42318),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ajukan Refund',
                      style: TextStyle(
                        color: Color(0xFF1A374D),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Lengkapi informasi secara bertahap',
                      style: TextStyle(color: Color(0xFF6B7D87), fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _submitting ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    const labels = ['Masalah', 'Solusi & Bukti', 'Konfirmasi'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = index == _currentStep;
          final completed = index < _currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: active
                    ? const [
                        BoxShadow(
                          color: Color(0x0F1A374D),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (completed)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 15,
                      color: Color(0xFF16835D),
                    )
                  else
                    Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: active
                            ? const Color(0xFF1A374D)
                            : const Color(0xFF87959D),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      labels[index],
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active
                            ? const Color(0xFF1A374D)
                            : const Color(0xFF87959D),
                        fontSize: 10,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProblemStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(
          'Apa yang terjadi?',
          'Pilih transaksi dan jelaskan masalah dengan kronologi yang jelas.',
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<String>(
          initialValue: _paymentTarget,
          decoration: _inputDecoration(
            label: 'Transaksi',
            icon: Icons.receipt_long_outlined,
          ),
          items: [
            if (widget.order.paymentStatus == 'paid')
              DropdownMenuItem(
                value: 'initial',
                child: Text(
                  _isSurvey ? 'Biaya survei awal' : 'Pembayaran pesanan',
                ),
              ),
            if (_hasFinalPayment)
              const DropdownMenuItem(
                value: 'final_quote',
                child: Text('Pembayaran final'),
              ),
          ],
          onChanged: _submitting
              ? null
              : (value) => setState(() => _paymentTarget = value!),
        ),
        const SizedBox(height: 13),
        DropdownButtonFormField<String>(
          initialValue: _reasonCode,
          decoration: _inputDecoration(
            label: 'Jenis masalah',
            icon: Icons.report_problem_outlined,
          ),
          items: _reasonOptions
              .map(
                (option) =>
                    DropdownMenuItem(value: option.$1, child: Text(option.$2)),
              )
              .toList(),
          onChanged: _submitting
              ? null
              : (value) => setState(() => _reasonCode = value!),
        ),
        const SizedBox(height: 13),
        TextField(
          controller: _descriptionController,
          enabled: !_submitting,
          minLines: 5,
          maxLines: 7,
          maxLength: 2000,
          textCapitalization: TextCapitalization.sentences,
          decoration: _inputDecoration(
            label: 'Kronologi masalah',
            icon: Icons.notes_rounded,
            alignLabelWithHint: true,
            hint:
                'Ceritakan kapan masalah terjadi, apa yang sudah dilakukan, dan hasil yang Anda harapkan.',
          ),
        ),
        const SizedBox(height: 4),
        _infoBanner(
          icon: Icons.manage_search_rounded,
          text:
              'Admin akan mencocokkan kronologi dengan pembayaran dan aktivitas order.',
        ),
      ],
    );
  }

  Widget _buildResolutionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(
          'Pilih solusi',
          'Tentukan penyelesaian yang Anda harapkan dan lampirkan bukti bila diperlukan.',
        ),
        const SizedBox(height: 18),
        if (_canRequestRework) ...[
          _resolutionOption(
            value: 'rework',
            icon: Icons.handyman_outlined,
            title: 'Perbaikan ulang pekerjaan',
            subtitle: 'Worker memperbaiki hasil kerja sebelum dikonfirmasi.',
          ),
          const SizedBox(height: 10),
        ],
        _resolutionOption(
          value: 'partial_refund',
          icon: Icons.pie_chart_outline_rounded,
          title: 'Refund sebagian',
          subtitle: 'Pengembalian sebagian dari pembayaran.',
        ),
        const SizedBox(height: 10),
        _resolutionOption(
          value: 'full_refund',
          icon: Icons.currency_exchange_rounded,
          title: 'Refund penuh',
          subtitle: 'Pengembalian seluruh pembayaran terkait.',
        ),
        if (_resolution == 'partial_refund') ...[
          const SizedBox(height: 14),
          TextField(
            controller: _amountController,
            enabled: !_submitting,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(
              label: 'Nominal refund',
              icon: Icons.payments_outlined,
              prefix: 'Rp ',
            ),
          ),
        ],
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Bukti pendukung',
                style: TextStyle(
                  color: Color(0xFF1A374D),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${_photos.length}/$_maxPhotos foto',
              style: const TextStyle(color: Color(0xFF6B7D87), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _evidenceRequired
              ? 'Wajib minimal 1 foto untuk jenis masalah ini.'
              : 'Opsional, tetapi bukti dapat memperkuat pemeriksaan.',
          style: TextStyle(
            color: _evidenceRequired
                ? const Color(0xFFB42318)
                : const Color(0xFF6B7D87),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        if (_photos.isNotEmpty) ...[
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, index) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(_photos[index].path),
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 5,
                    top: 5,
                    child: IconButton.filled(
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.55),
                      ),
                      onPressed: _submitting
                          ? null
                          : () => setState(() => _photos.removeAt(index)),
                      icon: const Icon(Icons.close, size: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDCE5E9)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _photoButton(
                  icon: Icons.photo_camera_outlined,
                  label: 'Ambil Foto',
                  onTap: () => _pickPhoto(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _photoButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Dari Galeri',
                  onTap: () => _pickPhoto(ImageSource.gallery),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepTitle(
          'Periksa pengajuan',
          'Pastikan seluruh informasi sesuai sebelum dikirim untuk pemeriksaan Admin.',
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDCE5E9)),
          ),
          child: Column(
            children: [
              _summaryRow('Transaksi', _paymentTargetLabel),
              _summaryRow('Masalah', _reasonLabel),
              _summaryRow('Solusi', _resolutionLabel),
              if (_resolution == 'partial_refund')
                _summaryRow('Nominal', 'Rp ${_amountController.text.trim()}'),
              _summaryRow(
                'Bukti',
                _photos.isEmpty ? 'Tidak ada' : '${_photos.length} foto',
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _infoBanner(
          icon: Icons.info_outline_rounded,
          text:
              'Pengajuan akan diperiksa Admin dan tidak otomatis menghasilkan refund.',
        ),
        const SizedBox(height: 14),
        if (_shouldAskContactedWorker) ...[
          _agreementTile(
            value: _contactedWorker,
            title: 'Saya sudah mencoba menghubungi Worker.',
            onChanged: (value) => setState(() => _contactedWorker = value),
          ),
          const SizedBox(height: 10),
        ],
        _agreementTile(
          value: _declarationAccepted,
          title: 'Saya menyatakan data dan bukti yang dikirim adalah benar.',
          important: true,
          onChanged: (value) => setState(() => _declarationAccepted = value),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8EB))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEAE8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFB42318),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFB42318),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                if (_currentStep > 0) ...[
                  SizedBox(
                    width: 54,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _submitting ? null : _goBack,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: const Color(0xFF1A374D),
                        side: const BorderSide(color: Color(0xFFD6E0E4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: _submitting
                        ? null
                        : _currentStep == 2
                        ? _submit
                        : _goNext,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: const Color(0xFF1A374D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 21,
                            height: 21,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentStep == 2
                                    ? 'Kirim Pengajuan'
                                    : 'Lanjutkan',
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _currentStep == 2
                                    ? Icons.send_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 18,
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _goNext() {
    FocusScope.of(context).unfocus();
    String? error;
    if (_currentStep == 0 && _descriptionController.text.trim().length < 50) {
      error = 'Kronologi masalah minimal 50 karakter.';
    } else if (_currentStep == 1) {
      if (_evidenceRequired && _photos.isEmpty) {
        error = 'Tambahkan minimal satu foto bukti.';
      } else if (_resolution == 'partial_refund') {
        final amount = num.tryParse(
          _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        );
        if (amount == null || amount <= 0) {
          error = 'Masukkan nominal refund sebagian.';
        }
      }
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _error = null;
      _currentStep = (_currentStep + 1).clamp(0, 2);
    });
  }

  void _goBack() {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _currentStep = (_currentStep - 1).clamp(0, 2);
    });
  }

  Widget _stepTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1A374D),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF6B7D87),
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    String? prefix,
    bool alignLabelWithHint = false,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,
      prefixIcon: Icon(icon, size: 20),
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: Colors.white,
      border: border(const Color(0xFFDCE5E9)),
      enabledBorder: border(const Color(0xFFDCE5E9)),
      focusedBorder: border(const Color(0xFF2B6478), 1.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
    );
  }

  Widget _resolutionOption({
    required String value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _resolution == value;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: _submitting
          ? null
          : () => setState(() {
              _resolution = value;
              _error = null;
            }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF2F6) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF2B6478) : const Color(0xFFDCE5E9),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF2B6478)
                    : const Color(0xFFF0F3F5),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? Colors.white : const Color(0xFF6B7D87),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF1A374D),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B7D87),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? const Color(0xFF2B6478)
                  : const Color(0xFFB2BEC4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final enabled = !_submitting && _photos.length < _maxPhotos;
    return OutlinedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2B6478),
        side: const BorderSide(color: Color(0xFFD6E0E4)),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _infoBanner({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2F6),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2B6478), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF2B6478),
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _agreementTile({
    required bool value,
    required String title,
    required ValueChanged<bool> onChanged,
    bool important = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _submitting ? null : () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value
              ? important
                    ? const Color(0xFFE4F5EC)
                    : const Color(0xFFEAF2F6)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value
                ? important
                      ? const Color(0xFF86C9AD)
                      : const Color(0xFF9ABBC8)
                : const Color(0xFFDCE5E9),
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: _submitting
                  ? null
                  : (checked) => onChanged(checked ?? false),
              activeColor: important
                  ? const Color(0xFF16835D)
                  : const Color(0xFF2B6478),
            ),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1A374D),
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF6B7D87), fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF1A374D),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _paymentTargetLabel => _paymentTarget == 'final_quote'
      ? 'Pembayaran final'
      : _isSurvey
      ? 'Biaya survei awal'
      : 'Pembayaran pesanan';

  String get _reasonLabel => _reasonOptions
      .firstWhere(
        (option) => option.$1 == _reasonCode,
        orElse: () => ('other', 'Masalah lainnya'),
      )
      .$2;

  String get _resolutionLabel => switch (_resolution) {
    'rework' => 'Perbaikan ulang',
    'partial_refund' => 'Refund sebagian',
    _ => 'Refund penuh',
  };

  static const List<(String, String)> _reasonOptions = [
    ('worker_no_show', 'Worker tidak datang'),
    ('work_not_started', 'Pekerjaan belum dimulai'),
    ('worker_cancelled', 'Worker membatalkan'),
    ('work_not_as_agreed', 'Hasil tidak sesuai kesepakatan'),
    ('property_damage', 'Terjadi kerusakan'),
    ('work_not_completed', 'Pekerjaan belum selesai'),
    ('duplicate_payment', 'Pembayaran ganda'),
    ('wrong_amount', 'Nominal pembayaran salah'),
    ('other', 'Masalah lainnya'),
  ];
}
