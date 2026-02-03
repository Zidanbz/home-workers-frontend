import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

const Color _primaryColor = Color(0xFF1A374D);

class ActionTapGuard {
  static bool _busy = false;
  static OverlayEntry? _entry;

  static Future<void> run(
    BuildContext context,
    Future<void> Function() action, {
    Duration minDuration = const Duration(milliseconds: 450),
    String label = 'Memuat',
  }) async {
    if (_busy) return;
    _busy = true;
    _showOverlay(context, label);

    final start = DateTime.now();
    try {
      await action();
    } finally {
      final elapsed = DateTime.now().difference(start);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }
      _hideOverlay();
      _busy = false;
    }
  }

  static void _showOverlay(BuildContext context, String label) {
    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) return;
    _entry?.remove();
    _entry = OverlayEntry(
      builder: (_) => _ActionLoadingPill(label: label),
    );
    overlay.insert(_entry!);
  }

  static void _hideOverlay() {
    _entry?.remove();
    _entry = null;
  }
}

class _ActionLoadingPill extends StatelessWidget {
  final String label;

  const _ActionLoadingPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(
            color: Colors.black.withOpacity(0.06),
          ),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor: const AlwaysStoppedAnimation(_primaryColor),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Tunggu sebentar yaa',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
