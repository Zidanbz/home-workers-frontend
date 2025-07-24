class User {
  final String uid;
  final String nama;
  final String email;
  final String role;
  final String? avatarUrl;
  final String? contact;
  final bool emailVerified; // ✅ Tambahan

  User({
    required this.uid,
    required this.nama,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.contact,
    this.emailVerified = false, // default false
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      nama: json['nama'] ?? 'Tanpa Nama',
      email: json['email'] ?? '',
      role: json['role'] ?? 'CUSTOMER',
      avatarUrl: json['avatarUrl'],
      contact: json['contact'],
      emailVerified: json['emailVerified'] ?? false, // ✅ Ambil dari backend
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'nama': nama,
      'email': email,
      'role': role,
      'avatarUrl': avatarUrl,
      'contact': contact,
      'emailVerified': emailVerified,
    };
  }

  User copyWith({
    String? nama,
    String? email,
    String? role,
    String? avatarUrl,
    String? contact,
    bool? emailVerified,
  }) {
    return User(
      uid: uid,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      contact: contact ?? this.contact,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }
}
