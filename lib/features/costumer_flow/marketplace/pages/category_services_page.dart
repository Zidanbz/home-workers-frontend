import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_workers_fe/features/costumer_flow/marketplace/widgets/service_card.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/state/auth_provider.dart';

class CategoryServicesPage extends StatefulWidget {
  final String categoryName;
  const CategoryServicesPage({super.key, required this.categoryName});

  @override
  State<CategoryServicesPage> createState() => _CategoryServicesPageState();
}

class _CategoryServicesPageState extends State<CategoryServicesPage> {
  final ApiService _apiService = ApiService();
  Future<List<Service>>? _servicesFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        setState(() {
          _servicesFuture = _apiService.getServicesByCategory(
            widget.categoryName,
            token,
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final token = Provider.of<AuthProvider>(context).token;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: token == null
          ? const Center(child: Text('Anda belum login.'))
          : _servicesFuture == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Service>>(
              future: _servicesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada layanan di kategori ini.'),
                  );
                }

                final services = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(20.0),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    return ServiceCard(service: services[index]);
                  },
                );
              },
            ),
    );
  }
}
