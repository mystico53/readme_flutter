import 'package:flutter/material.dart';
import 'view_models/generate_dialog_viewmodel.dart';
import 'view_models/intent_viewmodel.dart';
import 'services/firebase_init.dart';
import 'view_models/text_cleaner_viewmodel.dart';
import 'view_models/text_to_googleTTS_viewmodel.dart';
import 'view_models/user_id_viewmodel.dart';
import 'views/main_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TextCleanerViewModel()),
        ChangeNotifierProvider(create: (context) => TextToGoogleTTSViewModel()),
        ChangeNotifierProvider(create: (context) => IntentViewModel()),
        ChangeNotifierProvider(create: (context) => GenerateDialogViewModel()),
        ChangeNotifierProvider(create: (_) => UserIdViewModel()),
        // Add other providers here
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainScreen(),
    );
  }
}
