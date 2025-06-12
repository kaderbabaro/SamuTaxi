import 'dart:convert';
import 'package:http/http.dart' as http;

class AbonnementService {
  static const String baseUrl = 'http://192.168.137.1:8000/api/abonnements';

  Future<List<dynamic>> getAbonnements() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load abonnements');
    }
  }

  Future<Map<String, dynamic>> getAbonnement(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load abonnement');
    }
  }

  Future<void> createAbonnement(Map<String, dynamic> abonnement) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(abonnement),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create abonnement');
    }
  }

  Future<void> deleteAbonnement(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete abonnement');
    }
  }
}
