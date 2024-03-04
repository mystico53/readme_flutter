import 'package:flutter/material.dart';
import 'services/intent_service.dart';
import 'view_models/generate_dialog_viewmodel.dart';
import 'view_models/intent_viewmodel.dart';
import 'services/firebase_init.dart';
import 'view_models/text_cleaner_viewmodel.dart';
import 'view_models/user_id_viewmodel.dart';
import 'views/main_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(
    MultiProvider(
      providers: [
        Provider<IntentService>(
          create: (_) => IntentService(),
        ),
        ChangeNotifierProvider(create: (context) => TextCleanerViewModel()),
        ChangeNotifierProvider(create: (context) => IntentViewModel()),
        ChangeNotifierProvider(create: (context) => GenerateDialogViewModel()),
        ChangeNotifierProvider(create: (_) => UserIdViewModel()),
        // Add other providers here
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _initializeIntentHandling());
  }

  void _initializeIntentHandling() {
    final intentViewModel =
        Provider.of<IntentViewModel>(context, listen: false);
    intentViewModel.loadInitialSharedFiles();
    intentViewModel.startListeningForIntents();
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainScreen(), // Assuming MainScreen is the entry screen of your app
    );
  }
}
