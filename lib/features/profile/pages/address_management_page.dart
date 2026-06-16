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
  bool _isDeleting = false;

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

  Future<void> _deleteAddress(Address address) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Alamat'),
        content: Text(
          'Yakin ingin menghapus alamat "${address.label}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await _apiService.deleteAddress(token: token, addressId: address.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat berhasil dihapus.')),
      );
      _loadAddresses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ApiService.readableError(e, action: 'Gagal menghapus alamat'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
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
            return Center(
              child: Text(
                ApiService.readableError(
                  snapshot.error,
                  action: 'Gagal memuat alamat tersimpan',
                ),
              ),
            );
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
          return RefreshIndicator(
            onRefresh: () async {
              _loadAddresses();
              await _addressesFuture;
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
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
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      onPressed: _isDeleting
                          ? null
                          : () => _deleteAddress(address),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
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
