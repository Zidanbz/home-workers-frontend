import 'package:flutter/material.dart';
import 'package:home_workers_fe/features/profile/pages/add_address_page.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_service.dart';
import '../../../core/models/address_model.dart';
import '../../../core/state/auth_provider.dart';

class AddressManagementPage extends StatefulWidget {
  const AddressManagementPage({super.key});

  @override
  State<AddressManagementPage> createState() => _AddressManagementPageState();
}

class _AddressManagementPageState extends State<AddressManagementPage> {
  final ApiService _apiService = ApiService();
  late Future<List<Address>> _addressesFuture;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  void _loadAddresses() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      setState(() {
        _addressesFuture = _apiService.getMyAddresses(authProvider.token!);
      });
    } else {
      _addressesFuture = Future.error('Anda tidak terautentikasi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Alamat Tersimpan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<Address>>(
        future: _addressesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Anda belum memiliki alamat tersimpan.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final addresses = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.deepPurple,
                  ),
                  title: Text(
                    address.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(address.fullAddress),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      // TODO: Tampilkan opsi edit/hapus
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final result = Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (context) => const AddAddressPage()),
          );
          // Jika halaman tambah alamat kembali dengan nilai true, refresh daftar alamat
          if (result == true) {
            _loadAddresses();
          }
          // TODO: Navigasi ke halaman tambah alamat
        },
        label: const Text('Tambah Alamat'),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF1E232C),
        foregroundColor: Colors.white,
      ),
    );
  }
}
