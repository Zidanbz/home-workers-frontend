import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:home_workers_fe/core/api/api_service.dart';
import 'package:home_workers_fe/core/models/wallet_model.dart';
import 'package:home_workers_fe/core/state/auth_provider.dart';

class WorkerWithdrawPage extends StatefulWidget {
  const WorkerWithdrawPage({super.key});

  @override
  State<WorkerWithdrawPage> createState() => _WorkerWithdrawPageState();
}

class _WorkerWithdrawPageState extends State<WorkerWithdrawPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _destinationController = TextEditingController();

  String? _selectedType;
  bool _isLoading = false;

  final List<String> _destinationTypes = ['bank', 'ewallet'];

  // Saldo wallet
  Wallet? _wallet;
  bool _isWalletLoading = true;
  String? _walletError;

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  Future<void> _fetchWallet() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      final wallet = await ApiService().getMyWallet(token);
      setState(() {
        _wallet = wallet;
        _isWalletLoading = false;
      });
    } catch (e) {
      setState(() {
        _walletError = 'Gagal memuat saldo';
        _isWalletLoading = false;
      });
    }
  }

  Future<void> _submitWithdrawal() async {
    if (!_formKey.currentState!.validate() || _selectedType == null) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    try {
      await ApiService().requestWithdraw(
        token: token!,
        amount: int.parse(_amountController.text),
        destinationType: _selectedType!,
        destinationValue: _destinationController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permintaan tarik dana berhasil dikirim!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Kembali ke halaman sebelumnya
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal tarik dana: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildWalletBalance() {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    if (_isWalletLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_walletError != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(_walletError!, style: const TextStyle(color: Colors.red)),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF406882),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.account_balance_wallet, color: Color(0xFF406882)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saldo Tersedia',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                formatCurrency.format(_wallet?.currentBalance ?? 0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarik Dana'),
        backgroundColor: const Color(0xFF1A374D),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            _buildWalletBalance(),
            const Text(
              'Isi informasi berikut untuk menarik dana ke rekening atau dompet digital Anda.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Input jumlah
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah (Rp)',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Masukkan jumlah';
                      final number = int.tryParse(value);
                      if (number == null || number <= 0) {
                        return 'Jumlah harus lebih dari 0';
                      }
                      if (_wallet != null && number > _wallet!.currentBalance) {
                        return 'Saldo tidak mencukupi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Dropdown tujuan
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    items: _destinationTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          type == 'bank' ? 'Transfer Bank' : 'E-Wallet',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value;
                        _destinationController.clear();
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Jenis Tujuan',
                      prefixIcon: Icon(Icons.account_balance_wallet),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null ? 'Pilih jenis tujuan' : null,
                  ),
                  const SizedBox(height: 16),

                  // Input tujuan (rekening atau e-wallet)
                  TextFormField(
                    controller: _destinationController,
                    decoration: InputDecoration(
                      labelText: _selectedType == 'ewallet'
                          ? 'Nomor E-Wallet'
                          : 'Nomor Rekening Bank',
                      prefixIcon: const Icon(Icons.numbers),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Masukkan nomor rekening atau e-wallet';
                      }
                      if (value.length < 6) {
                        return 'Nomor terlalu pendek';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Tombol submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitWithdrawal,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        _isLoading ? 'Mengirim...' : 'Kirim Permintaan',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF1A374D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
