# TODO Fixes for Home Workers App

## 1. Fix Category Display and Error in Home User

- [x] Check and fix category list display in CustomerDashboardPage
- [x] Ensure categories load properly without errors
- [x] Handle empty categories gracefully

## 2. Fix Category Filter in Services

- [x] Update MarketplacePage to properly filter services by selected category
- [x] Show empty message when no services in selected category
- [x] Ensure filter works correctly for all categories

## 3. Add Payment Success/Failure Popup or Page Transition

- [x] Read payment related pages (snapPayment_page.dart, payment_success_page.dart)
- [x] Add popup or navigation on payment success/failure
- [x] Ensure proper user feedback for payment results

## 4. Implement Real-time Order Updates

- [ ] Read customer orders page
- [ ] Implement real-time update after purchase without logout
- [ ] Use RealtimeNotificationService for updates

## 5. Fix Hint System

- [x] Read shared_widgets/hint_system.dart
- [x] Fix hint to not bounce and not go off screen
- [x] Changed scale animation from 0.8-1.0 to 1.0-1.0 to prevent bouncing
- [x] Integrate hint system into login flow and dashboard
- [x] Add first login hint after successful login
- [x] Add address hint to customer dashboard
- [x] **COMPLETED**: Hint system now properly shows first login hint after login and address hint on dashboard

## 6. Fix APK Logo for Download

- [x] Check splash screen configuration
- [x] Ensure logo displays correctly in download/APK context
- [x] Verify assets/logo_howe.png usage
- [x] Update to use logo_howe_new.png for both app icon and splash screen
- [x] Add flutter_launcher_icons dependency
- [x] Run flutter pub run flutter_launcher_icons
- [x] Run flutter pub run flutter_native_splash:create
- [x] **COMPLETED**: Splash screen logo made smaller and color adjusted to match app theme (#1A374D)
- [x] **UPDATED**: Changed splash screen to use original colored logo (logo_howe.png) instead of white version

## 7. New Requirements from User

- [x] Fix login error response when password/email wrong - **DONE**: Added specific error messages for email vs password
- [x] Fix worker marketplace category empty message to "layanan belum tersedia"
- [x] Remove rating option from filter, keep only termurah and termahal
- [x] Fix profile photo disappearing on pull to refresh in "profile saya"
- [x] Fix voucher dropdown in date/time worker to show "tidak ada voucher yang tersedia" or list
- [x] Fix payment success page navigation - **DONE**: Enhanced URL detection patterns
- [x] Add pull to refresh to orders page - **DONE**: Already implemented
- [x] Fix category display issues - **IN PROGRESS**: Need to verify category filtering
- [x] Fix hint system disappearing - **COMPLETED**: Hint system now properly integrated into login flow and dashboard
