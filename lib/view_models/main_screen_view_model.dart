import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MainScreenViewModel with ChangeNotifier {
  MainScreenViewModel(this.userId) {
    listenToFirestoreChanges();
  }

  final String userId;
  List<DocumentSnapshot> _documents = [];

  List<DocumentSnapshot> get documents => _documents;

  void listenToFirestoreChanges() {
    final audioFilesCollection = FirebaseFirestore.instance
        .collection('audioFiles')
        .where('userId', isEqualTo: userId);

    audioFilesCollection.snapshots().listen(
      (querySnapshot) {
        _documents = querySnapshot.docs;
        notifyListeners();
      },
      onError: (error) {
        print("An error occurred while listening to changes: $error");
      },
    );
  }
}
