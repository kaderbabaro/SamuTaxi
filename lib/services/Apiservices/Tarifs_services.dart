import 'dart:convert';
import 'package:http/http.dart' as http;

class TarifService {
  static const String baseUrl = 'http://192.168.137.1:8000/api/tarif';

  Future<List<dynamic>> getTarifs() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load tarifs');
    }
  }

  Future<Map<String, dynamic>> getTarif(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load tarif');
    }
  }

  Future<void> createTarif(Map<String, dynamic> tarif) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(tarif),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create tarif');
    }
  }

  Future<void> updateTarif(int id, Map<String, dynamic> tarif) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(tarif),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update tarif');
    }
  }

  Future<void> deleteTarif(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete tarif');
    }
  }
}
