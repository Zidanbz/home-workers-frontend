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

  factory Performer.fromJson(Map<String, dynamic> json) {
    return Performer(
      // id: json['id'] ?? '',
      name: json['nama'] ?? 'No Name',
      // ✅ PERBAIKAN: Ambil dari 'fotoDiriUrl'
      avatarUrl: json['fotoDiriUrl'] ?? 'https://via.placeholder.com/150',
      rating: (json['rating'] ?? 0.0).toDouble(),
    );
  }
}
