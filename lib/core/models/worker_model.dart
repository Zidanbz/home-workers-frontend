class Worker {
  final String id;
  final String nama;
  final String email;
  final String? avatarUrl;
  final String? ktpUrl;
  final String? linkPortofolio;
  final List<String> keahlian;
  // final int experience;
  final double rating;
  final int totalReviews;
  final int totalOrders;
  final String bio;

  Worker({
    required this.id,
    required this.nama,
    required this.email,
    this.avatarUrl,
    this.ktpUrl,
    this.linkPortofolio,
    this.keahlian = const [],
    // required this.experience,
    required this.rating,
    required this.totalReviews,
    required this.totalOrders,
    required this.bio,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['id'] ?? '',
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['fotoDiriUrl'],
      ktpUrl: json['ktpUrl'],
      linkPortofolio: json['linkPortofolio'],
      keahlian: List<String>.from(json['keahlian'] ?? []),
      // experience: (json['experience'] ?? 0) is int
      //     ? json['experience']
      //     : int.tryParse(json['experience'].toString()) ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews:
          json['totalReviews'] ?? 0, // Firestore tidak ada → default 0
      totalOrders: json['jumlahOrderSelesai'] ?? 0,
      bio: json['deskripsi'] ?? '',
    );
  }
}
