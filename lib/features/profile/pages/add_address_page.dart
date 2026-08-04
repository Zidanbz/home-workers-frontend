import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/state/auth_provider.dart';
import '../../../core/api/api_service.dart';
import '../../../core/services/reverse_geocoding_service.dart';

class AddAddressPage extends StatefulWidget {
  const AddAddressPage({super.key});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _labelFocusNode = FocusNode();
  final ApiService _apiService = ApiService();
  final ReverseGeocodingService _reverseGeocodingService =
      ReverseGeocodingService();

  static const Color _primaryColor = Color(0xFF1E232C);
  static const Color _secondaryTextColor = Color(0xFF667085);
  static const String _googleApiKeyFromDefine = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );
  String _sessionToken = Uuid().v4();

  List<dynamic> _placePredictions = [];
  LatLng? _selectedLocation;
  bool _isLoading = false;
  bool _isResolvingLocation = false;
  int _locationSelectionRevision = 0;

  static const CameraPosition _kMakassar = CameraPosition(
    target: LatLng(-5.147665, 119.432732),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleSearchFocusChanged);
  }

  void _handleSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  String get _googleApiKey {
    final keyFromDefine = _googleApiKeyFromDefine.trim();
    if (keyFromDefine.isNotEmpty) return keyFromDefine;
    return (dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '').trim();
  }

  void _onSearchChanged(String input) {
    final query = input.trim();
    _locationSelectionRevision++;
    setState(() {
      _selectedLocation = null;
      _isResolvingLocation = false;
      if (query.isEmpty) _placePredictions = [];
    });

    if (query.isNotEmpty) {
      _getPlacePredictions(query);
    } else {
      _placePredictions = [];
    }
  }

  Future<void> _getPlacePredictions(String input) async {
    final apiKey = _googleApiKey;
    if (apiKey.isEmpty) {
      debugPrint('GOOGLE_MAPS_API_KEY belum dikonfigurasi.');
      return;
    }

    final uri =
        Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
          'input': input,
          'key': apiKey,
          'sessiontoken': _sessionToken,
          'components': 'country:id',
        });
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      if (!mounted) return;
      if (_searchController.text.trim() != input) return;
      setState(() {
        _placePredictions = json.decode(response.body)['predictions'];
      });
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    final apiKey = _googleApiKey;
    if (apiKey.isEmpty) {
      debugPrint('GOOGLE_MAPS_API_KEY belum dikonfigurasi.');
      return;
    }

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
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      final body = json.decode(response.body);
      final details = body is Map ? body['result'] : null;
      if (response.statusCode != 200 || details is! Map) {
        throw StateError('Place detail tidak tersedia.');
      }
      final geometry = details['geometry'];
      final location = geometry is Map ? geometry['location'] : null;
      final latitude = location is Map ? (location['lat'] as num?) : null;
      final longitude = location is Map ? (location['lng'] as num?) : null;
      if (latitude == null || longitude == null) {
        throw StateError('Koordinat alamat tidak tersedia.');
      }

      final selectedLocation = LatLng(
        latitude.toDouble(),
        longitude.toDouble(),
      );
      if (!mounted || selectionRevision != _locationSelectionRevision) return;
      setState(() {
        _selectedLocation = selectedLocation;
        _searchController.text =
            details['formatted_address']?.toString().trim() ?? '';
        _placePredictions = [];
        _sessionToken = const Uuid().v4();
      });
      _searchFocusNode.unfocus();

      final controller = await _mapController.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(selectedLocation, 17),
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
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedLocation = point;
      _placePredictions = [];
      _searchController.text = 'Mencari alamat titik ini…';
      _isResolvingLocation = true;
    });

    final resolvedAddress = await _reverseGeocodingService.resolve(
      latitude: point.latitude,
      longitude: point.longitude,
    );
    if (!mounted || selectionRevision != _locationSelectionRevision) return;

    setState(() {
      _searchController.text =
          resolvedAddress ??
          ReverseGeocodingService.coordinateFallback(
            latitude: point.latitude,
            longitude: point.longitude,
          );
      _isResolvingLocation = false;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_handleSearchFocusChanged);
    _searchFocusNode.dispose();
    _labelFocusNode.dispose();
    _searchController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveAddress() async {
    if (_isResolvingLocation) {
      _showMessage('Tunggu alamat lokasi selesai diproses.');
      return;
    }

    final label = _labelController.text.trim();
    final address = _searchController.text.trim();

    if (label.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Label dan Alamat tidak boleh kosong.')),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cari alamat atau pilih titik langsung pada peta.'),
        ),
      );
      _searchFocusNode.requestFocus();
      return;
    }

    setState(() {
      _isLoading = true;
    });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null || token.isEmpty) {
      setState(() => _isLoading = false);
      _showMessage('Sesi Anda berakhir. Silakan login kembali.');
      return;
    }

    try {
      await _apiService.addAddress(
        token: token,
        label: label,
        fullAddress: address,
        latitude: _selectedLocation?.latitude,
        longitude: _selectedLocation?.longitude,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ApiService.readableError(e, action: 'Gagal menambahkan alamat'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchFocusNode.hasFocus;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Tambah Alamat',
          style: TextStyle(
            color: _primaryColor,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _primaryColor,
        elevation: 0,
      ),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: _kMakassar,
              padding: EdgeInsets.only(top: 92, bottom: isSearching ? 24 : 210),
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onTap: _selectMapPoint,
              onMapCreated: (GoogleMapController controller) {
                debugPrint('MAP CREATED');
                if (!_mapController.isCompleted) {
                  _mapController.complete(controller);
                }
              },
              markers: _selectedLocation == null
                  ? {}
                  : {
                      Marker(
                        markerId: const MarkerId('selected-location'),
                        position: _selectedLocation!,
                        draggable: true,
                        onDragEnd: _selectMapPoint,
                      ),
                    },
            ),
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Material(
                  color: Colors.white,
                  elevation: 6,
                  shadowColor: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Cari alamat atau lokasi',
                      hintStyle: const TextStyle(color: Color(0xFF98A2B3)),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: _primaryColor,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? _isResolvingLocation
                                ? const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    tooltip: 'Hapus pencarian',
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () {
                                      _locationSelectionRevision++;
                                      _searchController.clear();
                                      setState(() {
                                        _selectedLocation = null;
                                        _placePredictions = [];
                                        _isResolvingLocation = false;
                                      });
                                    },
                                  )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
                if (_placePredictions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Material(
                      color: Colors.white,
                      elevation: 8,
                      shadowColor: Colors.black.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: _placePredictions.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            indent: 52,
                            color: Color(0xFFEAECF0),
                          ),
                          itemBuilder: (context, index) {
                            final prediction = _placePredictions[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.location_on_outlined,
                                color: _primaryColor,
                              ),
                              title: Text(
                                prediction['description'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onTap: () {
                                _getPlaceDetails(prediction['place_id']);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!isSearching)
            Positioned(
              left: 16,
              right: 16,
              bottom: 0,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 16),
                child: Material(
                  color: Colors.white,
                  elevation: 12,
                  shadowColor: Colors.black.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detail alamat',
                          style: TextStyle(
                            color: _primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedLocation == null
                              ? 'Cari alamat atau ketuk titik langsung pada peta.'
                              : _isResolvingLocation
                              ? 'Sedang mencari alamat untuk titik yang dipilih…'
                              : 'Lokasi sudah dipilih. Marker dapat digeser untuk koreksi.',
                          style: TextStyle(
                            color: _selectedLocation == null
                                ? _secondaryTextColor
                                : const Color(0xFF16803C),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _labelController,
                          focusNode: _labelFocusNode,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (!_isLoading && !_isResolvingLocation) {
                              _handleSaveAddress();
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Contoh: Rumah, Kantor',
                            hintStyle: const TextStyle(
                              color: Color(0xFF98A2B3),
                            ),
                            prefixIcon: const Icon(Icons.label_outline_rounded),
                            filled: true,
                            fillColor: const Color(0xFFF7F8FA),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 15,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFEAECF0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: _primaryColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading || _isResolvingLocation
                                ? null
                                : _handleSaveAddress,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: _primaryColor.withValues(
                                alpha: 0.72,
                              ),
                              disabledForegroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: _isLoading
                                  ? const SizedBox(
                                      key: ValueKey('loading'),
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      key: ValueKey('label'),
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.save_outlined, size: 20),
                                        SizedBox(width: 10),
                                        Text(
                                          'Simpan Alamat',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
