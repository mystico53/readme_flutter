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

  print("Debug: Firebase initialized"); // Debug statement

  final myAudioHandler = MyAudioHandler();

  final audioHandler = await AudioService.init(
    builder: () => myAudioHandler,
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.mystical.lisme',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
    ),
  );

  print("Debug: AudioService initialized"); // Debug statement

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
        ChangeNotifierProvider(
          create: (context) => GenerateDialogViewModel(
            Provider.of<UserIdViewModel>(context, listen: false).userId,
            Provider.of<AudioPlayerViewModel>(context, listen: false),
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          print("Debug: Providers set up"); // Debug statement
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
    print("Debug: MyAppState initState called"); // Debug statement
    Future.microtask(() async {
      await _initializeUserId();
      _initializeIntentHandling();
    });
  }

  Future<void> _initializeUserId() async {
    print("Debug: Initializing UserId"); // Debug statement
    final userIdViewModel =
        Provider.of<UserIdViewModel>(context, listen: false);
    await userIdViewModel.initUserId();
    print(
        "Debug: UserId initialized: ${userIdViewModel.userId}"); // Debug statement
  }

  void _initializeIntentHandling() {
    print("Debug: Initializing Intent Handling"); // Debug statement
    final intentViewModel =
        Provider.of<IntentViewModel>(context, listen: false);
    intentViewModel.loadInitialSharedFiles();
    print("Debug: Initial shared files loaded"); // Debug statement
    intentViewModel.startListeningForIntents(context);
    print("Debug: Started listening for intents"); // Debug statement
  }

  @override
  Widget build(BuildContext context) {
    print("Debug: MyApp build method called"); // Debug statement
    return BetterFeedback(
      child: MaterialApp(
        theme: ThemeData(
          scaffoldBackgroundColor: Color(0xFFFFEFC3),
          textTheme: GoogleFonts.hindTextTheme(
            Theme.of(context).textTheme,
          ).apply(
            bodyColor: Color(0xFF4B473D),
            displayColor: Color(0xFF4B473D),
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
