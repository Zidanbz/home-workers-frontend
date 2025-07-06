class Performer {
  final String name;
  final String avatarUrl;
  final double rating;
  Performer({
    required this.name,
    required this.avatarUrl,
    required this.rating,
  });
  factory Performer.fromJson(Map<String, dynamic> json) => Performer(
    name: json['nama'] ?? '',
    avatarUrl: json['avatarUrl'] ?? 'https://i.pravatar.cc/150',
    rating: (json['rating'] ?? 0).toDouble(),
  );
}
