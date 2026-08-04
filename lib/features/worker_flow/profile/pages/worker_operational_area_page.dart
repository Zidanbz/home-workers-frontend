import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_service.dart';
import '../../../../core/models/operational_location_model.dart';
import '../../../../core/state/auth_provider.dart';
import '../../../location/pages/operational_location_picker_page.dart';

class WorkerOperationalAreaPage extends StatefulWidget {
  const WorkerOperationalAreaPage({super.key});

  @override
  State<WorkerOperationalAreaPage> createState() =>
      _WorkerOperationalAreaPageState();
}

class _WorkerOperationalAreaPageState extends State<WorkerOperationalAreaPage> {
  static const Color _primary = Color(0xFF163B52);
  static const Color _accent = Color(0xFF0F8B78);

  final ApiService _apiService = ApiService();
  OperationalLocation? _location;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      setState(() {
        _isLoading = false;
        _error = 'Sesi login tidak tersedia.';
      });
      return;
    }

    try {
      final profile = await _apiService.getMyWorkerProfile(token);
      final parsed = OperationalLocation.fromWorkerProfile(profile);
      if (!mounted) return;
      setState(() {
        _location = parsed.isValid ? parsed : null;
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = ApiService.readableError(
          error,
          action: 'Gagal memuat area operasional',
        );
      });
    }
  }

  Future<void> _chooseLocation() async {
    final result = await Navigator.of(context).push<OperationalLocation>(
      MaterialPageRoute(
        builder: (_) => OperationalLocationPickerPage(initialValue: _location),
      ),
    );
    if (result == null || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw StateError('Sesi login tidak tersedia.');
      await _apiService.updateMyWorkerProfile(
        token: token,
        dataToUpdate: {
          'operationalAreaLabel': result.areaLabel,
          'operationalLatitude': result.latitude,
          'operationalLongitude': result.longitude,
          'serviceRadiusKm': result.serviceRadiusKm,
        },
      );
      if (!mounted) return;
      setState(() => _location = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Area operasional berhasil diperbarui.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ApiService.readableError(
              error,
              action: 'Gagal memperbarui area operasional',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FA),
      appBar: AppBar(
        title: const Text(
          'Area Operasional',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        foregroundColor: _primary,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFDDE6EA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 26,
                        backgroundColor: Color(0xFFDDF3EE),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: _accent,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _location?.areaLabel ??
                            'Area operasional belum ditentukan',
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _location == null
                            ? 'Tentukan lokasi agar customer dapat menemukan '
                                  'layanan Anda berdasarkan jarak.'
                            : 'Radius layanan hingga '
                                  '${_location!.serviceRadiusKm} km',
                        style: const TextStyle(
                          color: Color(0xFF6B7D87),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _chooseLocation,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.edit_location_alt_outlined),
                          label: Text(
                            _location == null
                                ? 'Tentukan Area'
                                : 'Ubah Area dan Radius',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _primary,
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Card(
                  elevation: 0,
                  color: Color(0xFFEAF7F3),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, color: _accent),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Koordinat persis tidak ditampilkan kepada '
                            'customer. Perubahan ini berlaku untuk pencarian '
                            'layanan berikutnya dan tidak mengubah order aktif.',
                            style: TextStyle(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: _primary),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loadProfile,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
