class Address {
  final String id;
  final String label;
  final String fullAddress;
  // Anda bisa tambahkan latitude dan longitude jika perlu

  Address({required this.id, required this.label, required this.fullAddress});

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] ?? '',
      label: json['label'] ?? 'Tanpa Label',
      fullAddress: json['fullAddress'] ?? 'Alamat tidak lengkap',
    );
  }
}
