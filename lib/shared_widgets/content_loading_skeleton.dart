import 'package:flutter/material.dart';

enum ContentSkeletonVariant { list, dashboard }

/// Skeleton ringan tanpa dependency tambahan. Animasi dihormati oleh
/// MediaQuery.disableAnimations agar tetap ramah aksesibilitas.
class ContentLoadingSkeleton extends StatefulWidget {
  const ContentLoadingSkeleton({
    super.key,
    this.variant = ContentSkeletonVariant.list,
    this.itemCount = 3,
    this.scrollable = true,
    this.padding = const EdgeInsets.all(16),
  });

  final ContentSkeletonVariant variant;
  final int itemCount;
  final bool scrollable;
  final EdgeInsetsGeometry padding;

  @override
  State<ContentLoadingSkeleton> createState() => _ContentLoadingSkeletonState();
}

class _ContentLoadingSkeletonState extends State<ContentLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final progress = disableAnimations == true ? 0.5 : _animation.value;
        final color = Color.lerp(
          const Color(0xFFE7ECF0),
          const Color(0xFFF5F7F9),
          progress,
        )!;
        final children = widget.variant == ContentSkeletonVariant.dashboard
            ? _dashboardChildren(color)
            : List<Widget>.generate(
                widget.itemCount,
                (index) => _listCard(color),
              );

        if (!widget.scrollable) {
          return Padding(
            key: const ValueKey('content-loading-skeleton'),
            padding: widget.padding,
            child: Column(children: children),
          );
        }

        return ListView(
          key: const ValueKey('content-loading-skeleton'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: widget.padding,
          children: children,
        );
      },
    );
  }

  List<Widget> _dashboardChildren(Color color) => [
    Row(
      children: [
        Expanded(child: _box(color, height: 92)),
        const SizedBox(width: 12),
        Expanded(child: _box(color, height: 92)),
      ],
    ),
    const SizedBox(height: 28),
    Align(child: _box(color, height: 20, width: 180)),
    const SizedBox(height: 14),
    _box(color, height: 110),
    const SizedBox(height: 28),
    Align(child: _box(color, height: 20, width: 150)),
    const SizedBox(height: 14),
    _listCard(color),
  ];

  Widget _listCard(Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E9ED)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _box(color, height: 54, width: 54, radius: 16),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(color, height: 16, width: 190),
                const SizedBox(height: 10),
                _box(color, height: 13),
                const SizedBox(height: 8),
                _box(color, height: 13, width: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _box(
    Color color, {
    required double height,
    double? width,
    double radius = 10,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
