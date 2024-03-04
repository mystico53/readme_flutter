import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/generate_dialog_viewmodel.dart';
import '../view_models/intent_viewmodel.dart';
import '../views/generate_dialog.dart';
import '../widgets/audio_player_widget.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  String userId = '';
  String sharedContent = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForSharedFiles();
    });
  }

  void checkForSharedFiles() {
    final intentViewModel =
        Provider.of<IntentViewModel>(context, listen: false);
    if (intentViewModel.sharedFiles.isNotEmpty) {
      print("Shared files are available in MainScreen.");
      // Perform actions based on available shared files
      // For example, navigate to GenerateDialog or update UI accordingly
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GenerateDialog()),
      );
    }
  }

  @override
  void dispose() {
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
            // Replace AudioFilesList with a list of operations
            child: Consumer<GenerateDialogViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.operations.isEmpty) {
                  return Center(child: Text("No operations started"));
                }
                return ListView.builder(
                  itemCount: viewModel.operations.length,
                  itemBuilder: (context, index) {
                    final operation = viewModel.operations[index];
                    return ListTile(
                      title: Text("Operation: ${operation.fileId}"),
                      subtitle: Text("Status: ${operation.status}"),
                    );
                  },
                );
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
