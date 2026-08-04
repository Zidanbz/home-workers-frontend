import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../core/models/operational_location_model.dart';
import '../../../core/services/reverse_geocoding_service.dart';

class OperationalLocationPickerPage extends StatefulWidget {
  const OperationalLocationPickerPage({super.key, this.initialValue});

  final OperationalLocation? initialValue;

  @override
  State<OperationalLocationPickerPage> createState() =>
      _OperationalLocationPickerPageState();
}

class _OperationalLocationPickerPageState
    extends State<OperationalLocationPickerPage> {
  static const Color _primary = Color(0xFF163B52);
  static const Color _accent = Color(0xFF0F8B78);
  static const CameraPosition _makassar = CameraPosition(
    target: LatLng(-5.147665, 119.432732),
    zoom: 12,
  );
  static const String _googleApiKeyFromDefine = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );
  static const List<int> _radiusOptions = [5, 10, 20, 30];

  final TextEditingController _searchController = TextEditingController();
  final ReverseGeocodingService _reverseGeocodingService =
      ReverseGeocodingService();
  GoogleMapController? _mapController;
  String _sessionToken = const Uuid().v4();
  Timer? _searchDebounce;
  List<Map<String, dynamic>> _predictions = [];
  LatLng? _selectedPoint;
  String _selectedAddress = '';
  int _selectedRadiusKm = 10;
  bool _isResolvingLocation = false;
  bool _hasLocationPermission = false;
  int _locationSelectionRevision = 0;

  String get _googleApiKey {
    final keyFromDefine = _googleApiKeyFromDefine.trim();
    if (keyFromDefine.isNotEmpty) return keyFromDefine;
    return (dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '').trim();
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    if (initial != null && initial.isValid) {
      _selectedPoint = LatLng(initial.latitude, initial.longitude);
      _selectedAddress = initial.areaLabel;
      _selectedRadiusKm = _radiusOptions.contains(initial.serviceRadiusKm)
          ? initial.serviceRadiusKm
          : 10;
      _searchController.text = initial.areaLabel;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final point = _selectedPoint;
    if (point != null) {
      controller.moveCamera(CameraUpdate.newLatLngZoom(point, 16));
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();
    if (query != _selectedAddress) {
      _locationSelectionRevision++;
      setState(() {
        _selectedPoint = null;
        _selectedAddress = '';
        _isResolvingLocation = false;
      });
    }
    if (query.isEmpty) {
      setState(() => _predictions = []);
      return;
    }
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _loadPredictions(query),
    );
  }

  Future<void> _loadPredictions(String query) async {
    final apiKey = _googleApiKey;
    if (apiKey.isEmpty) {
      _showMessage('Google Maps API key belum dikonfigurasi.');
      return;
    }

    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/autocomplete/json',
        {
          'input': query,
          'key': apiKey,
          'sessiontoken': _sessionToken,
          'components': 'country:id',
        },
      );
      final response = await http.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (!mounted || _searchController.text.trim() != query) return;
      if (response.statusCode != 200 || body['status'] == 'REQUEST_DENIED') {
        _showMessage('Pencarian alamat belum dapat digunakan.');
        return;
      }
      final values = body['predictions'] as List<dynamic>? ?? const [];
      setState(() {
        _predictions = values
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      });
    } catch (_) {
      if (mounted) _showMessage('Gagal mencari alamat. Periksa koneksi Anda.');
    }
  }

  Future<void> _selectPrediction(Map<String, dynamic> prediction) async {
    final placeId = prediction['place_id']?.toString();
    if (placeId == null || placeId.isEmpty) return;
    final apiKey = _googleApiKey;
    if (apiKey.isEmpty) return;

    final selectionRevision = ++_locationSelectionRevision;
    setState(() => _isResolvingLocation = true);
    try {
      final uri =
          Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
            'place_id': placeId,
            'key': apiKey,
            'sessiontoken': _sessionToken,
            'fields': 'formatted_address,geometry',
          });
      final response = await http.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final result = body['result'];
      if (response.statusCode != 200 || result is! Map) {
        throw StateError('Place detail tidak tersedia.');
      }
      final resultMap = Map<String, dynamic>.from(result);
      final geometry = Map<String, dynamic>.from(
        resultMap['geometry'] as Map? ?? const {},
      );
      final location = Map<String, dynamic>.from(
        geometry['location'] as Map? ?? const {},
      );
      final lat = (location['lat'] as num?)?.toDouble();
      final lng = (location['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) {
        throw StateError('Koordinat alamat tidak tersedia.');
      }
      final point = LatLng(lat, lng);
      final label =
          resultMap['formatted_address']?.toString().trim() ??
          prediction['description']?.toString().trim() ??
          '';
      if (!mounted || selectionRevision != _locationSelectionRevision) return;
      setState(() {
        _selectedPoint = point;
        _selectedAddress = label;
        _searchController.text = label;
        _predictions = [];
        _sessionToken = const Uuid().v4();
      });
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(point, 16),
      );
    } catch (_) {
      if (mounted && selectionRevision == _locationSelectionRevision) {
        _showMessage('Alamat tersebut belum dapat dipilih.');
      }
    } finally {
      if (mounted && selectionRevision == _locationSelectionRevision) {
        setState(() => _isResolvingLocation = false);
      }
    }
  }

  Future<void> _selectMapPoint(LatLng point) async {
    final selectionRevision = ++_locationSelectionRevision;
    setState(() {
      _selectedPoint = point;
      _selectedAddress = 'Mencari alamat titik ini…';
      _predictions = [];
      _isResolvingLocation = true;
    });
    final address = await _reverseGeocodingService.resolve(
      latitude: point.latitude,
      longitude: point.longitude,
    );
    if (!mounted || selectionRevision != _locationSelectionRevision) return;
    final fallback = ReverseGeocodingService.coordinateFallback(
      latitude: point.latitude,
      longitude: point.longitude,
    );
    setState(() {
      _selectedAddress = address ?? fallback;
      _searchController.text = _selectedAddress;
      _isResolvingLocation = false;
    });
  }

  Future<void> _useCurrentLocation() async {
    final selectionRevision = ++_locationSelectionRevision;
    setState(() => _isResolvingLocation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showMessage(
          'Layanan lokasi sedang nonaktif. Aktifkan GPS lalu coba lagi.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _showMessage(
          'Izin lokasi ditolak. Anda tetap dapat memilih alamat melalui peta.',
        );
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _showLocationSettingsMessage();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final point = LatLng(position.latitude, position.longitude);
      if (!mounted || selectionRevision != _locationSelectionRevision) return;
      setState(() {
        _hasLocationPermission = true;
        _selectedPoint = point;
      });
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(point, 16),
      );
      final address = await _reverseGeocodingService.resolve(
        latitude: point.latitude,
        longitude: point.longitude,
      );
      if (!mounted || selectionRevision != _locationSelectionRevision) return;
      final fallback =
          'Lokasi saat ini (${point.latitude.toStringAsFixed(5)}, '
          '${point.longitude.toStringAsFixed(5)})';
      setState(() {
        _selectedAddress = address ?? fallback;
        _searchController.text = _selectedAddress;
        _predictions = [];
      });
    } on TimeoutException {
      if (mounted) {
        _showMessage(
          'Lokasi belum ditemukan. Coba lagi atau pilih lewat peta.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Gagal mengambil lokasi. Pilih alamat melalui peta.');
      }
    } finally {
      if (mounted && selectionRevision == _locationSelectionRevision) {
        setState(() => _isResolvingLocation = false);
      }
    }
  }

  void _showLocationSettingsMessage() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: const Text(
          'Izin lokasi diblokir. Buka pengaturan atau pilih alamat lewat peta.',
        ),
        action: SnackBarAction(
          label: 'Pengaturan',
          onPressed: Geolocator.openAppSettings,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _save() {
    final point = _selectedPoint;
    final label = _selectedAddress.trim();
    if (point == null || label.isEmpty || _isResolvingLocation) {
      _showMessage('Pilih lokasi yang valid terlebih dahulu.');
      return;
    }
    Navigator.of(context).pop(
      OperationalLocation(
        areaLabel: label,
        latitude: point.latitude,
        longitude: point.longitude,
        serviceRadiusKm: _selectedRadiusKm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startPosition = _selectedPoint == null
        ? _makassar
        : CameraPosition(target: _selectedPoint!, zoom: 16);

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
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih titik awal jangkauan layanan',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Customer hanya melihat area dan perkiraan jarak, bukan titik '
                  'koordinat persis Anda.',
                  style: TextStyle(color: Color(0xFF6B7D87), height: 1.35),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isResolvingLocation
                        ? null
                        : _useCurrentLocation,
                    icon: const Icon(Icons.my_location_rounded),
                    label: const Text('Gunakan lokasi saat ini'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'atau cari secara manual',
                          style: TextStyle(color: Color(0xFF6B7D87)),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                ),
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Cari kecamatan, jalan, atau alamat',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _predictions = [];
                                _selectedPoint = null;
                                _selectedAddress = '';
                              });
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: const Color(0xFFF5F8FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFDCE5EA)),
                    ),
                  ),
                ),
                if (_predictions.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 170),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _predictions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final prediction = _predictions[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.location_on_outlined,
                            color: _accent,
                          ),
                          title: Text(
                            prediction['description']?.toString() ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectPrediction(prediction),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: startPosition,
                  onMapCreated: _onMapCreated,
                  onTap: _selectMapPoint,
                  myLocationEnabled: _hasLocationPermission,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  markers: _selectedPoint == null
                      ? const {}
                      : {
                          Marker(
                            markerId: const MarkerId('operational-location'),
                            position: _selectedPoint!,
                            draggable: true,
                            onDragEnd: _selectMapPoint,
                          ),
                        },
                ),
                const Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: IgnorePointer(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Icon(Icons.touch_app_outlined, color: _primary),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Anda juga dapat mengetuk peta untuk '
                                'menentukan titik.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isResolvingLocation)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x33FFFFFF),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              MediaQuery.paddingOf(context).bottom + 14,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A163B52),
                  blurRadius: 14,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.place_rounded, color: _accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedAddress.isEmpty
                            ? 'Belum ada lokasi dipilih'
                            : _selectedAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Radius layanan',
                  style: TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  children: _radiusOptions.map((radius) {
                    return ChoiceChip(
                      label: Text('$radius km'),
                      selected: _selectedRadiusKm == radius,
                      onSelected: (_) =>
                          setState(() => _selectedRadiusKm = radius),
                      selectedColor: const Color(0xFFDDF3EE),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Gunakan Area Ini'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
