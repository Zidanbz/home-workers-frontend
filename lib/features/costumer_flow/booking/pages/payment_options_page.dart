// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:midtrans_sdk/midtrans_sdk.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:provider/provider.dart';
// import '../../../../core/api/api_service.dart';
// import '../../../../core/state/auth_provider.dart';
// import 'payment_success_page.dart';

// class PaymentOptionsPage extends StatefulWidget {
//   final String orderId;
//   final num totalAmount;

//   const PaymentOptionsPage({
//     super.key,
//     required this.orderId,
//     required this.totalAmount,
//   });

//   @override
//   State<PaymentOptionsPage> createState() => _PaymentOptionsPageState();
// }

// class _PaymentOptionsPageState extends State<PaymentOptionsPage> {
//   String _selectedPaymentMethod = 'Dana';
//   bool _isLoading = false;
//   final ApiService _apiService = ApiService();

//   Future<void> _handleProcessPayment() async {
//     final scaffoldMessenger = ScaffoldMessenger.of(context);
//     final navigator = Navigator.of(context);
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);

//     setState(() => _isLoading = true);

//     try {
//       final token = authProvider.token;
//       if (token == null) throw Exception('Anda belum login.');

//       // Ambil snap token dari backend
//       final snapToken = await _apiService.createMidtransTransaction(
//         token: token,
//         orderId: widget.orderId,
//       );

//       if (snapToken == null || snapToken.isEmpty) {
//         throw Exception("Snap token kosong atau null.");
//       }

//       // Inisialisasi Midtrans SDK (panggil di dalam tombol, bukan initState)
//       final midtrans = await MidtransSDK.init(
//         config: MidtransConfig(
//           clientKey: dotenv.env['MIDTRANS_CLIENT_KEY']!,
//           merchantBaseUrl: dotenv.env['MIDTRANS_MERCHANT_BASE_URL']!,
//           enableLog: true,
//           colorTheme: ColorTheme(
//             colorPrimary: Theme.of(context).colorScheme.primary,
//             colorPrimaryDark: Theme.of(context).colorScheme.primary,
//             colorSecondary: Theme.of(context).colorScheme.secondary,
//           ),
//         ),
//       );

//       midtrans.setTransactionFinishedCallback((result) {
//         debugPrint('📦 Midtrans Result: ${result.status}');
//         if (result.status == "settlement") {
//           navigator.pushReplacement(
//             MaterialPageRoute(
//               builder: (context) => PaymentSuccessPage(
//                 paymentMethod: _selectedPaymentMethod,
//                 totalAmount: widget.totalAmount,
//               ),
//             ),
//           );
//         } else {
//           scaffoldMessenger.showSnackBar(
//             const SnackBar(content: Text('Transaksi dibatalkan atau gagal')),
//           );
//         }
//       });

//       // Mulai pembayaran di dalam APK
//       await midtrans.startPaymentUiFlow(token: snapToken);
//     } catch (e) {
//       debugPrint('❌ Midtrans SDK Error: $e');
//       scaffoldMessenger.showSnackBar(
//         SnackBar(
//           backgroundColor: Colors.red,
//           content: Text('Gagal: ${e.toString().replaceAll("Exception: ", "")}'),
//         ),
//       );
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F5),
//       appBar: AppBar(
//         title: const Text(
//           'Pilih Metode Pembayaran',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 1,
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(20.0),
//         children: [
//           const Text(
//             'Dompet Digital',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 12),
//           _buildPaymentOptionTile(
//             title: 'Dana',
//             logoAsset: 'assets/dana.png',
//             value: 'Dana',
//           ),
//           _buildPaymentOptionTile(
//             title: 'Gopay',
//             logoAsset: 'assets/gopay.png',
//             value: 'Gopay',
//           ),
//           _buildPaymentOptionTile(
//             title: 'Ovo',
//             logoAsset: 'assets/ovo.png',
//             value: 'Ovo',
//           ),
//         ],
//       ),
//       bottomNavigationBar: Container(
//         padding: const EdgeInsets.all(20.0),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
//           ],
//         ),
//         child: SafeArea(
//           child: _isLoading
//               ? const Center(child: CircularProgressIndicator())
//               : ElevatedButton.icon(
//                   onPressed: _handleProcessPayment,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF3A3F51),
//                     foregroundColor: Colors.white,
//                     minimumSize: const Size(double.infinity, 50),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   icon: const Icon(Icons.payment),
//                   label: const Text(
//                     'Bayar Sekarang',
//                     style: TextStyle(fontSize: 16),
//                   ),
//                 ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPaymentOptionTile({
//     required String title,
//     required String logoAsset,
//     required String value,
//     String? subtitle,
//   }) {
//     final isSelected = _selectedPaymentMethod == value;

//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       margin: const EdgeInsets.symmetric(vertical: 6),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: isSelected ? const Color(0xFF3A3F51) : Colors.grey.shade300,
//           width: 2,
//         ),
//         boxShadow: [
//           if (isSelected)
//             BoxShadow(
//               color: const Color(0xFF3A3F51).withOpacity(0.1),
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             ),
//         ],
//       ),
//       child: RadioListTile<String>(
//         value: value,
//         groupValue: _selectedPaymentMethod,
//         onChanged: (val) {
//           if (val != null) setState(() => _selectedPaymentMethod = val);
//         },
//         title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//         subtitle: subtitle != null ? Text(subtitle) : null,
//         secondary: Image.asset(logoAsset, width: 40, height: 40),
//         activeColor: const Color(0xFF3A3F51),
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//     );
//   }
// }
