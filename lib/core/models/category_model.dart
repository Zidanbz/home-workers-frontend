import 'package:flutter/material.dart';

// Enhanced category icons mapping with more comprehensive coverage
final Map<String, IconData> categoryIcons = {
  // Cleaning Services
  "cleaning_services": Icons.cleaning_services,
  "kebersihan": Icons.cleaning_services,
  "house_cleaning": Icons.cleaning_services,

  // Repair & Maintenance
  "handyman": Icons.handyman,
  "perbaikan": Icons.build_outlined,
  "home_repair_service": Icons.home_repair_service,
  "maintenance": Icons.build_circle_outlined,

  // Electrical Services
  "electrical_services": Icons.electrical_services,
  "listrik": Icons.electrical_services,
  "electric": Icons.bolt,

  // Plumbing
  "plumbing": Icons.plumbing,
  "air": Icons.water_drop,
  "water_services": Icons.water,

  // Construction & Home Improvement
  "construction": Icons.construction,
  "home_improvement": Icons.cottage_outlined,
  "renovation": Icons.home_work,
  "building": Icons.apartment,

  // Automotive
  "directions_car": Icons.directions_car,
  "automotive": Icons.car_repair,
  "vehicle": Icons.directions_car,

  // Gardening & Landscaping
  "local_florist": Icons.local_florist,
  "gardening": Icons.grass,
  "landscaping": Icons.park,

  // Technology & Electronics
  "phone_android": Icons.phone_android,
  "technology": Icons.computer,
  "electronics": Icons.devices,
  "it_services": Icons.laptop_mac,

  // Beauty & Personal Care
  "beauty": Icons.face_retouching_natural,
  "personal_care": Icons.spa,
  "salon": Icons.content_cut,

  // Education & Training
  "education": Icons.school,
  "tutoring": Icons.menu_book,
  "training": Icons.psychology,

  // Health & Wellness
  "health": Icons.health_and_safety,
  "medical": Icons.medical_services,
  "fitness": Icons.fitness_center,

  // Food & Catering
  "food": Icons.restaurant,
  "catering": Icons.dining,
  "cooking": Icons.kitchen,

  // Transportation & Delivery
  "delivery": Icons.delivery_dining,
  "transportation": Icons.local_shipping,
  "logistics": Icons.local_shipping,

  // Security & Safety
  "security": Icons.security,
  "safety": Icons.shield,
  "guard": Icons.verified_user,

  // Pet Services
  "pets": Icons.pets,
  "veterinary": Icons.pets,
  "pet_care": Icons.favorite,

  // Event Services
  "events": Icons.event,
  "party": Icons.celebration,
  "wedding": Icons.favorite,

  // Default fallback
  "download": Icons.download,
  "other": Icons.category,
  "default": Icons.work_outline,
};

// Predefined categories with proper Indonesian names
class CategoryData {
  static const List<Map<String, dynamic>> predefinedCategories = [
    {
      'name': 'Kebersihan',
      'icon': 'kebersihan',
      'description': 'Layanan pembersihan rumah, kantor, dan area lainnya',
      'keywords': ['bersih', 'cleaning', 'housekeeping', 'sanitasi'],
    },
    {
      'name': 'Perbaikan',
      'icon': 'perbaikan',
      'description': 'Perbaikan peralatan rumah tangga dan infrastruktur',
      'keywords': ['repair', 'fix', 'maintenance', 'service'],
    },
    {
      'name': 'Home Improvement',
      'icon': 'home_improvement',
      'description': 'Renovasi dan peningkatan kualitas rumah',
      'keywords': ['renovasi', 'upgrade', 'improvement', 'remodel'],
    },
    {
      'name': 'Listrik',
      'icon': 'listrik',
      'description': 'Instalasi dan perbaikan sistem kelistrikan',
      'keywords': ['electrical', 'wiring', 'power', 'voltage'],
    },
    {
      'name': 'Plumbing',
      'icon': 'plumbing',
      'description': 'Perbaikan dan instalasi sistem air',
      'keywords': ['air', 'pipa', 'water', 'drain', 'toilet'],
    },
    {
      'name': 'Konstruksi',
      'icon': 'construction',
      'description': 'Pembangunan dan konstruksi bangunan',
      'keywords': ['build', 'construction', 'structure', 'foundation'],
    },
    {
      'name': 'Otomotif',
      'icon': 'automotive',
      'description': 'Perawatan dan perbaikan kendaraan',
      'keywords': ['mobil', 'motor', 'car', 'vehicle', 'automotive'],
    },
    {
      'name': 'Taman & Landscaping',
      'icon': 'gardening',
      'description': 'Perawatan taman dan desain landscape',
      'keywords': ['garden', 'plants', 'landscape', 'outdoor'],
    },
    {
      'name': 'Teknologi',
      'icon': 'technology',
      'description': 'Layanan IT dan teknologi',
      'keywords': ['computer', 'software', 'hardware', 'IT', 'tech'],
    },
    {
      'name': 'Kecantikan',
      'icon': 'beauty',
      'description': 'Layanan kecantikan dan perawatan diri',
      'keywords': ['beauty', 'salon', 'makeup', 'skincare'],
    },
  ];

