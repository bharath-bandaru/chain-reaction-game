import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../common/ui_kit.dart';
import '../layout/custom_bottom_page.dart';

/// Themed confirmation bottom sheet (the roamates `showConfirmBottomSheet`
/// pattern on our glass surface). Resolves to true only when the user
/// explicitly confirms; cancel, swipe-down, and barrier taps all resolve
/// false.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Restart',
  Color confirmColor = const Color(0xFFCD0000), // player red
}) =>
    showConfirmSheetOn(
      Navigator.of(context),
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      confirmColor: confirmColor,
    );

/// Same as [showConfirmSheet] but addressed to a [NavigatorState] directly —
/// for callers whose own context is gone (e.g. a menu sheet that dismisses
/// itself before asking).
Future<bool> showConfirmSheetOn(
  NavigatorState navigator, {
  required String title,
  required String message,
  String confirmLabel = 'Restart',
  Color confirmColor = const Color(0xFFCD0000), // player red
}) async {
  final result = await navigator.push<bool>(
    CustomBottomPage<bool>(
      barrierColorOverride: const Color(0x47000000),
      child: CustomBottomSheetScaffold(
        minHeightFactor: 0,
        maxHeightFactor: 0.5,
        child: _ConfirmSheetContent(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          confirmColor: confirmColor,
        ),
      ),
    ),
  );
  return result ?? false;
}

class _ConfirmSheetContent extends StatelessWidget {
  const _ConfirmSheetContent({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;

  @override
  Widget build(BuildContext context) {
    return SheetSurface(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          22,
          24,
          20 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SheetActionButton(
                    label: 'Cancel',
                    background: AppColors.card,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SheetActionButton(
                    label: confirmLabel,
                    background: confirmColor,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  const _SheetActionButton({
    required this.label,
    required this.background,
    required this.onTap,
  });

  final String label;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          height: 50,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
