String buildPasswordResetConfirmation(String email) {
  final normalizedEmail = email.trim().toLowerCase();
  return 'Jika "$normalizedEmail" terdaftar sebagai akun Home Workers, link '
      'reset password akan dikirim.\n\n'
      'Periksa inbox atau folder spam Anda.';
}
