import 'dart:convert';
import 'package:http/http.dart' as http;

class CourseService {
  static const String baseUrl = 'http://192.168.137.1:8000/api/courses';

  Future<List<dynamic>> getCourses() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load courses');
    }
  }

  Future<Map<String, dynamic>> getCourse(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load course');
    }
  }

  Future<void> createCourse(Map<String, dynamic> course) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(course),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create course');
    }
  }

  Future<void> updateCourse(int id, Map<String, dynamic> course) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(course),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update course');
    }
  }

  Future<void> deleteCourse(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete course');
    }
  }
}
