import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RefundResponseSheet extends StatefulWidget {
  const RefundResponseSheet({super.key, required this.onSubmit});

  final Future<void> Function(
    String response,
    String proposedResolution,
    List<XFile> evidence,
  )
  onSubmit;

  @override
  State<RefundResponseSheet> createState() => _RefundResponseSheetState();
}

class _RefundResponseSheetState extends State<RefundResponseSheet> {
  final _responseController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _photos = [];
  String _resolution = 'rework';
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _responseController.dispose();
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
    final response = _responseController.text.trim();
    if (response.length < 20) {
      setState(() => _error = 'Tanggapan minimal 20 karakter.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
        response,
        _resolution,
        List<XFile>.unmodifiable(_photos),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tanggapi Komplain',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Berikan penjelasan faktual. Admin akan membandingkannya dengan bukti Customer serta foto before/after.',
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _resolution,
              decoration: const InputDecoration(
                labelText: 'Usulan penyelesaian',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'rework',
                  child: Text('Bersedia memperbaiki'),
                ),
                DropdownMenuItem(
                  value: 'partial_refund',
                  child: Text('Setuju refund sebagian'),
                ),
                DropdownMenuItem(
                  value: 'full_refund',
                  child: Text('Setuju refund penuh'),
                ),
                DropdownMenuItem(
                  value: 'reject_claim',
                  child: Text('Menolak klaim'),
                ),
              ],
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _resolution = value!),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _responseController,
              enabled: !_submitting,
              minLines: 4,
              maxLines: 7,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Penjelasan Worker',
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
                  : const Text('Kirim Tanggapan'),
            ),
          ],
        ),
      ),
    );
  }
}
