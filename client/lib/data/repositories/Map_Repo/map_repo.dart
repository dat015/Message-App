import 'package:first_app/PlatformClient/config.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart' as latlong;

class LocationRepo {
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Dịch vụ vị trí bị tắt');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Quyền truy cập vị trí bị từ chối');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Quyền truy cập vị trí bị từ chối vĩnh viễn');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<String?> getAddressFromLatLng(double lat, double lng) async {
    final apiKey = Config.geoapifyApiKey;
    final url =
        'https://maps.geoapify.com/v1/geocode/reverse?lat=$lat&lon=$lng&apiKey=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['features'][0]['properties']['formatted'] ??
            'Không tìm thấy địa chỉ';
      } else {
        throw Exception('Lỗi API: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi khi gọi Geoapify API: $e');
    }
  }

  Future<List<dynamic>> searchPlaces(
    String query, {
    double? lat,
    double? lng,
  }) async {
    final apiKey = Config.geoapifyApiKey;
    if (query.isEmpty) return [];

    final baseUrl = 'https://api.geoapify.com/v1/geocode/autocomplete';
    final locationBias =
        (lat != null && lng != null) ? '&bias=proximity:$lng,$lat' : '';
    final url = '$baseUrl?text=$query$locationBias&apiKey=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['features'] ?? [];
      } else {
        throw Exception('Lỗi API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi khi gọi Geoapify API: $e');
    }
  }

  Map<String, dynamic> selectPlace(Map<String, dynamic> place) {
    try {
      final coordinates = place['geometry']['coordinates'];
      final lat = coordinates[1] as double;
      final lng = coordinates[0] as double;
      final address =
          place['properties']['formatted'] as String? ?? 'Không có địa chỉ';

      return {'coordinates': latlong.LatLng(lat, lng), 'address': address};
    } catch (e) {
      throw Exception('Lỗi khi xử lý địa điểm: $e');
    }
  }
}
