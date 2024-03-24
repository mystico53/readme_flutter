import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:readme_app/intropages/intropage_main.dart';
import 'services/intent_service.dart';
import 'view_models/generate_dialog_viewmodel.dart';
import 'view_models/intent_viewmodel.dart';
import 'services/firebase_init.dart';
import 'view_models/text_cleaner_viewmodel.dart';
import 'view_models/user_id_viewmodel.dart';
import 'views/main_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter/rendering.dart';
import '/intropages/intropage_main.dart';
import 'package:feedback/feedback.dart';

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
        ChangeNotifierProvider(create: (_) => UserIdViewModel()),
        // Add other providers here
      ],
      child: Builder(
        builder: (context) {
          return ChangeNotifierProvider(
            create: (context) => GenerateDialogViewModel(
              Provider.of<UserIdViewModel>(context, listen: false).userId,
            ),
            child: MyApp(),
          );
        },
      ),
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
    Future.microtask(() async {
      await _initializeUserId();
      _initializeIntentHandling();
    });
  }

  Future<void> _initializeUserId() async {
    final userIdViewModel =
        Provider.of<UserIdViewModel>(context, listen: false);
    await userIdViewModel.initUserId();
  }

  void _initializeIntentHandling() {
    final intentViewModel =
        Provider.of<IntentViewModel>(context, listen: false);
    intentViewModel.loadInitialSharedFiles();
    intentViewModel.startListeningForIntents(context);
  }

  @override
  Widget build(BuildContext context) {
    return BetterFeedback(
      child: MaterialApp(
        theme: ThemeData(
          // Define the default brightness and colors.
          scaffoldBackgroundColor: Color(0xFFFFEFC3),
          textTheme: GoogleFonts.dosisTextTheme(
            Theme.of(context)
                .textTheme, // This ensures that VT323 is applied on top of the current theme
          ), // Custom color for background
        ),
        home:
            const MainScreen(), // Assuming MainScreen is the entry screen of your app
        routes: {
          '/intropages/intropage_main': (context) => IntroPageMain(),
        },
      ),
    );
  }
}
