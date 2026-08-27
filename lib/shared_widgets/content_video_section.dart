import 'package:flutter/material.dart';
import 'package:home_workers_fe/core/models/content_video_model.dart';

import 'content_video_card.dart';

typedef ContentVideoCardBuilder = Widget Function(ContentVideo video, Key key);

class ContentVideoSection extends StatefulWidget {
  const ContentVideoSection({
    super.key,
    required this.videos,
    this.videoCardBuilder,
  });

  final List<ContentVideo> videos;

  /// Dipakai oleh test untuk mengganti player dengan widget ringan.
  final ContentVideoCardBuilder? videoCardBuilder;

  @override
  State<ContentVideoSection> createState() => _ContentVideoSectionState();
}

class _ContentVideoSectionState extends State<ContentVideoSection> {
  String? _selectedVideoId;

  ContentVideo get _selectedVideo {
    final selectedId = _selectedVideoId;
    return widget.videos.firstWhere(
      (video) => video.id == selectedId,
      orElse: () => widget.videos.first,
    );
  }

  @override
  void didUpdateWidget(covariant ContentVideoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedVideoId != null &&
        !widget.videos.any((video) => video.id == _selectedVideoId)) {
      _selectedVideoId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videos.isEmpty) return const SizedBox.shrink();

    final selected = _selectedVideo;
    final cardKey = ValueKey('content-video-${selected.id}');
    final customBuilder = widget.videoCardBuilder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F5F2),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.ondemand_video_outlined,
                color: Color(0xFF00897B),
                size: 20,
              ),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Video Pilihan',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF12364D),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Panduan, tips, dan informasi untuk mendukung aktivitas Anda.',
                    style: TextStyle(
                      color: Color(0xFF6B7B87),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        customBuilder != null
            ? customBuilder(selected, cardKey)
            : ContentVideoCard(key: cardKey, video: selected),
        if (widget.videos.length > 1) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.videos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final video = widget.videos[index];
                final isSelected = video.id == selected.id;
                return Material(
                  color: isSelected
                      ? const Color(0xFF1A374D)
                      : const Color(0xFFF3F5F7),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    key: ValueKey('content-video-option-${video.id}'),
                    onTap: () => setState(() => _selectedVideoId = video.id),
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 190,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.play_circle_outline_rounded,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF1A374D),
                              size: 25,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    video.categoryLabel,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white70
                                          : Colors.grey.shade600,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    video.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF1A374D),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
