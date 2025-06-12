import 'package:first_app/data/repositories/Map_Repo/map_repo.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlong;

class PlacePickerScreen extends StatefulWidget {
  final LocationRepo locationService;
  final Function(latlong.LatLng, String) onLocationSelected;

  const PlacePickerScreen({
    Key? key,
    required this.locationService,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  _PlacePickerScreenState createState() => _PlacePickerScreenState();
}

class _PlacePickerScreenState extends State<PlacePickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _places = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    try {
      Position? position = await widget.locationService.getCurrentLocation();
      final places = await widget.locationService.searchPlaces(
        query,
        lat: position?.latitude,
        lng: position?.longitude,
      );
      setState(() {
        _places = places;
        print('Places found: $_places'); // Debug log
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tìm kiếm địa điểm: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn vị trí')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm địa điểm',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchPlaces(_searchController.text),
                ),
              ),
              onSubmitted: _searchPlaces,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _places.length,
              itemBuilder: (context, index) {
                var place = _places[index];
                return ListTile(
                  title: Text(place['properties']['name'] ?? 'Không có tên'),
                  subtitle: Text(place['properties']['formatted'] ?? ''),
                  onTap: () {
                    final selected = widget.locationService.selectPlace(place);
                    widget.onLocationSelected(
                      selected['coordinates'] as latlong.LatLng,
                      selected['address'] as String,
                    );
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}