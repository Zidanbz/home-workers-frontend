import 'package:flutter/material.dart';

class BadgeWidget extends StatelessWidget {
  final Widget child;
  final int count;
  final Color? badgeColor;
  final Color? textColor;
  final double? size;
  final bool showZero;

  const BadgeWidget({
    super.key,
    required this.child,
    required this.count,
    this.badgeColor,
    this.textColor,
    this.size,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0 || showZero)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: EdgeInsets.all(count > 99 ? 4 : 6),
              decoration: BoxDecoration(
                color: badgeColor ?? Colors.red,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                minWidth: size ?? 20,
                minHeight: size ?? 20,
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: count > 99 ? 10 : 12,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class DotBadgeWidget extends StatelessWidget {
  final Widget child;
  final bool show;
  final Color? color;
  final double? size;

  const DotBadgeWidget({
    super.key,
    required this.child,
    required this.show,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (show)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: size ?? 12,
              height: size ?? 12,
              decoration: BoxDecoration(
                color: color ?? Colors.red,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
