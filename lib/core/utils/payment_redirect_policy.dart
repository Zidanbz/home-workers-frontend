Uri? parseTrustedMidtransRedirectUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      uri.scheme.toLowerCase() != 'https' ||
      !uri.hasAuthority ||
      uri.userInfo.isNotEmpty) {
    return null;
  }

  final host = uri.host.toLowerCase();
  final isMidtransHost =
      host == 'midtrans.com' || host.endsWith('.midtrans.com');
  if (!isMidtransHost || (uri.hasPort && uri.port != 443)) {
    return null;
  }

  // Snap redirect URLs currently use /snap/v*/redirection or /snap/v*/vtweb.
  // Restrict the externally opened URL to that payment surface.
  if (!uri.path.toLowerCase().startsWith('/snap/')) {
    return null;
  }

  return uri;
}
