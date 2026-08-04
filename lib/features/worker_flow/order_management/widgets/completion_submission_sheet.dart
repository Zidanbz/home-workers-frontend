import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/api/api_service.dart';

enum WorkEvidenceStage { before, after }

class CompletionSubmissionSheet extends StatefulWidget {
  const CompletionSubmissionSheet({
    super.key,
    required this.onSubmit,
    this.stage = WorkEvidenceStage.after,
  });

  final Future<void> Function(String note, List<XFile> evidence) onSubmit;
  final WorkEvidenceStage stage;

  @override
  State<CompletionSubmissionSheet> createState() =>
      _CompletionSubmissionSheetState();
}

class _CompletionSubmissionSheetState extends State<CompletionSubmissionSheet> {
  static const int _maxPhotos = 3;
  static const int _maxPhotoBytes = 5 * 1024 * 1024;

  final TextEditingController _noteController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _photos = [];
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool get _isBefore => widget.stage == WorkEvidenceStage.before;

  Future<void> _takePhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (picked == null || !mounted) return;

      if (await picked.length() > _maxPhotoBytes) {
        if (!mounted) return;
        setState(() {
          _error = 'Setiap foto maksimal 5 MB.';
        });
        return;
      }

      setState(() {
        _photos.add(picked);
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.readableError(error, action: 'Gagal memilih foto');
      });
    }
  }

  Future<void> _submit() async {
    final note = _noteController.text.trim();
    if (!_isBefore && note.length < 10) {
      setState(() {
        _error = 'Catatan penyelesaian minimal 10 karakter.';
      });
      return;
    }
    if (_photos.isEmpty) {
      setState(() {
        _error = _isBefore
            ? 'Ambil minimal 1 foto kondisi awal.'
            : 'Ambil minimal 1 foto hasil pekerjaan.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(note, List<XFile>.unmodifiable(_photos));
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.readableError(
          error,
          action: 'Gagal mengirim bukti',
        );
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isBefore ? 'Foto Before Pekerjaan' : 'Foto After Pekerjaan',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _isBefore
                  ? 'Ambil 1–3 foto kondisi awal di lokasi. Setelah terkirim, status pekerjaan akan dimulai.'
                  : 'Ambil 1–3 foto kondisi akhir. Customer akan membandingkannya dengan foto before sebelum pembayaran dicairkan.',
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
            ),
            if (!_isBefore) ...[
              const SizedBox(height: 20),
              TextField(
                controller: _noteController,
                minLines: 3,
                maxLines: 5,
                maxLength: 1000,
                enabled: !_submitting,
                decoration: const InputDecoration(
                  labelText: 'Catatan pekerjaan',
                  hintText:
                      'Jelaskan pekerjaan yang diselesaikan dan kondisi akhirnya.',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (_photos.isNotEmpty)
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final photo = _photos[index];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(photo.path),
                            width: 92,
                            height: 92,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Material(
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _submitting
                                  ? null
                                  : () => setState(() {
                                      _photos.removeAt(index);
                                    }),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            if (_photos.isNotEmpty) const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _submitting || _photos.length >= _maxPhotos
                  ? null
                  : _takePhoto,
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text('Ambil Foto (${_photos.length}/$_maxPhotos)'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _submitting
                    ? 'Mengirim bukti...'
                    : _isBefore
                    ? 'Simpan Before & Mulai Kerja'
                    : 'Kirim After untuk Dikonfirmasi',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: const Color(0xFF1A374D),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
