import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/features/customer_flow/dashboard/utils/customer_dashboard_layout.dart';

void main() {
  test('bottom inset memakai clearance, safe area, dan jarak konten', () {
    expect(
      customerDashboardBottomInset(
        bottomNavigationClearance: 89,
        safeAreaBottom: 24,
      ),
      137,
    );
  });

  test('bottom inset menolak nilai layout negatif', () {
    expect(
      customerDashboardBottomInset(
        bottomNavigationClearance: -10,
        safeAreaBottom: -5,
        contentGap: -20,
      ),
      0,
    );
  });
}
