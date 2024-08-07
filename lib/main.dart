import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:readme_app/intropages/intropage_main.dart';
import 'package:readme_app/view_models/audioplayer_viewmodel.dart';
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
import '../view_models/main_screen_view_model.dart';
import 'package:audio_service/audio_service.dart';
import 'package:readme_app/services/audio_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();

  final myAudioHandler = MyAudioHandler();

  final audioHandler = await AudioService.init(
    builder: () => myAudioHandler,
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.mystical.lisme',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    ),
  );

  final audioPlayerViewModel = AudioPlayerViewModel(audioHandler);

  myAudioHandler.setViewModel(audioPlayerViewModel);

  runApp(
    MultiProvider(
      providers: [
        Provider<IntentService>(
          create: (_) => IntentService(),
        ),
        ChangeNotifierProvider(create: (context) => TextCleanerViewModel()),
        ChangeNotifierProvider(create: (context) => IntentViewModel()),
        ChangeNotifierProvider(create: (_) => UserIdViewModel()),
        ChangeNotifierProvider.value(value: audioPlayerViewModel),
        Provider<AudioHandler>.value(value: audioHandler),
        ChangeNotifierProvider(
          create: (context) {
            final userIdViewModel =
                Provider.of<UserIdViewModel>(context, listen: false);
            return MainScreenViewModel(userIdViewModel.userId);
          },
        ),
        // Update this provider
        ChangeNotifierProvider(
          create: (context) => GenerateDialogViewModel(
            Provider.of<UserIdViewModel>(context, listen: false).userId,
            Provider.of<AudioPlayerViewModel>(context, listen: false),
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          return MyApp();
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
          scaffoldBackgroundColor: Color(0xFFFFEFC3),
          textTheme: GoogleFonts.hindTextTheme(
            Theme.of(context).textTheme,
          ).apply(
            // Applying a color to all text styles within the text theme
            bodyColor: Color(0xFF4B473D), // Set the default text color
            displayColor:
                Color(0xFF4B473D), // Used for headings and other display texts
          ),
        ),
        home: const MainScreen(),
        routes: {
          '/intropages/intropage_main': (context) => IntroPageMain(),
        },
      ),
    );
  }
}
