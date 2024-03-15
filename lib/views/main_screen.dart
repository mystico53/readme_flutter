import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/generate_dialog_viewmodel.dart';
import '../view_models/intent_viewmodel.dart';
import '../view_models/user_id_viewmodel.dart';
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
  String selectedAudioTitle = '';
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
    final intentViewModel =
        Provider.of<IntentViewModel>(context, listen: false);
    if (intentViewModel.sharedFiles.isNotEmpty) {
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
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  Future<String> _getUserId() async {
    final userIdViewModel =
        Provider.of<UserIdViewModel>(context, listen: false);
    String userId = userIdViewModel.userId;
    print('User ID for mainscreen: $userId');
    return userId;
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
    // Log when the build method is called

    final generateDialogViewModel =
        Provider.of<GenerateDialogViewModel>(context);
    final userIdViewModel = Provider.of<UserIdViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[300],
        title: Text(
          userIdViewModel.userId.isNotEmpty
              ? 'Lisme\nUser(${userIdViewModel.userId})'
              : 'Lisme',
          style: TextStyle(
            fontSize: 16,
            height: 1.2,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: userIdViewModel.userId.isNotEmpty
                ? StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('audioFiles')
                        .where('userId', isEqualTo: userIdViewModel.userId)
                        .orderBy('created_at', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final documents = snapshot.data!.docs;
                        // Log how many documents were fetched

                        return ListView.separated(
                          controller: _scrollController,
                          itemCount: documents.length,
                          separatorBuilder: (context, index) => Divider(),
                          itemBuilder: (context, index) {
                            final document = documents[index];
                            final fileId = document.id;
                            final data =
                                document.data() as Map<String, dynamic>?;
                            final status = data?['status'] as String?;
                            final createdAt = data?['created_at'] as Timestamp?;
                            final formattedCreatedAt = createdAt != null
                                ? DateFormat('yyyy-MM-dd HH:mm:ss')
                                    .format(createdAt.toDate())
                                : 'endingP';
                            final title = data?['title'] as String?;

                            return ListTile(
                              title: Text(title ?? 'New Lisme is created'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status: ${status ?? 'Preparing'}',
                                    style: TextStyle(
                                      color:
                                          status == 'error' ? Colors.red : null,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text('Created At: $formattedCreatedAt'),
                                      SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(Icons.delete, size: 16),
                                        onPressed: () async {
                                          // Log the deletion of a document
                                          print(
                                              "Deleting document with ID: $fileId");
                                          await FirebaseFirestore.instance
                                              .collection('audioFiles')
                                              .doc(fileId)
                                              .delete();
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: status == 'ready'
                                  ? CircleAvatar(
                                      backgroundColor: Colors.blue,
                                      child: IconButton(
                                        icon: Icon(Icons.play_arrow,
                                            color: Colors.white),
                                        onPressed: () {
                                          final httpsUrl =
                                              data?['httpsUrl'] as String?;
                                          final title =
                                              data?['title'] as String?;
                                          if (httpsUrl != null &&
                                              httpsUrl.isNotEmpty &&
                                              title != null) {
                                            setState(() {
                                              selectedAudioUrl = httpsUrl;
                                              selectedAudioTitle = title;
                                            });
                                          } else {
                                            print(
                                                'Audio URL or title is missing or invalid for document: $fileId');
                                          }
                                        },
                                      ),
                                    )
                                  : Icon(Icons.hourglass_empty),
                            );
                          },
                        );
                      } else if (snapshot.hasError) {
                        // Log the error
                        print("Error fetching documents: ${snapshot.error}");
                        return Text('Error: ${snapshot.error}');
                      } else {
                        // Log the loading state
                        print("Waiting for documents...");
                        return CircularProgressIndicator();
                      }
                    },
                  )
                : Center(child: CircularProgressIndicator()),
          ),
          AudioPlayerWidget(
            audioUrl: selectedAudioUrl,
            audioTitle: selectedAudioTitle,
          ),
        ],
      ),
    );
  }
}
