/// Game-wide constants shared across logic and UI.
abstract final class AppConstants {
  static const String appTitle = 'chain reaction';
  static const String version = '1.8.1';

  /// Default board (portrait): 9 rows x 6 columns.
  static const int defaultRows = 9;
  static const int defaultCols = 6;

  /// Large board option: 10 x 10.
  static const int largeRows = 10;
  static const int largeCols = 10;

  static const int minPlayers = 2;
  static const int maxPlayers = 4;

  /// The AI always plays as player index 1 (same as the React app).
  static const int aiPlayerIndex = 1;

  /// Duration of one explosion wave (matches the web's 400ms CSS animation).
  static const Duration explosionWave = Duration(milliseconds: 400);

  /// Duration of the "flying dot" move animation.
  static const Duration flyingDot = Duration(milliseconds: 400);

  /// Delay before the AI starts thinking about its move.
  static const Duration aiMoveDelay = Duration(milliseconds: 450);

  /// Web game link shared together with a room code.
  static const String gameLink =
      'https://bharath-bandaru.github.io/chain-reaction-game/';

  static const String supportUrl =
      'https://www.paypal.com/donate/?business=QTCZHFFF6J6HE&no_recurring=0&currency_code=USD';
}
