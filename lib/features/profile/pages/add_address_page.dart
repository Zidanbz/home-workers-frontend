import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/state/auth_provider.dart';
import '../../../core/api/api_service.dart';

class AddAddressPage extends StatefulWidget {
  const AddAddressPage({super.key});

  @override
  State<AddAddressPage> createState() => _AddAddressPageState();
}

class _AddAddressPageState extends State<AddAddressPage> {
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  final ApiService _apiService = ApiService();

  // Ganti dengan API Key Anda
  final String _googleApiKey = "AIzaSyCRe7xfKI2OzPUp9pUWxR2QHH8zsdhoWTw";
  String _sessionToken = Uuid().v4();

  List<dynamic> _placePredictions = [];
  LatLng? _selectedLocation;
  bool _isLoading = false;

  static const CameraPosition _kMakassar = CameraPosition(
    target: LatLng(-5.147665, 119.432732),
    zoom: 12,
  );

  void _onSearchChanged(String input) {
    if (input.isNotEmpty) {
      _getPlacePredictions(input);
    } else {
      setState(() {
        _placePredictions = [];
      });
    }
  }

  Future<void> _getPlacePredictions(String input) async {
    String request =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_googleApiKey&sessiontoken=$_sessionToken&components=country:id';
    var response = await http.get(Uri.parse(request));
    if (response.statusCode == 200) {
      setState(() {
        _placePredictions = json.decode(response.body)['predictions'];
      });
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    String request =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleApiKey&sessiontoken=$_sessionToken';
    var response = await http.get(Uri.parse(request));
    if (response.statusCode == 200) {
      var details = json.decode(response.body)['result'];
      var location = details['geometry']['location'];

      setState(() {
        _selectedLocation = LatLng(location['lat'], location['lng']);
        _searchController.text = details['formatted_address'];
        _placePredictions = [];
      });

      final GoogleMapController controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _selectedLocation!, zoom: 17),
        ),
      );
      // Reset session token
      _sessionToken = Uuid().v4();
    }
  }

  Future<void> _handleSaveAddress() async {
    if (_labelController.text.isEmpty || _searchController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Label dan Alamat tidak boleh kosong.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await _apiService.addAddress(
        token: authProvider.token!,
        label: _labelController.text,
        fullAddress: _searchController.text,
        latitude: _selectedLocation?.latitude,
        longitude: _selectedLocation?.longitude,
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Alamat Baru')),
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              child: GoogleMap(
                // cloudMapId: "3c6dd06f72e67224fd6ccecb", // <-- TAMBAHKAN BARIS INI
                initialCameraPosition: _kMakassar,

                onMapCreated: (GoogleMapController controller) {
                  print("MAP CREATED ✅");
                  _mapController.complete(controller);
                },
                markers: _selectedLocation == null
                    ? {}
                    : {
                        Marker(
                          markerId: const MarkerId('selected-location'),
                          position: _selectedLocation!,
                        ),
                      },
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Cari alamat...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _placePredictions = [];
                              });
                            },
                          )
                        : null,
                  ),
                ),
                if (_placePredictions.isNotEmpty)
                  Container(
                    height: 200,
                    color: Colors.white,
                    child: ListView.builder(
                      itemCount: _placePredictions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_placePredictions[index]['description']),
                          onTap: () {
                            _getPlaceDetails(
                              _placePredictions[index]['place_id'],
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                TextField(
                  controller: _labelController,
                  decoration: InputDecoration(
                    hintText: 'Label Alamat (cth: Rumah, Kantor)',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _handleSaveAddress,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Simpan Alamat'),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
