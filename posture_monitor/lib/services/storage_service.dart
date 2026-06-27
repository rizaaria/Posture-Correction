import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/posture_data.dart';

class StorageService {
  static const String _fileName = 'posture_history.json';

  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<List<PostureData>> loadHistory() async {
    try {
      final file = await _getLocalFile();
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      if (contents.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((json) => PostureData.fromJson(json)).toList();
    } catch (e) {
      print('Error loading history: $e');
      return [];
    }
  }

  Future<void> saveHistory(List<PostureData> dataList) async {
    try {
      final file = await _getLocalFile();
      final List<Map<String, dynamic>> jsonList =
          dataList.map((item) => item.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      print('Error saving history: $e');
    }
  }
}
