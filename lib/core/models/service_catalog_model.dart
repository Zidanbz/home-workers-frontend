class ServiceCatalogGroup {
  const ServiceCatalogGroup({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final int sortOrder;

  factory ServiceCatalogGroup.fromJson(Map<String, dynamic> json) {
    return ServiceCatalogGroup(
      id: (json['id'] ?? json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      sortOrder: int.tryParse(json['sortOrder']?.toString() ?? '') ?? 0,
    );
  }
}

class ServiceCatalogAsset {
  const ServiceCatalogAsset({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final int sortOrder;

  factory ServiceCatalogAsset.fromJson(Map<String, dynamic> json) {
    return ServiceCatalogAsset(
      id: (json['id'] ?? json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      sortOrder: int.tryParse(json['sortOrder']?.toString() ?? '') ?? 0,
    );
  }
}

class ServiceCatalogItem {
  const ServiceCatalogItem({
    required this.id,
    required this.name,
    required this.groupId,
    required this.assetId,
    required this.allowedServiceTypes,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String groupId;
  final String assetId;
  final List<String> allowedServiceTypes;
  final int sortOrder;

  bool allows(String type) => allowedServiceTypes.contains(type);

  factory ServiceCatalogItem.fromJson(Map<String, dynamic> json) {
    return ServiceCatalogItem(
      id: (json['id'] ?? json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      groupId: (json['groupId'] ?? '').toString(),
      assetId: (json['assetId'] ?? '').toString(),
      allowedServiceTypes: List<String>.from(
        json['allowedServiceTypes'] as List? ?? const [],
      ),
      sortOrder: int.tryParse(json['sortOrder']?.toString() ?? '') ?? 0,
    );
  }
}

class ServiceCatalog {
  const ServiceCatalog({
    required this.taxonomyVersion,
    required this.groups,
    required this.assets,
    required this.items,
  });

  final int taxonomyVersion;
  final List<ServiceCatalogGroup> groups;
  final List<ServiceCatalogAsset> assets;
  final List<ServiceCatalogItem> items;

  factory ServiceCatalog.fromJson(Map<String, dynamic> json) {
    T parse<T>(dynamic source, T Function(Map<String, dynamic>) factory) {
      return factory(Map<String, dynamic>.from(source as Map));
    }

    return ServiceCatalog(
      taxonomyVersion:
          int.tryParse(json['taxonomyVersion']?.toString() ?? '') ?? 1,
      groups: (json['groups'] as List? ?? const [])
          .whereType<Map>()
          .map((value) => parse(value, ServiceCatalogGroup.fromJson))
          .toList(growable: false),
      assets: (json['assets'] as List? ?? const [])
          .whereType<Map>()
          .map((value) => parse(value, ServiceCatalogAsset.fromJson))
          .toList(growable: false),
      items: (json['items'] as List? ?? const [])
          .whereType<Map>()
          .map((value) => parse(value, ServiceCatalogItem.fromJson))
          .toList(growable: false),
    );
  }
}
