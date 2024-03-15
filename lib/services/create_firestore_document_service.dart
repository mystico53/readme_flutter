import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/app_config.dart';

class FirestoreService {
  Future<void> createFirestoreDocument(
    String fileId,
    String status,
    String userId,
  ) async {
    print(
        'Attempting to create Firestore document with fileId: $fileId, status: $status, and userId: $userId');

    try {
      final response = await http.post(
        AppConfig.createFirestoreDocumentUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fileId': fileId,
          'status': status,
          'userId': userId,
        }),
      );

      print('Firestore document creation response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Document with fileId: $fileId successfully created.');
      } else {
        print(
            'Failed to create document with fileId: $fileId. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception occurred while creating Firestore document: $e');
    }
  }

  void listenToAudioFileChanges(
    String userId,
    void Function(DocumentSnapshot) callback,
  ) {
    final audioFilesCollection = FirebaseFirestore.instance
        .collection('audioFiles')
        .where('userId', isEqualTo: userId);

    audioFilesCollection.snapshots().listen(
      (querySnapshot) {
        querySnapshot.docChanges.forEach((change) {
          if (change.type == DocumentChangeType.added ||
              change.type == DocumentChangeType.modified) {
            callback(change.doc);
          }
        });
      },
      onError: (error) {
        print("An error occurred while listening to changes: $error");
      },
    );
  }

  Future<void> updateFirestoreDocumentStatus(
    String fileId,
    String status,
    String userId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('audioFiles')
          .doc(fileId)
          .update({
        'status': status,
        'userId': userId,
      });
    } catch (e) {
      print('Error updating Firestore document status: $e');
    }
  }
}
