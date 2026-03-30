import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<List<LatLng>> getOsrmRoute(LatLng start, LatLng end) async {
  final url = Uri.parse(
      'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson');

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final coordinates = data['routes'][0]['geometry']['coordinates'] as List;

    return coordinates
        .map((coord) => LatLng(coord[1], coord[0])) // inverse lon/lat
        .toList();
  } else {
    print("Erreur OSRM: ${response.statusCode}");
    return [];
  }
}