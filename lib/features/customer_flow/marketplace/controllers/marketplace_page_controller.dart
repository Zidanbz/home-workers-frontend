import 'package:flutter/foundation.dart';

/// Mengirim intent navigasi dari shell customer ke halaman marketplace yang
/// dipertahankan di dalam IndexedStack.
class MarketplacePageController extends ChangeNotifier {
  int _nearestRequestVersion = 0;

  int get nearestRequestVersion => _nearestRequestVersion;

  void showNearestServices() {
    _nearestRequestVersion += 1;
    notifyListeners();
  }
}
