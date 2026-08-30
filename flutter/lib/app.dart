import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'logic/game_controller.dart';
import 'services/firebase_service.dart';
import 'services/preferences_service.dart';
import 'ui/screens/game_screen.dart';

/// Root widget: wires services into the [GameController] and applies the
/// dark theme matching the web app (#191919 background).
class ChainReactionApp extends StatelessWidget {
  const ChainReactionApp({
    super.key,
    required this.firebase,
    required this.prefs,
  });

  final FirebaseService firebase;
  final PreferencesService prefs;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameController(firebase: firebase, prefs: prefs),
      child: MaterialApp(
        title: AppConstants.appTitle,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: const ColorScheme.dark(
            surface: AppColors.background,
            primary: Colors.white,
          ),
          popupMenuTheme: PopupMenuThemeData(
            color: AppColors.surface,
            textStyle: const TextStyle(color: Colors.white, fontSize: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
          ),
          dividerTheme: const DividerThemeData(color: Colors.white10),
          useMaterial3: true,
        ),
        home: const GameScreen(),
      ),
    );
  }
}
