import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final apiKey = 'AIzaSyDO20mxTPHOBLF5y9Yd89Kxjk26FGsDKXY';
  final origin = Uri.encodeComponent('Paris, France'); // Origine (adresse ou coordonnées géographiques)
  final destination = Uri.encodeComponent('Marseille, France'); // Destination (adresse ou coordonnées géographiques)

  final url = Uri.parse('https://maps.googleapis.com/maps/api/distancematrix/json?origins=$origin&destinations=$destination&key=$apiKey');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      if (json['status'] == 'OK') {
        final distanceText = json['rows'][0]['elements'][0]['distance']['text'];
        final distanceValue = json['rows'][0]['elements'][0]['distance']['value'];

        print('Distance entre $origin et $destination: $distanceText');
        print('Distance en mètres: $distanceValue');
      } else {
        print('Erreur: ${json['status']}');
      }
    } else {
      print('Erreur lors de la requête HTTP: ${response.statusCode}');
    }
  } catch (e) {
    print('Erreur lors de la récupération des données: $e');
  }
}
