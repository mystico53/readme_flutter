import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:feedback/feedback.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:readme_app/view_models/audioplayer_viewmodel.dart';
import 'package:readme_app/views/webview.dart';
import '../services/feedback_service.dart';
import '../view_models/generate_dialog_viewmodel.dart';
import '../view_models/intent_viewmodel.dart';
import '../view_models/user_id_viewmodel.dart';
import '../views/generate_dialog.dart';
import '../widgets/audio_player_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String selectedFileId = '';
  final audioPlayerViewModel = AudioPlayerViewModel();
  SharedPreferences? _prefs;
  late VoidCallback _progressListener;
  Map<String, double> _fileProgress = {};
  IntentViewModel? _intentViewModel; //for webview only

  @override
  void initState() {
    super.initState();
    final intentViewModel =
        Provider.of<IntentViewModel>(context, listen: false);
    intentViewModel.addListener(_handleIntentViewModelChange);
    //_intentViewModel = intentViewModel; //for webview only
    //_intentViewModel!.startListeningForIntents(context); //for webview only
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _prefs = prefs;
      });
    });

    _progressListener = () {
      final fileId = audioPlayerViewModel.currentFileId;
      final progress = audioPlayerViewModel.lastProgressPercentage;
      if (fileId != null) {
        setState(() {
          _fileProgress[fileId] = progress;
        });
      }
    };
    audioPlayerViewModel.addListener(_progressListener);
  }

  void _handleIntentViewModelChange() {
    final intentViewModel =
        Provider.of<IntentViewModel>(context, listen: false);
    if (intentViewModel.sharedFiles.isNotEmpty) {
      if (isDialogOpen) {
        // Close the current dialog
        Navigator.pop(context);
      }
      final sharedContent = intentViewModel.sharedFiles[0].path;
      final lines = sharedContent.split('\n');
      final firstLine = lines.isNotEmpty ? lines[0] : '';

      // Call the intentViewModel to pass the firstLine and get the extracted URL
      final extractedUrl = intentViewModel.lookForURL(firstLine);
      if (extractedUrl.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
              create: (context) => UserIdViewModel()..initUserId(),
              child: WebViewPage(url: extractedUrl),
            ),
          ),
        );
      } else {
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
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  void _showFeedback(BuildContext context) {
    BetterFeedback.of(context).show((feedback) async {
      try {
        await FeedbackService.submitFeedback(
          feedback.text,
          feedback.screenshot,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback submitted successfully')),
        );
      } catch (error) {
        print('Error submitting feedback: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error submitting feedback')),
        );
      }
    });
  }

  String formatDuration(int? durationInSeconds) {
    if (durationInSeconds == null) {
      return '';
    }

    if (durationInSeconds < 60) {
      return '$durationInSeconds sec';
    } else {
      final minutes = durationInSeconds ~/ 60;
      final seconds = durationInSeconds % 60;
      return '$minutes min ${seconds > 0 ? '$seconds sec' : ''}';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    final intentViewModel =
        Provider.of<IntentViewModel>(context, listen: false);
    intentViewModel.removeListener(_handleIntentViewModelChange);
    _intentViewModel?.removeListener(_handleIntentViewModelChange);
    audioPlayerViewModel.removeListener(_progressListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Log when the build method is called

    final generateDialogViewModel =
        Provider.of<GenerateDialogViewModel>(context);
    final userIdViewModel = Provider.of<UserIdViewModel>(context);

    return Consumer<AudioPlayerViewModel>(
      builder: (context, audioPlayerViewModel, child) {
        final formattedDuration = audioPlayerViewModel
            .formatDuration(audioPlayerViewModel.totalTimePlayed);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF4B473D),
            title: Row(
              children: [
                Tooltip(
                  message: 'Air time: $formattedDuration',
                  child: const Text(
                    'Lisme',
                    style: TextStyle(
                      fontSize: 32,
                      height: 1.2,
                      color: Color(0xFFFFEFC3),
                    ),
                  ),
                ),
                const SizedBox(
                    width:
                        60), /*
                Tooltip(
                  message: 'Air time: $formattedDuration',
                  child: const Icon(
                    Icons.earbuds_rounded,
                    size: 24,
                    color: Color(0xFFFFEFC3),
                  ),
                ),*/
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _showFeedback(context);
                },
                child: const Text(
                  'Give Feedback',
                  style: TextStyle(color: Color(0xFFFFEFC3)),
                ),
              ),
            ],
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
                            if (documents.isEmpty) {
                              return ListTile(
                                title: const Text(
                                    'Learn how to create your first lisme'),
                                trailing: const Icon(Icons.tips_and_updates),
                                onTap: () {
                                  Navigator.pushNamed(
                                      context, '/intropages/intropage_main');
                                },
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: ListView.separated(
                                controller: _scrollController,
                                itemCount: documents.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 5),
                                itemBuilder: (context, index) {
                                  final document = documents[index];
                                  final fileId = document.id;
                                  final data =
                                      document.data() as Map<String, dynamic>?;
                                  final status = data?['status'] as String?;
                                  final createdAt =
                                      data?['created_at'] as Timestamp?;
                                  final formattedCreatedAt = createdAt != null
                                      ? DateFormat('MMMM d, yyyy, h:mm a')
                                          .format(createdAt.toDate())
                                      : 'endingP';
                                  final title = data?['title'] as String?;
                                  //final progress = data?['progress'] ?? 0;
                                  //final progress = _fileProgress[fileId] ?? 0.0;

                                  final durationInSeconds =
                                      data?['duration'] as int?;
                                  final formattedDuration =
                                      formatDuration(durationInSeconds);

                                  //calc progress in percent stuff
                                  final savedProgressString =
                                      _prefs?.getString('$fileId');
                                  final savedProgress =
                                      savedProgressString != null
                                          ? int.parse(savedProgressString)
                                          : 0;
                                  final totalDuration =
                                      Duration(seconds: durationInSeconds ?? 0);
                                  final progress = totalDuration.inSeconds > 0
                                      ? (savedProgress /
                                          totalDuration.inMilliseconds)
                                      : 0.0;

                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 5),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFF4B473D),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        ListTile(
                                          title: Text(
                                              title ?? 'New Lisme is created'),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  if (status != 'ready' &&
                                                      status!
                                                          .startsWith('error'))
                                                    const Padding(
                                                      padding: EdgeInsets.only(
                                                          right: 8.0),
                                                      child: SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                      ),
                                                    ),
                                                  Text(
                                                    status ?? 'Preparing',
                                                    style: TextStyle(
                                                      color: status == 'error'
                                                          ? Colors.red
                                                          : null,
                                                    ),
                                                  ),
                                                  if (status ==
                                                      'error: google tts')
                                                    const Padding(
                                                      padding: EdgeInsets.only(
                                                          left: 8.0),
                                                      child: Icon(
                                                        Icons.error,
                                                        color: Colors.red,
                                                        size: 16,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Text('$formattedCreatedAt'),
                                                  const SizedBox(width: 8),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.delete,
                                                        size: 16),
                                                    onPressed: () async {
                                                      print(
                                                          "Deleting document with ID: $fileId");
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection(
                                                              'audioFiles')
                                                          .doc(fileId)
                                                          .delete();
                                                    },
                                                  ),
                                                  const SizedBox(width: 8),
                                                  if (formattedDuration
                                                      .isNotEmpty)
                                                    Text('$formattedDuration'),
                                                  const SizedBox(width: 8),
                                                  // Fetch and display saved progress
                                                ],
                                              ),
                                              /*
                                          Text(
                                            'Progress listen: ${progress.toStringAsFixed(1)}%',
                                          ),*/
                                            ],
                                          ),
                                          trailing: status == 'ready'
                                              ? CircleAvatar(
                                                  backgroundColor:
                                                      const Color(0xFF4B473D),
                                                  child: IconButton(
                                                    icon: const Icon(
                                                        Icons.play_arrow,
                                                        color:
                                                            Color(0xFFFFEFC3)),
                                                    onPressed: () async {
                                                      final httpsUrl =
                                                          data?['httpsUrl']
                                                              as String?;
                                                      final title =
                                                          data?['title']
                                                              as String?;
                                                      if (httpsUrl != null &&
                                                          httpsUrl.isNotEmpty &&
                                                          title != null) {
                                                        setState(() {
                                                          selectedAudioUrl =
                                                              httpsUrl;
                                                          selectedAudioTitle =
                                                              title;
                                                          selectedFileId =
                                                              fileId;
                                                        });
                                                      } else {
                                                        print(
                                                            'Audio URL or title is missing or invalid for document: $fileId');
                                                      }
                                                    },
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.hourglass_empty),
                                        ),
                                        if (status != 'ready')
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: LinearProgressIndicator(
                                              value: calculateStatus(status),
                                              backgroundColor:
                                                  const Color(0xFFFFEFC3),
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                      Color>(Color(0xFF4B473D)),
                                              minHeight: 8.0,
                                            ),
                                          ),
                                        if (status == 'ready')
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              backgroundColor:
                                                  const Color(0xFFFFEFC3),
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                      Color>(Color(0xFF4B473D)),
                                              minHeight: 8.0,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          } else if (snapshot.hasError) {
                            // Log the error
                            print(
                                "Error fetching documents: ${snapshot.error}");
                            return Text('Error: ${snapshot.error}');
                          } else {
                            // Log the loading state
                            print("Waiting for documents...");
                            return const CircularProgressIndicator();
                          }
                        },
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
              AudioPlayerWidget(
                audioUrl: selectedAudioUrl,
                audioTitle: selectedAudioTitle,
                fileId: selectedFileId,
                viewModel: audioPlayerViewModel,
              ),
            ],
          ),
        );
      },
    );
  }

  double calculateStatus(String? status) {
    if (status == 'initiating file') return 0.1;
    if (status == 'processing text') return 0.2;
    if (status == 'generating title') return 0.4;
    if (status == 'summarizing') return 0.45;
    if (status == 'preparing speech service') return 0.5;
    if (status == 'generating speech') return 0.7;
    if (status == 'ready') return 1.0;
    return 0.0;
  }
}
