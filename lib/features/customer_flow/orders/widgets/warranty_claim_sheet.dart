import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class WarrantyClaimSheet extends StatefulWidget {
  const WarrantyClaimSheet({super.key, required this.onSubmit});

  final Future<void> Function({
    required String issueType,
    required String description,
    required DateTime preferredVisitAt,
    required bool declarationAccepted,
    required List<XFile> evidence,
  })
  onSubmit;

  @override
  State<WarrantyClaimSheet> createState() => _WarrantyClaimSheetState();
}

class _WarrantyClaimSheetState extends State<WarrantyClaimSheet> {
  static const _maxPhotos = 5;
  static const _maxPhotoBytes = 5 * 1024 * 1024;
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _photos = [];

  String _issueType = 'same_issue';
  DateTime? _preferredVisitAt;
  bool _declarationAccepted = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _descriptionController.dispose();
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

  Future<void> _selectSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      helpText: 'Pilih tanggal kunjungan',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Pilih waktu kunjungan',
    );
    if (time == null) return;
    setState(() {
      _preferredVisitAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _error = null;
    });
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    if (description.length < 30) {
      setState(() => _error = 'Kronologi masalah minimal 30 karakter.');
      return;
    }
    if (_preferredVisitAt == null ||
        !_preferredVisitAt!.isAfter(DateTime.now())) {
      setState(() => _error = 'Pilih waktu kunjungan yang akan datang.');
      return;
    }
    if (_photos.isEmpty) {
      setState(() => _error = 'Unggah minimal satu foto masalah.');
      return;
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
        issueType: _issueType,
        description: description,
        preferredVisitAt: _preferredVisitAt!,
        declarationAccepted: true,
        evidence: List<XFile>.unmodifiable(_photos),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F7F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
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
                const SizedBox(height: 16),
                const Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFFE8F7EF),
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      child: SizedBox(
                        width: 46,
                        height: 46,
                        child: Icon(
                          Icons.verified_user_outlined,
                          color: Color(0xFF16835D),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ajukan Klaim Garansi',
                            style: TextStyle(
                              color: Color(0xFF1A374D),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Khusus masalah terkait pekerjaan awal',
                            style: TextStyle(
                              color: Color(0xFF6B7D87),
                              fontSize: 12,
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
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 18 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _issueType,
                    decoration: const InputDecoration(
                      labelText: 'Jenis masalah',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'same_issue',
                        child: Text('Masalah yang sama muncul kembali'),
                      ),
                      DropdownMenuItem(
                        value: 'workmanship',
                        child: Text('Kesalahan pengerjaan'),
                      ),
                      DropdownMenuItem(
                        value: 'damage_from_work',
                        child: Text('Kerusakan akibat pekerjaan'),
                      ),
                      DropdownMenuItem(
                        value: 'result_not_as_agreed',
                        child: Text('Hasil tidak sesuai kesepakatan'),
                      ),
                      DropdownMenuItem(
                        value: 'other',
                        child: Text('Lainnya terkait pekerjaan'),
                      ),
                    ],
                    onChanged: _submitting
                        ? null
                        : (value) => setState(() => _issueType = value!),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _descriptionController,
                    enabled: !_submitting,
                    minLines: 4,
                    maxLines: 7,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'Kronologi masalah',
                      hintText:
                          'Jelaskan kapan masalah muncul dan kaitannya dengan pekerjaan awal.',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: _submitting ? null : _selectSchedule,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFD3DDE2)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.event_available_outlined,
                            color: Color(0xFF2B6478),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _preferredVisitAt == null
                                  ? 'Pilih waktu kunjungan yang diinginkan'
                                  : DateFormat(
                                      'EEEE, d MMM yyyy • HH:mm',
                                      'id_ID',
                                    ).format(_preferredVisitAt!),
                              style: TextStyle(
                                color: _preferredVisitAt == null
                                    ? const Color(0xFF6B7D87)
                                    : const Color(0xFF1A374D),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_photos.isNotEmpty) ...[
                    SizedBox(
                      height: 88,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _photos.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_photos[index].path),
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              right: 2,
                              top: 2,
                              child: IconButton.filled(
                                visualDensity: VisualDensity.compact,
                                onPressed: _submitting
                                    ? null
                                    : () => setState(
                                        () => _photos.removeAt(index),
                                      ),
                                icon: const Icon(Icons.close, size: 15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _submitting || _photos.length >= _maxPhotos
                              ? null
                              : () => _pickPhoto(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Kamera'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _submitting || _photos.length >= _maxPhotos
                              ? null
                              : () => _pickPhoto(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text('Galeri (${_photos.length}/5)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _declarationAccepted,
                    enabled: !_submitting,
                    onChanged: (value) =>
                        setState(() => _declarationAccepted = value ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'Saya menyatakan masalah berkaitan dengan pekerjaan awal dan bukti yang dikirim adalah benar.',
                      style: TextStyle(fontSize: 13, height: 1.35),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFB42318)),
                    ),
                  ],
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      backgroundColor: const Color(0xFF1A374D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.shield_outlined),
                    label: Text(
                      _submitting ? 'Mengirim...' : 'Kirim Klaim Garansi',
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
}
