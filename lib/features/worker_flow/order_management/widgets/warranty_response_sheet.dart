import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WarrantyResponseSheet extends StatefulWidget {
  const WarrantyResponseSheet({super.key, required this.onSubmit});

  final Future<void> Function(String response, DateTime scheduledAt) onSubmit;

  @override
  State<WarrantyResponseSheet> createState() => _WarrantyResponseSheetState();
}

class _WarrantyResponseSheetState extends State<WarrantyResponseSheet> {
  final _responseController = TextEditingController();
  DateTime? _scheduledAt;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _selectSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 14)),
      helpText: 'Tanggal perbaikan garansi',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Waktu perbaikan',
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(
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
    final response = _responseController.text.trim();
    if (response.length < 20) {
      setState(() => _error = 'Tanggapan minimal 20 karakter.');
      return;
    }
    if (_scheduledAt == null || !_scheduledAt!.isAfter(DateTime.now())) {
      setState(() => _error = 'Pilih jadwal perbaikan yang akan datang.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(response, _scheduledAt!);
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
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F7F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
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
                  color: const Color(0xFFD3DDE2),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Jadwalkan Perbaikan Garansi',
              style: TextStyle(
                color: Color(0xFF1A374D),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Berikan penjelasan dan jadwal kunjungan. Tanggapan ini akan dilihat Customer dan Admin.',
              style: TextStyle(color: Color(0xFF6B7D87), height: 1.4),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _responseController,
              enabled: !_submitting,
              minLines: 4,
              maxLines: 7,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Tanggapan Worker',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
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
                        _scheduledAt == null
                            ? 'Pilih jadwal kunjungan'
                            : DateFormat(
                                'EEEE, d MMM yyyy • HH:mm',
                                'id_ID',
                              ).format(_scheduledAt!),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Color(0xFFB42318))),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFF1A374D),
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
                  : const Icon(Icons.calendar_month_outlined),
              label: Text(_submitting ? 'Menyimpan...' : 'Simpan Jadwal'),
            ),
          ],
        ),
      ),
    );
  }
}
