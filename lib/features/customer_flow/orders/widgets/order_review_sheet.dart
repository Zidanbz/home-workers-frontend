import 'package:flutter/material.dart';

typedef ReviewSubmitter = Future<void> Function(int rating, String comment);

Future<bool> showOrderReviewSheet({
  required BuildContext context,
  required String serviceName,
  String? workerName,
  required ReviewSubmitter onSubmit,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OrderReviewSheet(
      serviceName: serviceName,
      workerName: workerName,
      onSubmit: onSubmit,
    ),
  );
  return result == true;
}

class _OrderReviewSheet extends StatefulWidget {
  const _OrderReviewSheet({
    required this.serviceName,
    required this.workerName,
    required this.onSubmit,
  });

  final String serviceName;
  final String? workerName;
  final ReviewSubmitter onSubmit;

  @override
  State<_OrderReviewSheet> createState() => _OrderReviewSheetState();
}

class _OrderReviewSheetState extends State<_OrderReviewSheet> {
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _submitting = false;
  String? _error;

  static const _labels = [
    '',
    'Kurang memuaskan',
    'Perlu perbaikan',
    'Cukup baik',
    'Sangat baik',
    'Luar biasa!',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0 || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_rating, _commentController.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8E0E5),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF4D6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFF6AE2D),
                  size: 38,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Bagaimana hasil pekerjaannya?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF173B4F),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.serviceName}${widget.workerName?.trim().isNotEmpty == true ? ' oleh ${widget.workerName}' : ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF667985), height: 1.4),
              ),
              const SizedBox(height: 18),
              Semantics(
                label: 'Pilih rating $_rating dari 5',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final value = index + 1;
                    return IconButton(
                      key: ValueKey('review-star-$value'),
                      tooltip: '$value bintang',
                      onPressed: _submitting
                          ? null
                          : () => setState(() => _rating = value),
                      iconSize: 39,
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 160),
                        child: Icon(
                          value <= _rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          key: ValueKey(value <= _rating),
                          color: const Color(0xFFF6AE2D),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  _labels[_rating],
                  key: ValueKey(_rating),
                  style: const TextStyle(
                    color: Color(0xFF9A6700),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _commentController,
                enabled: !_submitting,
                maxLength: 1000,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Ceritakan pengalaman Anda (opsional)',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: const Color(0xFFF5F8FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFDCE5EA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFDCE5EA)),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFB42318)),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('submit-review-button'),
                  onPressed: _rating == 0 || _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _submitting ? 'Mengirim ulasan...' : 'Kirim Ulasan',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF173B4F),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFD7E0E5),
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
