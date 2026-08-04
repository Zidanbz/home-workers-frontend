String? validateIndonesianWhatsApp(String? value) {
  final compact = (value ?? '').trim().replaceAll(RegExp(r'[\s().-]'), '');
  var digits = compact.replaceFirst(RegExp(r'^\+'), '');
  if (digits.startsWith('0')) digits = '62${digits.substring(1)}';
  if (!RegExp(r'^628\d{7,11}$').hasMatch(digits)) {
    return 'Masukkan nomor WhatsApp Indonesia yang valid (contoh: 081234567890)';
  }
  return null;
}
