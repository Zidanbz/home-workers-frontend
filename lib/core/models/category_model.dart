import 'package:flutter/material.dart';

class CategoryItem {
  final String name;
  final IconData icon;

  CategoryItem(this.name, this.icon);
}

final List<CategoryItem> categories = [
  CategoryItem("Kebersihan", Icons.cleaning_services),
  CategoryItem("Perbaikan", Icons.handyman),
  CategoryItem("Instalasi", Icons.download),
  CategoryItem("Renovasi", Icons.home_repair_service),
  CategoryItem("Elektronik", Icons.electrical_services),
  CategoryItem("Otomotif", Icons.directions_car),
  CategoryItem("Perawatan Taman", Icons.local_florist),
  CategoryItem("Pembangunan", Icons.construction),
  CategoryItem("Gadget", Icons.phone_android),
];

class Category {
  final String name;
  final IconData icon;
  final String workerCount;
  Category({required this.name, required this.icon, required this.workerCount});
  factory Category.fromJson(Map<String, dynamic> json) => Category(
    name: json['name'] ?? '',
    workerCount: json['workerCount'] ?? '',
    icon: Icons.work, // Default icon
  );
}
