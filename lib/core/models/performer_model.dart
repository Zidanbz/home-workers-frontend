class Performer {
  // final String id;
  final String name;
  final String avatarUrl;
  final double rating;

  Performer({
    // required this.id,
    required this.name,
    required this.avatarUrl,
    required this.rating,
  });

  static String _publicAvatarUrl(dynamic value) {
    if (value is! String) return '';
    final candidate = value.trim();
    final uri = Uri.tryParse(candidate);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return '';
    return candidate;
  }

  factory Performer.fromJson(Map<String, dynamic> json) {
    return Performer(
      // id: json['id'] ?? '',
      name: json['nama'] ?? 'No Name',
      // Selfie KYC (`fotoDiriUrl`) bukan media profil publik.
      avatarUrl: _publicAvatarUrl(json['avatarUrl']),
      rating: (json['rating'] ?? 0.0).toDouble(),
    );
  }
}
