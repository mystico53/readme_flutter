import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/app_config.dart';

class FirestoreService {
  Future<void> createFirestoreDocument(String fileId) async {
    try {
      final response = await http.post(
        AppConfig.createFirestoreDocumentUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'fileId': fileId}),
      );

      if (response.statusCode == 200) {
        print('Firestore document created with ID: $fileId');
      } else {
        print(
            'Error creating Firestore document. Status code: ${response.statusCode}');
        throw Exception('Failed to create Firestore document');
      }
    } catch (e) {
      print('Error creating Firestore document: $e');
      rethrow;
    }
  }
}
