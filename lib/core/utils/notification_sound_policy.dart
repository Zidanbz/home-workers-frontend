const generalNotificationChannelId = 'home_workers_general_v2';
const newOrderNotificationChannelId = 'home_workers_new_orders_v2';
const generalNotificationSoundResource = 'sound_general';
const newOrderNotificationSoundResource = 'notif_orderan_masuk';

String notificationChannelIdFor(String? type) {
  return type == 'new_order'
      ? newOrderNotificationChannelId
      : generalNotificationChannelId;
}

String notificationSoundResourceFor(String? type) {
  return type == 'new_order'
      ? newOrderNotificationSoundResource
      : generalNotificationSoundResource;
}
