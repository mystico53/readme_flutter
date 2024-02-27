import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '/services/firebase_options.dart';
import '/utils/app_config.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up Firebase Crashlytics error handling as the default error handler
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  // Automatically switch between Firestore emulator and production
  if (!AppConfig.isProduction) {
    // For local development, connect to the Firestore emulator
    // Use '10.0.2.2' for Android emulator and 'localhost' for iOS simulator or web
    FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);
    FirebaseFunctions.instance.useFunctionsEmulator('10.0.2.2', 5001);
  }
}
