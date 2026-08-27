import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_service.dart';
import '../models/order_model.dart';
import '../state/auth_provider.dart';
import '../../features/customer_flow/orders/pages/customer_order_detail_page.dart';
import '../../features/worker_flow/order_management/pages/order_detail_page.dart';

class NotificationOrderDetailRoute extends StatelessWidget {
  const NotificationOrderDetailRoute({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.user?.role.toUpperCase() == 'WORKER') {
      return OrderDetailPage(orderId: orderId);
    }
    return _CustomerOrderLoader(orderId: orderId, token: auth.token);
  }
}

class _CustomerOrderLoader extends StatefulWidget {
  const _CustomerOrderLoader({required this.orderId, required this.token});

  final String orderId;
  final String? token;

  @override
  State<_CustomerOrderLoader> createState() => _CustomerOrderLoaderState();
}

class _CustomerOrderLoaderState extends State<_CustomerOrderLoader> {
  late final Future<Order> _orderFuture;

  @override
  void initState() {
    super.initState();
    final token = widget.token;
    _orderFuture = token == null
        ? Future<Order>.error('Sesi login tidak tersedia.')
        : ApiService().getOrderById(token: token, orderId: widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Order>(
      future: _orderFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return CustomerOrderDetailPage(initialOrder: snapshot.data!);
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Detail Pesanan')),
          body: Center(
            child: snapshot.hasError
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 42),
                        const SizedBox(height: 12),
                        const Text(
                          'Detail pesanan tidak dapat dibuka.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Kembali'),
                        ),
                      ],
                    ),
                  )
                : const CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
