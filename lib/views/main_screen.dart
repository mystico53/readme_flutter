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
  String selectedAudioUrl = '';
  final _scrollController = ScrollController();
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

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 200,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
                  return Scrollbar(
                    controller: _scrollController,
                    child: ListView.builder(
                      controller: _scrollController,
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
                          onTap: () {
                            // Get the httpsUrl field from the Firestore document
                            final httpsUrl = data?['httpsUrl'] as String?;
                            if (httpsUrl != null && httpsUrl.isNotEmpty) {
                              setState(() {
                                selectedAudioUrl = httpsUrl;
                              });
                            } else {
                              // Handle the case when the URL is null or empty
                              print(
                                  'Audio URL is missing or invalid for document: $fileId');
                              // Display an error message or take appropriate action
                            }
                          },
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () async {
                              // Delete the document from Firestore
                              await FirebaseFirestore.instance
                                  .collection('audioFiles')
                                  .doc(fileId)
                                  .delete();
                            },
                          ),
                        );
                      },
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
          ),
          AudioPlayerWidget(audioUrl: selectedAudioUrl),
        ],
      ),
      floatingActionButton: Padding(
        padding:
            EdgeInsets.only(bottom: 120.0), // Adjust the offset value as needed
        child: FloatingActionButton(
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
            ).then((callback) {
              isDialogOpen = false;
              Future.delayed(Duration(milliseconds: 500), () {
                _scrollToBottom();
              });
            });
          },
          child: const Icon(Icons.add_box_sharp),
        ),
      ),
    );
  }
}
