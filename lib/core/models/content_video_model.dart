class ContentVideo {
  const ContentVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.videoId,
    required this.category,
    required this.audience,
    required this.sortOrder,
  });

  final String id;
  final String title;
  final String description;
  final String videoId;
  final String category;
  final String audience;
  final int sortOrder;

  String get thumbnailUrl => 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

  String get categoryLabel => switch (category) {
    'tutorial' => 'Tutorial',
    'tips_trik' => 'Tips & Trik',
    'keselamatan' => 'Keselamatan',
    _ => 'Informasi',
  };

  factory ContentVideo.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString().trim() ?? '';
    final title = json['title']?.toString().trim() ?? '';
    final videoId = json['videoId']?.toString().trim() ?? '';
    final sortOrder = _readSortOrder(json['sortOrder']);

    if (id.isEmpty || title.length < 3) {
      throw const FormatException('Data konten video tidak lengkap.');
    }
    if (!RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(videoId)) {
      throw const FormatException('ID video YouTube tidak valid.');
    }

    return ContentVideo(
      id: id,
      title: title,
      description: json['description']?.toString().trim() ?? '',
      videoId: videoId,
      category:
          json['category']?.toString().trim().toLowerCase() ?? 'informasi',
      audience: json['audience']?.toString().trim().toLowerCase() ?? 'worker',
      sortOrder: sortOrder,
    );
  }

  static int _readSortOrder(dynamic value) {
    final parsed = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed < 0 || parsed > 9999) return 0;
    return parsed;
  }
}
