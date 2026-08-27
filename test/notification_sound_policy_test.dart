import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/utils/notification_sound_policy.dart';

void main() {
  test('new order memakai channel dan suara order khusus', () {
    expect(
      notificationChannelIdFor('new_order'),
      newOrderNotificationChannelId,
    );
    expect(
      notificationSoundResourceFor('new_order'),
      newOrderNotificationSoundResource,
    );
  });

  test('notifikasi selain new order memakai channel dan suara general', () {
    for (final type in ['chat', 'order_update', 'broadcast', null]) {
      expect(notificationChannelIdFor(type), generalNotificationChannelId);
      expect(
        notificationSoundResourceFor(type),
        generalNotificationSoundResource,
      );
    }
  });
}
