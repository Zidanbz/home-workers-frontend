double customerDashboardBottomInset({
  required double bottomNavigationClearance,
  required double safeAreaBottom,
  double contentGap = 24,
}) {
  final navigationClearance = bottomNavigationClearance < 0
      ? 0.0
      : bottomNavigationClearance;
  final safeBottom = safeAreaBottom < 0 ? 0.0 : safeAreaBottom;
  final safeContentGap = contentGap < 0 ? 0.0 : contentGap;
  return navigationClearance + safeBottom + safeContentGap;
}
