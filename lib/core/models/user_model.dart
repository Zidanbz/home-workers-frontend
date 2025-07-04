class User {
  final String uid;
  final String nama;
  final String email;
  final String role;
  final String? avatarUrl; // <-- PERUBAHAN 1: Tambahkan field baru (opsional)
  final String? contact;

  User({
    required this.uid,
    required this.nama,
    required this.email,
    required this.role,
    this.avatarUrl, // <-- Tambahkan di constructor
    this.contact,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      nama: json['nama'] ?? 'Tanpa Nama',
      email: json['email'] ?? '',
      role: json['role'] ?? 'CUSTOMER',
      avatarUrl:
          json['avatarUrl'], // <-- PERUBAHAN 2: Ambil data avatar dari JSON
      contact: json['contact'],
    );
  }
}
