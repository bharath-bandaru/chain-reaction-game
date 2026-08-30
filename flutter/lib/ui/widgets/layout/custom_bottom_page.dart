import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../common/ui_kit.dart' show isTabletLayout;

/// Bottom-sheet page route ported from the roamates app: slides up over a
/// fading barrier (450ms in / 350ms out, cubic easing).
class CustomBottomPage<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Color? barrierColorOverride;
  final bool isDismissible;

  CustomBottomPage({
    required this.child,
    this.barrierColorOverride,
    this.isDismissible = true,
  }) : super(
         opaque: false,
         barrierColor: Colors.black54,
         pageBuilder: (context, animation, secondaryAnimation) => child,
         transitionDuration: const Duration(milliseconds: 450),
         reverseTransitionDuration: const Duration(milliseconds: 350),
       );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return Stack(
      children: [
        FadeTransition(
          opacity: animation,
          child: ModalBarrier(
            color: barrierColorOverride ?? const Color.fromARGB(167, 0, 0, 0),
            dismissible: false,
          ),
        ),
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      ],
    );
  }

  @override
  bool get barrierDismissible => isDismissible;
  @override
  Color? get barrierColor => barrierColorOverride;
  @override
  String? get barrierLabel => 'Dismiss';
  @override
  bool get maintainState => true;
}

/// Sheet chrome ported from roamates' `CustomBottomSheetScaffold`:
/// drag-to-dismiss (20% of screen height or a >300px/s flick), dampened
/// elastic over-drag upward with a smooth spring-back, tap-outside dismiss,
/// and a floating handle. The rounded top keeps a subtle rim-light border
/// that follows the corner curve (the "top corner shine").
class CustomBottomSheetScaffold extends StatefulWidget {
  final Widget child;
  final double minHeightFactor;
  final double maxHeightFactor;
  final bool hideHandle;
  final bool dismissible;

  const CustomBottomSheetScaffold({
    super.key,
    required this.child,
    this.minHeightFactor = 0.1,
    this.maxHeightFactor = 0.85,
    this.hideHandle = true,
    this.dismissible = true,
  });

  @override
  State<CustomBottomSheetScaffold> createState() =>
      _CustomBottomSheetScaffoldState();
}

class _CustomBottomSheetScaffoldState extends State<CustomBottomSheetScaffold>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  AnimationController? _springBackController;
  double _dragOffset = 0.0;
  bool _dismissed = false;

  /// Dismiss when dragged 20% of the screen height.
  static const double _dismissThreshold = 0.2;

  /// Max upward elastic stretch.
  static const double _maxElasticOffset = 720.0;

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    FocusManager.instance.primaryFocus?.unfocus();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _springBackController?.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta;
    if (delta == null) return;
    setState(() {
      _dragOffset = (_dragOffset + delta).clamp(
        -_maxElasticOffset,
        double.infinity,
      );
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isFlickDown =
        details.primaryVelocity != null && details.primaryVelocity! > 300;

    if (widget.dismissible &&
        (_dragOffset > screenHeight * _dismissThreshold || isFlickDown)) {
      _controller.duration = const Duration(milliseconds: 200);
      _controller.forward().whenComplete(_dismiss);
    } else if (_dragOffset != 0) {
      // Smooth spring-back to rest.
      _springBackController?.dispose();
      _springBackController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 250),
      );
      final offsetAnimation = Tween<double>(begin: _dragOffset, end: 0.0)
          .animate(
            CurvedAnimation(
              parent: _springBackController!,
              curve: Curves.easeOutCubic,
            ),
          );
      offsetAnimation.addListener(() {
        if (mounted) setState(() => _dragOffset = offsetAnimation.value);
      });
      _springBackController!.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Tappable background for dismissing.
          GestureDetector(
            onTap: widget.dismissible ? _dismiss : null,
            child: Container(color: Colors.transparent),
          ),

          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final screenHeight = MediaQuery.sizeOf(context).height;
              final animatedOffset = screenHeight * _controller.value;
              // Upward over-drag is dampened for the elastic feel.
              final effectiveOffset = _dragOffset < 0
                  ? _dragOffset * 0.5
                  : _dragOffset;
              final isTablet = isTabletLayout(context);

              return Stack(
                children: [
                  // Cover behind the sheet so an upward stretch never shows
                  // the barrier through the bottom gap. Matches the sheet's
                  // #191919 tint. Hidden on tablets, where the sheet floats
                  // with fully rounded corners.
                  if (!isTablet)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      top:
                          screenHeight - (0 - effectiveOffset - animatedOffset),
                      child: Container(color: AppColors.background),
                    ),
                  Positioned(
                    // Float above the bottom edge on tablets.
                    bottom:
                        (isTablet ? 40 : 0) - effectiveOffset - animatedOffset,
                    left: 0,
                    right: 0,
                    child: Material(
                      color: Colors.transparent,
                      elevation: 0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: _handleDragUpdate,
                        onVerticalDragEnd: _handleDragEnd,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!widget.hideHandle) _buildHandle(),
                            _buildSheetContent(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 36,
      height: 5,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }

  Widget _buildSheetContent(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topPadding = MediaQuery.viewPaddingOf(context).top;
    final isTablet = isTabletLayout(context);

    // On tablets the sheet is narrower, centered, and capped lower — same
    // treatment as roamates.
    const maxSheetWidth = 500.0;
    final sheetWidth = isTablet ? maxSheetWidth : size.width;
    final effectiveMaxHeightFactor = isTablet
        ? (widget.maxHeightFactor > 0.65 ? 0.65 : widget.maxHeightFactor)
        : widget.maxHeightFactor;

    final maxAllowed = (size.height - topPadding - 24).clamp(0.0, size.height);
    final maxHeight = (size.height * effectiveMaxHeightFactor).clamp(
      0.0,
      maxAllowed,
    );
    final minHeight = (size.height * widget.minHeightFactor).clamp(
      0.0,
      maxHeight,
    );

    // Surface visuals (glass tint, clip, rounding) belong to the child's
    // `SheetSurface`; this scaffold only provides the roamates route/drag
    // mechanics and the size constraints.
    return SizedBox(
      width: sheetWidth,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight, maxHeight: maxHeight),
        child: NotificationListener<ScrollNotification>(
          // Prevents drag conflicts with scrollables inside the sheet:
          // the sheet only takes over when the inner scroll sits at its top.
          onNotification: (notification) {
            if (notification.metrics.axis != Axis.vertical) return false;
            return notification.metrics.pixels > 0;
          },
          child: widget.child,
        ),
      ),
    );
  }
}
