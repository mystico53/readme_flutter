import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/generate_dialog_viewmodel.dart';
import '../view_models/intent_viewmodel.dart';
import '../views/generate_dialog.dart';
import '../widgets/audio_player_widget.dart';
import 'package:intl/intl.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  String userId = '';
  String sharedContent = "";
  bool isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    final intentViewModel =
        Provider.of<IntentViewModel>(context, listen: false);
    intentViewModel.addListener(_handleIntentViewModelChange);
  }

  void checkForSharedFiles() {
    print("checkForSharedFiles started");
    final intentViewModel =
        Provider.of<IntentViewModel>(context, listen: false);
    if (intentViewModel.sharedFiles.isNotEmpty) {
      print("Shared files are available in MainScreen.");
      if (isDialogOpen) {
        // Close the current dialog
        Navigator.pop(context);
      }
      // Open the GenerateDialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          isDialogOpen = true;
          return const GenerateDialog();
        },
      ).then((_) {
        isDialogOpen = false;
      });
    }
  }

  void _handleIntentViewModelChange() {
    final intentViewModel =
        Provider.of<IntentViewModel>(context, listen: false);
    if (intentViewModel.sharedFiles.isNotEmpty) {
      checkForSharedFiles();
    }
  }

  @override
  void dispose() {
    final intentViewModel =
        Provider.of<IntentViewModel>(context, listen: false);
    intentViewModel.removeListener(_handleIntentViewModelChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final generateDialogViewModel =
        Provider.of<GenerateDialogViewModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lisme - listen to my text'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('audioFiles')
                  .orderBy('created_at', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final documents = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final document = documents[index];
                      final fileId = document.id;
                      final data = document.data() as Map<String, dynamic>?;
                      final status = data?['status'] as String?;
                      final createdAt = data?['created_at'] as Timestamp?;
                      final formattedCreatedAt = createdAt != null
                          ? DateFormat('yyyy-MM-dd HH:mm:ss')
                              .format(createdAt.toDate())
                          : 'Pending';
                      return ListTile(
                        title: Text('File ID: $fileId'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${status ?? 'Pending'}'),
                            Text('Created At: $formattedCreatedAt'),
                          ],
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
          ),
          const SizedBox(height: 20),
          // Conditionally display the AudioPlayerWidget if there's a URL
          generateDialogViewModel.audioUrl != null &&
                  generateDialogViewModel.audioUrl!.isNotEmpty
              ? AudioPlayerWidget(audioUrl: generateDialogViewModel.audioUrl!)
              : Container(), // Show an empty container if there's no URL
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (isDialogOpen) {
            // Close the current dialog
            Navigator.pop(context);
          }
          // Open the GenerateDialog
          showDialog(
            context: context,
            builder: (BuildContext context) {
              isDialogOpen = true;
              return GenerateDialog();
            },
          ).then((_) {
            isDialogOpen = false;
          });
        },
        child: const Icon(Icons.add_box_sharp),
      ),
    );
  }
}
