import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/utils/payment_redirect_policy.dart';

void main() {
  group('parseTrustedMidtransRedirectUrl', () {
    test('accepts production and sandbox Snap HTTPS URLs', () {
      expect(
        parseTrustedMidtransRedirectUrl(
          'https://app.midtrans.com/snap/v4/redirection/payment-token',
        ),
        isNotNull,
      );
      expect(
        parseTrustedMidtransRedirectUrl(
          'https://app.sandbox.midtrans.com/snap/v2/vtweb/payment-token',
        ),
        isNotNull,
      );
    });

    test('rejects insecure and lookalike hosts', () {
      expect(
        parseTrustedMidtransRedirectUrl(
          'http://app.midtrans.com/snap/v4/redirection/token',
        ),
        isNull,
      );
      expect(
        parseTrustedMidtransRedirectUrl(
          'https://midtrans.com.attacker.example/snap/v4/redirection/token',
        ),
        isNull,
      );
      expect(
        parseTrustedMidtransRedirectUrl(
          'https://evilmidtrans.com/snap/v4/redirection/token',
        ),
        isNull,
      );
    });

    test('rejects credentials, non-standard ports, and non-Snap paths', () {
      expect(
        parseTrustedMidtransRedirectUrl(
          'https://user@app.midtrans.com/snap/v4/redirection/token',
        ),
        isNull,
      );
      expect(
        parseTrustedMidtransRedirectUrl(
          'https://app.midtrans.com:8443/snap/v4/redirection/token',
        ),
        isNull,
      );
      expect(
        parseTrustedMidtransRedirectUrl('https://app.midtrans.com/account'),
        isNull,
      );
    });
  });
}
