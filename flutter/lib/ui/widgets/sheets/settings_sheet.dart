import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../logic/game_controller.dart';
import '../common/ui_kit.dart';
import '../layout/custom_bottom_page.dart';
import 'confirm_sheet.dart';
import '../../../core/haptics.dart';

/// Opens the game menu bottom sheet on the roamates-style custom bottom
/// page: slide-up route, drag-to-dismiss, elastic over-drag. The glass
/// surface (and its top-corner shine) stays with [SheetSurface].
Future<void> showSettingsSheet(BuildContext context) {
  return Navigator.of(context).push(
    CustomBottomPage<void>(
      // Lighter than the default black54: the glass needs the board
      // showing through it, not a near-opaque wall behind it.
      barrierColorOverride: const Color(0x47000000),
      child: const CustomBottomSheetScaffold(child: SettingsSheet()),
    ),
  );
}

/// Rich bottom sheet for game settings: AI difficulty cards, board size,
/// animation/undo toggles, and How to Play — same visual language as the
/// online sheet (dark rounded panel, colorful icon chips, card rows).
///
/// Watches the [GameController] so the toggles and selections update in
/// place without closing the sheet.
class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();

    return SheetSurface(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 10,
          bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const Row(
                children: [
                  Text(
                    'Game Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Difficulty, board size, animations and more.',
                style: TextStyle(color: AppColors.mutedText, fontSize: 13),
              ),
              const SizedBox(height: 18),

              if (!game.isLive) ...[
                const _SectionLabel('Opponent'),
                _DifficultySwitch(
                  // Always shows a selection; the stored level defaults to
                  // Medium.
                  selectedIndex: (int.parse(game.aiLevel) - 1).clamp(0, 2),
                  onChanged: (index) async {
                    if (game.aiPlayerIndex == null) {
                      // AI off: just move the selection; the button below
                      // starts the game.
                      game.setAiLevel('${index + 1}');
                      return;
                    }
                    // Same segment tapped again: nothing to change.
                    if (index == (int.parse(game.aiLevel) - 1).clamp(0, 2)) {
                      return;
                    }
                    final navigator = Navigator.of(context);
                    if (game.isMidGame) {
                      // Re-leveling restarts the AI game: dismiss the menu
                      // first, then confirm.
                      navigator.pop();
                      await Future.delayed(const Duration(milliseconds: 320));
                      final confirmed = await showConfirmSheetOn(
                        navigator,
                        title: 'Change difficulty?',
                        message:
                            'A game is in progress — changing the '
                            'difficulty restarts it.',
                        confirmLabel: 'Change',
                        confirmColor: AppColors.players[0],
                      );
                      if (confirmed) game.playWithComputer('${index + 1}');
                      return;
                    }
                    game.playWithComputer('${index + 1}');
                    // Let the thumb finish sliding, then auto-collapse.
                    Future.delayed(const Duration(milliseconds: 350), () {
                      if (navigator.canPop()) navigator.pop();
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (game.aiPlayerIndex == null)
                  SheetOptionRow(
                    icon: Icons.smart_toy,
                    // The AI plays as the pink player in-game.
                    chipColor: AppColors.players[1],
                    title: 'Play with Computer',
                    subtitle:
                        'Start a '
                        '${_DifficultySwitch._labels[(int.parse(game.aiLevel) - 1).clamp(0, 2)]}'
                        ' game against the AI',
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      if (!game.isMidGame) {
                        game.playWithComputer(game.aiLevel);
                        Future.delayed(const Duration(milliseconds: 250), () {
                          if (navigator.canPop()) navigator.pop();
                        });
                        return;
                      }
                      // Mid-game: dismiss the menu first, then confirm on a
                      // fresh sheet of its own.
                      navigator.pop();
                      await Future.delayed(const Duration(milliseconds: 320));
                      final confirmed = await showConfirmSheetOn(
                        navigator,
                        title: 'Play with Computer?',
                        message:
                            'A game is in progress — switching to the '
                            'AI restarts it.',
                        confirmLabel: 'Start',
                        confirmColor: AppColors.players[1],
                      );
                      if (confirmed) game.playWithComputer(game.aiLevel);
                    },
                  )
                else
                  SheetOptionRow(
                    icon: Icons.exit_to_app,
                    chipColor: AppColors.players[3],
                    title: 'Exit to Play with Friends',
                    subtitle: 'Turn the computer player off',
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      if (!game.isMidGame) {
                        navigator.pop();
                        game.exitComputerMode();
                        return;
                      }
                      // Dismiss the menu first, then confirm.
                      navigator.pop();
                      await Future.delayed(const Duration(milliseconds: 320));
                      final confirmed = await showConfirmSheetOn(
                        navigator,
                        title: 'Exit to friends mode?',
                        message:
                            'A game is in progress — leaving AI mode '
                            'restarts it.',
                        confirmLabel: 'Exit',
                        confirmColor: AppColors.players[3],
                      );
                      if (confirmed) game.exitComputerMode();
                    },
                  ),
                const SizedBox(height: 18),
                // Board size is a tablet-only option: 10x10 cells get too
                // cramped on phone screens (the web app gates it the same
                // way, by window size).
                if (isTabletLayout(context)) ...[
                  const _SectionLabel('Board Size'),
                  Row(
                    children: [
                      _BoardCard(
                        label: '6 x 9',
                        selected: game.boardSizeKey == '0',
                        onTap: () => _changeBoardSize(context, game, '0'),
                      ),
                      const SizedBox(width: 10),
                      _BoardCard(
                        label: '10 x 10',
                        selected: game.boardSizeKey == '1',
                        onTap: () => _changeBoardSize(context, game, '1'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
              ],

              const _SectionLabel('Preferences'),
              SheetToggleRow(
                icon: Icons.auto_awesome,
                chipColor: AppColors.players[0],
                title: 'Move Animation',
                subtitle: 'Fly an orb from the player to the cell',
                value: game.showAnimation,
                onChanged: (_) => game.toggleAnimation(),
              ),
              const SizedBox(height: 12),
              SheetToggleRow(
                icon: Icons.undo,
                chipColor: AppColors.players[3],
                title: 'Undo Button',
                subtitle: 'Show undo under the board',
                value: game.showUndo,
                onChanged: (_) => game.toggleUndoButton(),
              ),
              const SizedBox(height: 12),
              SheetToggleRow(
                icon: Icons.vibration,
                chipColor: AppColors.players[1],
                title: 'Haptics',
                subtitle: 'Vibrate lightly on every tap',
                value: game.hapticsEnabled,
                onChanged: (_) => game.toggleHaptics(),
              ),
              const SizedBox(height: 12),
              SheetOptionRow(
                icon: Icons.question_mark,
                chipColor: AppColors.chipGreen,
                title: 'How to Play?',
                subtitle: 'Rules, critical mass and chain reactions',
                onTap: () {
                  Navigator.of(context).pop();
                  game.openHowToPlay();
                },
              ),
              const SizedBox(height: 14),
              const Center(
                child: Text(
                  'version ${AppConstants.version}',
                  style: TextStyle(color: AppColors.faintText, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Switches the board size; a no-op when the size is already active, and
/// confirmed first when a game is in progress (the change restarts it).
Future<void> _changeBoardSize(
  BuildContext context,
  GameController game,
  String key,
) async {
  if (game.boardSizeKey == key) return;
  final navigator = Navigator.of(context);
  if (!game.isMidGame) {
    navigator.pop();
    game.setBoardSize(key);
    return;
  }
  // Dismiss the menu first, then confirm.
  navigator.pop();
  await Future.delayed(const Duration(milliseconds: 320));
  final confirmed = await showConfirmSheetOn(
    navigator,
    title: 'Change board size?',
    message: 'A game is in progress — changing the board restarts it.',
    confirmLabel: 'Change',
    confirmColor: AppColors.players[0],
  );
  if (confirmed) game.setBoardSize(key);
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Segmented difficulty switch: a dark rounded track with a sliding filled
/// thumb under bold labels. Always shows the selected difficulty (Medium by
/// default); starting the game is a separate action.
class _DifficultySwitch extends StatelessWidget {
  const _DifficultySwitch({
    required this.selectedIndex,
    required this.onChanged,
  });

  /// 0 = Easy, 1 = Medium, 2 = Hard; null when playing without the AI.
  final int? selectedIndex;
  final ValueChanged<int> onChanged;

  static const _labels = ['Easy', 'Medium', 'Hard'];
  // Easy -> green, Medium -> player blue, Hard -> player red.
  static const _accents = [
    AppColors.chipGreen,
    Color(0xFF00A8CD),
    Color(0xFFCD0000),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / _labels.length;
          return Stack(
            children: [
              if (selectedIndex != null)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  left: segmentWidth * selectedIndex!,
                  top: 0,
                  bottom: 0,
                  width: segmentWidth,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: _accents[selectedIndex!],
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                ),
              Row(
                children: [
                  for (var i = 0; i < _labels.length; i++)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Haptics.tap();
                          onChanged(i);
                        },
                        child: Center(
                          child: Text(
                            _labels[i],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Selectable board-size card.
class _BoardCard extends StatelessWidget {
  const _BoardCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? Colors.white10 : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Haptics.tap();
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? Colors.white : Colors.transparent,
                width: 1.4,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.grid_on,
                  size: 18,
                  color: selected ? Colors.white : Colors.white54,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
