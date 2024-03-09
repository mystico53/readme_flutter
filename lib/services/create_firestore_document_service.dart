import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/app_config.dart';

class FirestoreService {
  Future<void> createFirestoreDocument(String fileId, String status) async {
    print(
        'Attempting to create Firestore document with fileId: $fileId and status: $status'); // Debug before sending request

    try {
      final response = await http.post(
        AppConfig.createFirestoreDocumentUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fileId': fileId,
          'status': status,
        }),
      );

      // Debug print to log the response body. Helpful to understand the response from the server.
      print('Firestore document creation response body: ${response.body}');

      if (response.statusCode == 200) {
        // Assuming the server returns a success response when a document is created
        print('Document with fileId: $fileId successfully created.');
      } else {
        // If server response indicates failure (non-200 status code)
        print(
            'Failed to create document with fileId: $fileId. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Debug print to log any exceptions encountered during the HTTP request
      print('Exception occurred while creating Firestore document: $e');
    }
  }

  void listenToAudioFileChanges(void Function(DocumentSnapshot) callback) {
    final audioFilesCollection =
        FirebaseFirestore.instance.collection('audioFiles');

    // Debug message to indicate that we're starting to listen to changes

    audioFilesCollection.snapshots().listen((querySnapshot) {
      // Debug message to indicate that a snapshot has been received

      querySnapshot.docChanges.forEach((change) {
        // Debug message to log the type of change detected

        if (change.type == DocumentChangeType.added ||
            change.type == DocumentChangeType.modified) {
          // Debug message before invoking the callback

          callback(change.doc);
        }
      });
    }, onError: (error) {
      // Debug message to log any errors encountered during listening
      print("An error occurred while listening to changes: $error");
    });
  }

  Future<void> updateFirestoreDocumentStatus(
      String fileId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('audioFiles')
          .doc(fileId)
          .update({'status': status});
    } catch (e) {
      print('Error updating Firestore document status: $e');
    }
  }
}