  static List<String> getCategoryNames() {
    return predefinedCategories.map((cat) => cat['name'] as String).toList();
  }

  static IconData getIconForCategory(String categoryName) {
    final category = predefinedCategories.firstWhere(
      (cat) => cat['name'] == categoryName,
      orElse: () => {'icon': 'default'},
    );
    return categoryIcons[category['icon']] ?? Icons.work_outline;
  }

  static String getDescriptionForCategory(String categoryName) {
    final category = predefinedCategories.firstWhere(
      (cat) => cat['name'] == categoryName,
      orElse: () => {'description': 'Layanan profesional'},
    );
    return category['description'] as String;
  }
}

class Category {
  final String name;
  final IconData icon;
  final String workerCount;
  final String? description;

  Category({
    required this.name,
    required this.icon,
    required this.workerCount,
    this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final categoryName = json['name'] ?? '';
    return Category(
      name: categoryName,
      workerCount: json['serviceCount']?.toString() ?? '0',
      description:
          json['description'] ??
          CategoryData.getDescriptionForCategory(categoryName),
      icon: _getIconFromJson(json, categoryName),
    );
  }

  static IconData _getIconFromJson(
    Map<String, dynamic> json,
    String categoryName,
  ) {
    // Try to get icon from JSON first
    if (json['icon'] != null) {
      final iconFromJson = categoryIcons[json['icon']];
      if (iconFromJson != null) return iconFromJson;
    }

    // Try to match by category name
    final iconByName = CategoryData.getIconForCategory(categoryName);
    if (iconByName != Icons.work_outline) return iconByName;

    // Try to match by lowercase category name
    final lowerCaseName = categoryName.toLowerCase();
    final iconByLowerCase = categoryIcons[lowerCaseName];
    if (iconByLowerCase != null) return iconByLowerCase;

    // Fallback to default
    return Icons.category;
  }

  // Helper method to get icon for any category string
  static IconData getIconForCategoryString(String category) {
    final lowerCategory = category.toLowerCase();

    // Direct match
    if (categoryIcons.containsKey(lowerCategory)) {
      return categoryIcons[lowerCategory]!;
    }

    // Partial match for common categories
    if (lowerCategory.contains('bersih') || lowerCategory.contains('clean')) {
      return Icons.cleaning_services;
    }
    if (lowerCategory.contains('perbaik') || lowerCategory.contains('repair')) {
      return Icons.build_outlined;
    }
    if (lowerCategory.contains('listrik') ||
        lowerCategory.contains('electric')) {
      return Icons.electrical_services;
    }
    if (lowerCategory.contains('air') || lowerCategory.contains('plumb')) {
      return Icons.plumbing;
    }
    if (lowerCategory.contains('taman') || lowerCategory.contains('garden')) {
      return Icons.grass;
    }
    if (lowerCategory.contains('mobil') ||
        lowerCategory.contains('car') ||
        lowerCategory.contains('motor')) {
      return Icons.car_repair;
    }
    if (lowerCategory.contains('teknologi') ||
        lowerCategory.contains('tech') ||
        lowerCategory.contains('komputer')) {
      return Icons.computer;
    }
    if (lowerCategory.contains('cantik') ||
        lowerCategory.contains('beauty') ||
        lowerCategory.contains('salon')) {
      return Icons.face_retouching_natural;
    }

    // Default fallback
    return Icons.work_outline;
  }
}
