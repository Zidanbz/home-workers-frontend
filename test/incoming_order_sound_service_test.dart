import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_workers_fe/core/services/incoming_order_sound_service.dart';

class _FakeSoundPlayer implements IncomingOrderSoundPlayer {
  int startCount = 0;
  int stopCount = 0;
  final List<Duration> durations = [];

  @override
  Future<void> startLoop({required Duration maxDuration}) async {
    startCount++;
    durations.add(maxDuration);
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }
}

void main() {
  test('order yang sama hanya membunyikan loop satu kali', () async {
    final player = _FakeSoundPlayer();
    final controller = IncomingOrderAlertController(player: player);

    await controller.showOrder('order-1');
    await controller.showOrder('order-1');

    expect(player.startCount, 1);
    expect(player.durations, [incomingOrderMaxRingDuration]);
    controller.dispose();
  });

  test('order berikutnya mengganti suara aktif tanpa menumpuk', () async {
    final player = _FakeSoundPlayer();
    final controller = IncomingOrderAlertController(player: player);

    await controller.showOrder('order-1');
    await controller.showOrder('order-2');

    expect(player.startCount, 2);
    expect(player.stopCount, 1);
    controller.dispose();
  });

  test('loop otomatis berhenti saat batas waktu tercapai', () async {
    final player = _FakeSoundPlayer();
    final controller = IncomingOrderAlertController(
      player: player,
      maxDuration: const Duration(milliseconds: 10),
    );

    await controller.showOrder('order-1');
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(player.startCount, 1);
    expect(player.stopCount, 1);
    controller.dispose();
  });
}
