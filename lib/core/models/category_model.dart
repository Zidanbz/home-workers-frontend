import 'package:flutter/material.dart';

final Map<String, IconData> categoryIcons = {
  "cleaning_services": Icons.cleaning_services,
  "handyman": Icons.handyman,
  "download": Icons.download,
  "home_repair_service": Icons.home_repair_service,
  "electrical_services": Icons.electrical_services,
  "directions_car": Icons.directions_car,
  "local_florist": Icons.local_florist,
  "construction": Icons.construction,
  "phone_android": Icons.phone_android,
};

class Category {
  final String name;
  final IconData icon;
  final String workerCount;

  Category({required this.name, required this.icon, required this.workerCount});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    name: json['name'] ?? '',
    workerCount: json['serviceCount'] ?? '',
    icon:
        categoryIcons[json['icon']] ??
        Icons.category, // fallback jika ikon tidak ditemukan
  );
}
