# TODO - Voucher Feature Implementation

## Completed Tasks

### 1. Hide Voucher Section for "Cek Dulu" Payment Method (Booking Page)
- [x] Analyzed the booking page structure
- [x] Identified the issue with case-sensitive string matching
- [x] Updated the payment method check to be case-insensitive
- [x] Added `hasCekDulu` variable that uses `.any()` method with `.toLowerCase()` for robust checking
- [x] Added debug prints to track payment method detection

**File: `lib/features/costumer_flow/booking/pages/booking_page.dart`**

Changes:
1. Added case-insensitive check for "cek dulu" payment method:
   ```dart
   final hasCekDulu = widget.service.metodePembayaran.any(
     (method) => method.toString().toLowerCase().contains('cek dulu')
   );
   ```

2. Updated the voucher section condition:
   ```dart
   if (!isSurvey && !hasCekDulu) _buildVoucherSection()
   ```

3. Added debug prints to track detection:
   ```dart
   print('🔍 [BookingPage] Metode Pembayaran: ${widget.service.metodePembayaran}');
   print('🔍 [BookingPage] hasCekDulu: $hasCekDulu');
   ```

### 2. Add Voucher Feature to Order Detail Page (Quote Accepted Status)
- [x] Added voucher functionality to customer order detail page
- [x] Implemented voucher fetching for quote_accepted status
- [x] Added price card showing quoted price and discount
- [x] Added voucher selection dropdown
- [x] Implemented voucher validation
- [x] Updated payment flow to include voucher code
- [x] Fixed model compatibility (used `quotedPrice` instead of `proposedPrice`)

**File: `lib/features/costumer_flow/orders/pages/customer_order_detail_page.dart`**

Changes:
1. Added voucher state variables
2. Added `_fetchVouchers()` method to load available vouchers
3. Added `_validateAndApplyVoucher()` method for voucher validation
4. Added `_resetVoucher()` method to clear voucher selection
5. Added `_formatCurrency()` helper method
6. Created `_buildPriceCard()` widget to display:
   - Quoted price from worker
   - Discount amount (if voucher applied)
   - Final total after discount
7. Created `_buildVoucherSection()` widget with:
   - Voucher dropdown selection
   - Validation messages
   - Cancel voucher button
8. Updated `_handlePayment()` to pass `voucherCode` parameter
9. Added conditional rendering for quote_accepted status

**File: `lib/core/api/api_service.dart`**
- Already supports `voucherCode` parameter in `startPaymentForQuote()` method ✅

## How It Works

### Booking Page (Regular Services)
- Checks if service has "Cek Dulu" payment method (case-insensitive)
- Hides voucher section if payment method contains "cek dulu"
- Shows voucher section for regular payment methods

### Order Detail Page (Quote Accepted)
- Shows voucher section only when order status is `quote_accepted`
- Displays quoted price from worker
- Allows customer to select and apply voucher
- Validates voucher against quoted price
- Shows discount and final total
- Passes voucher code to payment API

## Testing Recommendations

### Booking Page
- [x] Test with service that has "Cashless" payment method (voucher should show)
- [ ] Test with service that has "Cek Dulu & Cashless" payment method (voucher should hide)
- [ ] Test with survey type services (voucher should hide)
- [ ] Verify case-insensitive matching works

### Order Detail Page
- [ ] Test with order in `quote_accepted` status
- [ ] Verify voucher list loads correctly
- [ ] Test voucher validation with valid voucher
- [ ] Test voucher validation with invalid voucher
- [ ] Test voucher validation with expired voucher
- [ ] Verify discount calculation is correct
- [ ] Test payment flow with applied voucher
- [ ] Test payment flow without voucher
- [ ] Verify voucher cancellation works
- [ ] Test with order in other statuses (voucher section should not show)

## Known Issues
- None currently

## Future Enhancements
- [ ] Add voucher suggestions based on order amount
- [ ] Show voucher savings summary
- [ ] Add voucher history/usage tracking
- [ ] Implement voucher auto-apply for best discount
