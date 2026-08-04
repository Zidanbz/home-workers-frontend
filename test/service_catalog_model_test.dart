import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/models/service_catalog_model.dart';

void main() {
  test('mem-parsing hierarchy katalog dan tipe layanan yang diizinkan', () {
    final catalog = ServiceCatalog.fromJson({
      'taxonomyVersion': 1,
      'groups': [
        {'id': 'REPAIR', 'name': 'Perbaikan', 'sortOrder': 10},
      ],
      'assets': [
        {'id': 'AC', 'name': 'AC', 'sortOrder': 10},
      ],
      'items': [
        {
          'id': 'REPAIR_AC',
          'name': 'Perbaikan AC',
          'groupId': 'REPAIR',
          'assetId': 'AC',
          'allowedServiceTypes': ['survey'],
          'sortOrder': 10,
        },
      ],
    });

    expect(catalog.groups.single.name, 'Perbaikan');
    expect(catalog.assets.single.name, 'AC');
    expect(catalog.items.single.groupId, 'REPAIR');
    expect(catalog.items.single.allows('survey'), isTrue);
    expect(catalog.items.single.allows('fixed'), isFalse);
  });
}
