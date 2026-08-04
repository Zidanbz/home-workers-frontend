import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RefundAdditionalEvidenceSheet extends StatefulWidget {
  const RefundAdditionalEvidenceSheet({
    super.key,
    required this.instruction,
    required this.onSubmit,
  });

  final String instruction;
  final Future<void> Function(String note, List<XFile> evidence) onSubmit;

  @override
  State<RefundAdditionalEvidenceSheet> createState() =>
      _RefundAdditionalEvidenceSheetState();
}

class _RefundAdditionalEvidenceSheetState
    extends State<RefundAdditionalEvidenceSheet> {
  final _noteController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _photos = [];
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final photo = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (photo == null || !mounted) return;
    if (await photo.length() > 5 * 1024 * 1024) {
      setState(() => _error = 'Setiap foto maksimal 5 MB.');
      return;
    }
    setState(() {
      _photos.add(photo);
      _error = null;
    });
  }

  Future<void> _submit() async {
    final note = _noteController.text.trim();
    if (note.length < 10) {
      setState(() => _error = 'Keterangan minimal 10 karakter.');
      return;
    }
    if (_photos.isEmpty) {
      setState(() => _error = 'Unggah minimal satu foto bukti.');
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
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF4F7F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
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
              const Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFEAF2F6),
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Color(0xFF2B6478),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Lengkapi Bukti',
                      style: TextStyle(
                        color: Color(0xFF1A374D),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.instruction,
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                enabled: !_submitting,
                minLines: 3,
                maxLines: 6,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Keterangan bukti',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
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
                          borderRadius: BorderRadius.circular(10),
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
                                : () => setState(() => _photos.removeAt(index)),
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
                      onPressed: _submitting || _photos.length >= 5
                          ? null
                          : () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Kamera'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _submitting || _photos.length >= 5
                          ? null
                          : () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text('Galeri (${_photos.length}/5)'),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF1A374D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Kirim Bukti Tambahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
