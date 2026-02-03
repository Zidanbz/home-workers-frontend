import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const Color _primaryColor = Color(0xFF1A374D);
const Object _noTapGuardTag = Object();

class NoTapGuard extends StatelessWidget {
  final Widget child;

  const NoTapGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MetaData(
      metaData: _noTapGuardTag,
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}

class GlobalTapGuard extends StatefulWidget {
  final Widget child;
  final Duration lockDuration;

  const GlobalTapGuard({
    super.key,
    required this.child,
    this.lockDuration = const Duration(milliseconds: 700),
  });

  @override
  State<GlobalTapGuard> createState() => _GlobalTapGuardState();
}

class _GlobalTapGuardState extends State<GlobalTapGuard> {
  static const double _tapSlop = 10;

  Offset? _downPosition;
  bool _movedTooFar = false;
  bool _ignoreTap = false;
  bool _locked = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startLock() {
    if (_locked) return;
    setState(() => _locked = true);
    _timer?.cancel();
    _timer = Timer(widget.lockDuration, () {
      if (!mounted) return;
      setState(() => _locked = false);
    });
  }

  void _handlePointerDown(PointerDownEvent event) {
    _downPosition = event.position;
    _movedTooFar = false;
    _ignoreTap = _isTapGuardDisabled(event.position);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_downPosition == null) return;
    if ((event.position - _downPosition!).distance > _tapSlop) {
      _movedTooFar = true;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_movedTooFar) return;
    if (_ignoreTap) return;
    _startLock();
  }

  bool _isTapGuardDisabled(Offset position) {
    final hitTestResult = HitTestResult();
    WidgetsBinding.instance.hitTest(hitTestResult, position);
    for (final entry in hitTestResult.path) {
      final target = entry.target;
      if (target is RenderMetaData && identical(target.metaData, _noTapGuardTag)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _handlePointerDown,
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerUp,
          child: AbsorbPointer(
            absorbing: _locked,
            child: widget.child,
          ),
        ),
        AnimatedOpacity(
          opacity: _locked ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: IgnorePointer(
            child: _LoadingOverlay(visible: _locked),
          ),
        ),
      ],
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  final bool visible;

  const _LoadingOverlay({required this.visible});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: Container(
            color: Colors.black.withOpacity(0.03),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 160),
              scale: visible ? 1 : 0.95,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: const AlwaysStoppedAnimation(_primaryColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Memuat',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
