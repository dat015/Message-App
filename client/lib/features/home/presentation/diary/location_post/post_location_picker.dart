import 'package:first_app/data/repositories/Map_Repo/map_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:first_app/PlatformClient/config.dart';
import 'package:http/http.dart' as http;

class LocationPicker extends StatefulWidget {
  final latlong.LatLng initialPosition;
  final Function(latlong.LatLng, String) onLocationSelected;

  const LocationPicker({
    Key? key,
    required this.initialPosition,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  _LocationPickerState createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late latlong.LatLng _selectedLocation;
  String? _selectedAddress;
  final LocationRepo _locationService = LocationRepo();
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialPosition;
    _getAddress();
  }

  // Hàm tạo URL tile với log
  String _getTileUrl(int zoom, int x, int y) {
    final apiKey = Config.geoapifyApiKey;
    final tileUrl = 'https://maps.geoapify.com/v1/tile/osm/bright/$zoom/$x/$y.png?apiKey=$apiKey';
    print('Tile URL generated: $tileUrl'); // Log URL hoàn chỉnh
    print('Tile parameters - Zoom: $zoom, X: $x, Y: $y, API Key: $apiKey'); // Log chi tiết tham số
    return tileUrl;
  }

  // Hàm kiểm tra tile với log
  Future<void> _fetchTile(int zoom, int x, int y) async {
    try {
      final url = _getTileUrl(zoom, x, y);
      final response = await http.get(Uri.parse(url));
      print('Tile fetch status: ${response.statusCode} - URL: $url'); // Log trạng thái và URL
      if (response.statusCode == 404) {
        print('Tile not found at $url - Possible invalid tile coordinates or API issue');
      } else if (response.statusCode != 200) {
        print('Unexpected status code: ${response.statusCode} for $url');
      }
    } catch (e) {
      print('Error fetching tile: $e - URL attempted: ${_getTileUrl(zoom, x, y)}'); // Log lỗi và URL
    }
  }

  // Hàm lấy địa chỉ với log
  Future<void> _getAddress() async {
    try {
      print('Fetching address for Lat: ${_selectedLocation.latitude}, Lng: ${_selectedLocation.longitude}');
      String? address = await _locationService.getAddressFromLatLng(
        _selectedLocation.latitude,
        _selectedLocation.longitude,
      );
      if (address != null) {
        print('Address fetched: $address');
        setState(() {
          _selectedAddress = address;
        });
      } else {
        print('No address returned for current location');
      }
    } catch (e) {
      print('Error fetching address: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Log khi render map để kiểm tra initial position
    print('Rendering map with initial position: Lat ${_selectedLocation.latitude}, Lng ${_selectedLocation.longitude}');

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation,
                initialZoom: 15,
                onTap: (tapPosition, point) async {
                  print('Map tapped at: Lat ${point.latitude}, Lng ${point.longitude}');
                  try {
                    String? address = await _locationService.getAddressFromLatLng(
                      point.latitude,
                      point.longitude,
                    );
                    if (address != null) {
                      print('Address updated to: $address');
                      setState(() {
                        _selectedLocation = point;
                        _selectedAddress = address;
                      });
                      _mapController.move(point, 15);
                    } else {
                      print('No address found for tapped location');
                    }
                  } catch (e) {
                    print('Error getting address on tap: $e');
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://maps.geoapify.com/v1/tile/osm/bright/{z}/{x}/{y}.png?apiKey=${Config.geoapifyApiKey}',
                  userAgentPackageName: 'com.example.app',
                  errorTileCallback: (tile, error, stackTrace) {
                    print('Tile error - Error: $error'); // Log lỗi từ tile
                    return null; // Không hiển thị tile lỗi
                  },
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: screenWidth * 0.02),
          Text(
            _selectedAddress ?? 'Đang tải địa chỉ...',
            style: TextStyle(fontSize: screenWidth * 0.04),
          ),
          SizedBox(height: screenWidth * 0.02),
          ElevatedButton(
            onPressed: () {
              print('Confirm button pressed - Location: Lat ${_selectedLocation.latitude}, Lng ${_selectedLocation.longitude}, Address: $_selectedAddress');
              if (_selectedAddress != null) {
                widget.onLocationSelected(_selectedLocation, _selectedAddress!);
                Navigator.pop(context);
              } else {
                print('No address selected, action cancelled');
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}