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
  final _institutionController = TextEditingController();
  final _destinationController = TextEditingController();
  final _accountNameController = TextEditingController();

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

  @override
  void dispose() {
    _amountController.dispose();
    _institutionController.dispose();
    _destinationController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchWallet() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      final wallet = await ApiService().getMyWallet(token);
      if (!mounted) return;
      setState(() {
        _wallet = wallet;
        _isWalletLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _walletError = ApiService.readableError(
          e,
          action: 'Gagal memuat saldo',
        );
        _isWalletLoading = false;
      });
    }
  }

  Future<void> _submitWithdrawal() async {
    if (_wallet?.withdrawalBlocked == true ||
        (_wallet?.currentBalance ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _wallet?.withdrawalBlockedReason ??
                'Pencairan tidak tersedia karena saldo belum positif.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate() || _selectedType == null) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    try {
      await ApiService().requestWithdraw(
        token: token!,
        amount: int.parse(_amountController.text),
        destinationType: _selectedType!,
        institutionName: _institutionController.text.trim(),
        accountNumber: _destinationController.text.trim(),
        accountName: _accountNameController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permintaan tarik dana berhasil dikirim!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Kembali ke halaman sebelumnya
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ApiService.readableError(e, action: 'Gagal tarik dana'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF406882),
                ),
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
          if (_wallet?.withdrawalBlocked == true) ...[
            const SizedBox(height: 12),
            Text(
              _wallet!.withdrawalBlockedReason ?? 'Pencairan sedang diblokir.',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
                      if (value == null || value.isEmpty) {
                        return 'Masukkan jumlah';
                      }
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
                    initialValue: _selectedType,
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
                        _institutionController.clear();
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

                  TextFormField(
                    controller: _institutionController,
                    decoration: InputDecoration(
                      labelText: _selectedType == 'ewallet'
                          ? 'Provider E-Wallet'
                          : 'Nama Bank',
                      hintText: _selectedType == 'ewallet'
                          ? 'Contoh: DANA, OVO, GoPay'
                          : 'Contoh: BCA, BRI, Mandiri',
                      prefixIcon: Icon(
                        _selectedType == 'ewallet'
                            ? Icons.account_balance_wallet_outlined
                            : Icons.account_balance_outlined,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      final normalized = value?.trim() ?? '';
                      if (normalized.isEmpty) {
                        return _selectedType == 'ewallet'
                            ? 'Masukkan provider e-wallet'
                            : 'Masukkan nama bank';
                      }
                      if (normalized.length < 2) {
                        return 'Nama bank/provider terlalu pendek';
                      }
                      return null;
                    },
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
                      final normalized = value?.trim() ?? '';
                      if (normalized.isEmpty) {
                        return 'Masukkan nomor rekening atau e-wallet';
                      }
                      if (!RegExp(r'^\d{6,30}$').hasMatch(normalized)) {
                        return 'Nomor harus terdiri dari 6–30 digit';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _accountNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Pemilik',
                      hintText: 'Sesuai rekening atau akun e-wallet',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      final normalized = value?.trim() ?? '';
                      if (normalized.isEmpty) {
                        return 'Masukkan nama pemilik';
                      }
                      if (normalized.length < 2) {
                        return 'Nama pemilik terlalu pendek';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Tombol submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isLoading ||
                              _wallet?.withdrawalBlocked == true ||
                              (_wallet?.currentBalance ?? 0) <= 0
                          ? null
                          : _submitWithdrawal,
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
