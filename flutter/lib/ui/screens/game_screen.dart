import 'package:flutter/material.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../logic/game_controller.dart';
import '../widgets/board/board_grid.dart';
import '../widgets/board/flying_dot_layer.dart';
import '../widgets/common/dot_loader.dart';
import '../widgets/common/ui_kit.dart';
import '../widgets/feedback/snackbar/content_type.dart';
import '../widgets/feedback/snackbar/custom_snackbar.dart';
import '../widgets/footer/game_footer.dart';
import '../widgets/header/game_header.dart';
import '../widgets/header/top_status_bar.dart';
import '../widgets/overlays/how_to_play_overlay.dart';
import '../widgets/overlays/win_overlay.dart';
import '../widgets/sheets/online_sheet.dart';
import '../widgets/sheets/settings_sheet.dart';
import '../../core/haptics.dart';

/// The single full-screen game page.
///
/// Layout: a status row (clock / likes) pinned to the very top, and a
/// board-centered block in the middle where the header and footer are sized
/// to the board's width so their icons sit on the board's corners (mockup).
/// Overlays (how-to-play, win screen, loading, flying dot, confetti) are
/// full-screen and carry their own action buttons.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GlobalKey _boardKey = GlobalKey();
  final GlobalKey _activeDotKey = GlobalKey();
  final GlobalKey _footerKey = GlobalKey();
  final GlobalKey _headerKey = GlobalKey();

  /// Vertical space reserved for the header block (controls + dots row) and
  /// the footer row when computing the board's cell size.
  static const double _headerReserve = 104;
  static const double _footerReserve = 72;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final game = context.read<GameController>();
      game.onToast = _showToast;
      game.onConfetti = _playConfetti;
      // Dev-only hooks for visual verification of the bottom sheets:
      // flutter run --dart-define=OPEN_ONLINE_SHEET=true (or OPEN_MENU_SHEET)
      if (const bool.fromEnvironment('OPEN_ONLINE_SHEET')) {
        showOnlineSheet(context, game);
      } else if (const bool.fromEnvironment('OPEN_MENU_SHEET')) {
        showSettingsSheet(context);
      }
    });
  }

  /// Subtle celebration burst, same tuning as the escape_game project.
  void _playConfetti() {
    Confetti.launch(
      context,
      options: const ConfettiOptions(
        particleCount: 100,
        spread: 70,
        y: 0.6,
        colors: AppColors.players,
      ),
    );
  }

  /// Global rect of the footer row (the board block is vertically centered,
  /// so its position varies per device); null before the first layout.
  Rect? _footerRect() {
    final box = _footerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Global rect of the header block; null before the first layout.
  Rect? _headerRect() {
    final box = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Shows the roamates-style pill snackbar (drops in from the top with a
  /// squash-and-stretch, tap/swipe to dismiss).
  void _showToast(String message, ToastTone tone) {
    if (!mounted) return;
    Snackbar.show(
      context,
      message: message,
      contentType: switch (tone) {
        ToastTone.success => ContentType.success,
        ToastTone.error => ContentType.failure,
        ToastTone.info => ContentType.help,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ------------------------------------------------ main layout
          Column(
            children: [
              // Keep content below the real system status bar.
              SizedBox(height: MediaQuery.viewPaddingOf(context).top + 4),
              TopStatusBar(onLike: () => game.like()),
              Expanded(
                child: Padding(
                  // Wide gutters for the board block; the likes pill above
                  // keeps its own tighter padding.
                  padding: const EdgeInsets.only(
                    left: 35,
                    right: 35,
                    bottom: 40,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // The board never grows past a fixed height, so large
                      // screens (tablets, desktop windows) keep sane cells.
                      final maxBoardHeight = game.boardSizeKey == '0'
                          ? 500.0
                          : 550.0;
                      final availableHeight =
                          (constraints.maxHeight -
                                  _headerReserve -
                                  _footerReserve)
                              .clamp(0.0, maxBoardHeight);
                      final cellSize = (constraints.maxWidth / game.cols)
                          .clamp(0.0, availableHeight / game.rows)
                          .floorToDouble();
                      final boardWidth = cellSize * game.cols;

                      return Center(
                        // scaleDown absorbs tiny (few-px) differences between
                        // the reserved and actual header/footer heights.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                key: _headerKey,
                                width: boardWidth,
                                child: GameHeader(activeDotKey: _activeDotKey),
                              ),
                              const SizedBox(height: 4),
                              BoardGrid(
                                boardKey: _boardKey,
                                cellSize: cellSize,
                              ),
                              SizedBox(
                                key: _footerKey,
                                width: boardWidth,
                                child: const GameFooter(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          // ------------------------------------------------ overlays
          if (game.showIWon) ...[
            Positioned.fill(child: WinOverlay(won: game.wonStatus)),
            // Restart floats above the overlay at the footer's position —
            // the same spot where undo shows (the web app's z-index trick) —
            // with the layered support button sitting just above it.
            if (_footerRect() case final Rect rect) ...[
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.sizeOf(context).height - rect.top + 36,
                child: const Center(child: SupportShadowButton()),
              ),
              Positioned.fromRect(
                rect: rect,
                child: Center(
                  child: PillButton(
                    text: TitleMessages.restart,
                    color: AppColors.chipOrange,
                    onTap: game.onTitleTap,
                  ),
                ),
              ),
            ],
          ],
          if (game.showHowToPlay) ...[
            Positioned.fill(
              child: HowToPlayOverlay(
                state: game.howToPlayState,
                onClose: game.closeHowToPlay,
              ),
            ),
            // "next" floats above the overlay in the footer row — the same
            // spot where undo shows.
            if (_footerRect() case final Rect rect)
              Positioned.fromRect(
                rect: rect,
                child: Center(
                  child: PillButton(
                    text: TitleMessages.next,
                    color: AppColors.accentYellow,
                    onTap: game.onTitleTap,
                  ),
                ),
              ),
          ],
          if (game.isMainLoading) ...[
            Positioned.fill(
              child: Container(
                color: const Color(0xCC000000),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const DotFlashingLoader(),
                    // Waiting-room message for mid-game joiners.
                    if (game.mainLoadingMessage != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        game.mainLoadingMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // The host's "start" floats above the overlay in the footer row
            // — the same spot where undo shows.
            if (game.titleMessage == TitleMessages.start)
              if (_footerRect() case final Rect rect)
                Positioned.fromRect(
                  rect: rect,
                  child: Center(
                    child: PillButton(
                      text: TitleMessages.start,
                      color: AppColors.players[0],
                      onTap: game.onTitleTap,
                    ),
                  ),
                ),
            // Escape hatch while waiting in a room: an exit button floats
            // above the overlay in the menu icon's spot (header bottom-left)
            // so a stranded player can always leave.
            if (game.isLive)
              if (_headerRect() case final Rect rect)
                Positioned.fromRect(
                  rect: rect,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        Haptics.tap();
                        game.leaveRoom();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Transform.flip(
                          flipX: true,
                          child: const Icon(
                            Icons.exit_to_app,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          ],

          // ------------------------------------------- move animation
          Positioned.fill(
            child: FlyingDotLayer(
              boardKey: _boardKey,
              activeDotKey: _activeDotKey,
            ),
          ),
        ],
      ),
    );
  }
}
