import 'package:flutter/material.dart';
import 'package:home_workers_fe/core/models/content_video_model.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

typedef ContentVideoPlayerBuilder = Widget Function(BuildContext context);

class ContentVideoCard extends StatefulWidget {
  const ContentVideoCard({super.key, required this.video, this.playerBuilder});

  final ContentVideo video;

  /// Dapat diinjeksi oleh test agar tidak membuat platform WebView sungguhan.
  final ContentVideoPlayerBuilder? playerBuilder;

  @override
  State<ContentVideoCard> createState() => _ContentVideoCardState();
}

class _ContentVideoCardState extends State<ContentVideoCard> {
  static const Color _primaryColor = Color(0xFF1A374D);

  YoutubePlayerController? _controller;
  bool _showPlayer = false;

  void _playInline() {
    if (_showPlayer) return;

    if (widget.playerBuilder == null) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: widget.video.videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          playsInline: true,
          enableCaption: true,
          interfaceLanguage: 'id',
          privacyEnhancedMode: true,
          strictRelatedVideos: true,
        ),
      );
    }

    setState(() => _showPlayer = true);
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _showPlayer ? _buildPlayer() : _buildThumbnailCard(),
      ),
    );
  }

  Widget _buildPlayer() {
    final customPlayer = widget.playerBuilder;
    if (customPlayer != null) {
      return KeyedSubtree(
        key: const ValueKey('content-video-inline-player'),
        child: AspectRatio(aspectRatio: 16 / 9, child: customPlayer(context)),
      );
    }

    return Semantics(
      label: '${widget.video.title} sedang diputar di dalam aplikasi',
      child: YoutubePlayer(
        key: const ValueKey('content-video-inline-player'),
        controller: _controller!,
        aspectRatio: 16 / 9,
      ),
    );
  }

  Widget _buildThumbnailCard() {
    return Semantics(
      button: true,
      excludeSemantics: true,
      label:
          'Putar ${widget.video.title} di dalam aplikasi. '
          '${widget.video.description}',
      onTap: _playInline,
      child: Material(
        key: const ValueKey('content-video-thumbnail'),
        color: Colors.transparent,
        child: InkWell(
          onTap: _playInline,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildThumbnail(),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x26000000),
                        Color(0x33000000),
                        Color(0xD91A374D),
                      ],
                      stops: [0, 0.45, 1],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF0000),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF0000),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.smart_display_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'YouTube',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.video.categoryLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        widget.video.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.video.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          widget.video.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return Image.network(
      widget.video.thumbnailUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildThumbnailFallback(),
    );
  }

  Widget _buildThumbnailFallback() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryColor, Color(0xFF2A4A5F)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.ondemand_video_rounded,
          color: Color(0x66FFFFFF),
          size: 92,
        ),
      ),
    );
  }
}
