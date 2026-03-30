import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocalStorageService {
  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/user_data.json');
  }

  static Future<void> saveUser(Map<String, dynamic> userData) async {
    final file = await _getFile();
    await file.writeAsString(jsonEncode(userData));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final file = await _getFile();
    if (await file.exists()) {
      final content = await file.readAsString();
      return jsonDecode(content);
    }
    return null;
  }

  static Future<void> clearUser() async {
    final file = await _getFile();
    if (await file.exists()) {
      await file.delete();
    }
  }
}
