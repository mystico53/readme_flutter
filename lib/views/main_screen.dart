import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/user_id_viewmodel.dart';
import '../views/generate_dialog.dart';
import '../widgets/audio_files_list.dart';
import '../view_models/text_to_googleTTS_viewmodel.dart';
import '../widgets/audio_player_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  String userId = '';

  @override
  void initState() {
    super.initState();
    Provider.of<UserIdViewModel>(context, listen: false).initUserId();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TTSviewModel = Provider.of<TextToGoogleTTSViewModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lisme - listen to my text'),
      ),
      body: Column(
        // Use Column (or another layout widget) here
        children: <Widget>[
          Expanded(
            child: AudioFilesList(
              onAudioSelected: (String url) {
                // Implement your logic here
              },
            ),
          ),
          const SizedBox(height: 20),
          TTSviewModel.audioUrl != null && TTSviewModel.audioUrl!.isNotEmpty
              ? AudioPlayerWidget(audioUrl: TTSviewModel.audioUrl!)
              : Container(), // Show an empty container if there's no URL
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return const GenerateDialog(); // Ensure GenerateDialog can be instantiated without parameters or adjust accordingly
            },
          );
        },
        child: const Icon(Icons.add_box_sharp),
      ),
    );
  }
}
