import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

final CollectionReference audioFilesCollection =
    FirebaseFirestore.instance.collection('audioFiles');

class AudioFilesList extends StatelessWidget {
  final Function(String) onAudioSelected;

  AudioFilesList({required this.onAudioSelected});

  @override
  Widget build(BuildContext context) {
    CollectionReference audioFilesCollection =
        FirebaseFirestore.instance.collection('audioFiles');

    return StreamBuilder<QuerySnapshot>(
      stream: audioFilesCollection.snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text("Loading");
        }

        return ListView(
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            Map<String, dynamic> data = document.data() as Map<String, dynamic>;
            return ListTile(
              title: Text(document.id), // Displaying the document ID
              trailing: Row(
                mainAxisSize: MainAxisSize
                    .min, // This ensures the Row only takes as much space as needed
                children: [
                  IconButton(
                    icon: Icon(Icons.play_arrow),
                    onPressed: () {
                      onAudioSelected(data[
                          'httpsUrl']); // Call the function to play the audio
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      // Perform the delete operation
                      await FirebaseFirestore.instance
                          .collection('audioFiles')
                          .doc(document.id)
                          .delete();
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
