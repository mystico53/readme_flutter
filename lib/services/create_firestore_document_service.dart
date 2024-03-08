import 'package:cloud_firestore/cloud_firestore.dart';
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

  void listenToAudioFileChanges(void Function(DocumentSnapshot) callback) {
    final audioFilesCollection =
        FirebaseFirestore.instance.collection('audioFiles');

    // Debug message to indicate that we're starting to listen to changes
    print("Listening to changes in audioFiles collection");

    audioFilesCollection.snapshots().listen((querySnapshot) {
      // Debug message to indicate that a snapshot has been received
      print(
          "Received a querySnapshot with ${querySnapshot.docChanges.length} changes");

      querySnapshot.docChanges.forEach((change) {
        // Debug message to log the type of change detected
        print(
            "Detected a ${change.type} change in document with ID: ${change.doc.id}");

        if (change.type == DocumentChangeType.added ||
            change.type == DocumentChangeType.modified) {
          // Debug message before invoking the callback
          print("Invoking callback for document with ID: ${change.doc.id}");
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
