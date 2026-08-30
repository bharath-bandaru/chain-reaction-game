import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/firebase_service.dart';
import 'services/preferences_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge layout with the system status bar (clock, battery,
  // notifications) visible over the dark canvas, locked to portrait.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, // Android: light icons
    statusBarBrightness: Brightness.dark, // iOS: dark bg -> light icons
  ));

  final firebase = FirebaseService();
  await firebase.init();
  final prefs = await PreferencesService.load();

  runApp(ChainReactionApp(firebase: firebase, prefs: prefs));
}
