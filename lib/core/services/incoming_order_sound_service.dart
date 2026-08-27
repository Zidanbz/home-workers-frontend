import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const incomingOrderMaxRingDuration = Duration(seconds: 30);
const incomingOrderSoundChannelName =
    'com.homeworkers.app/incoming_order_sound';

abstract interface class IncomingOrderSoundPlayer {
  Future<void> startLoop({required Duration maxDuration});
  Future<void> stop();
}

class NativeIncomingOrderSoundPlayer implements IncomingOrderSoundPlayer {
  NativeIncomingOrderSoundPlayer({
    MethodChannel channel = const MethodChannel(incomingOrderSoundChannelName),
  }) : _channel = channel;

  final MethodChannel _channel;

  bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> startLoop({required Duration maxDuration}) async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod<void>('startLoop', {
        'maxDurationMs': maxDuration.inMilliseconds,
      });
    } on PlatformException catch (error) {
      debugPrint('Gagal memutar sound pesanan masuk: $error');
    } on MissingPluginException catch (error) {
      debugPrint('Native sound pesanan masuk belum tersedia: $error');
    }
  }

  @override
  Future<void> stop() async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException catch (error) {
      debugPrint('Gagal menghentikan sound pesanan masuk: $error');
    } on MissingPluginException catch (error) {
      debugPrint('Native sound pesanan masuk belum tersedia: $error');
    }
  }
}

class IncomingOrderAlertController {
  IncomingOrderAlertController({
    IncomingOrderSoundPlayer? player,
    this.maxDuration = incomingOrderMaxRingDuration,
  }) : _player = player ?? NativeIncomingOrderSoundPlayer();

  final IncomingOrderSoundPlayer _player;
  final Duration maxDuration;

  Timer? _stopTimer;
  String? _lastAlertedOrderId;
  bool _isPlaying = false;
  int _generation = 0;

  Future<void> showOrder(String orderId) async {
    final normalizedOrderId = orderId.trim();
    if (normalizedOrderId.isEmpty || _lastAlertedOrderId == normalizedOrderId) {
      return;
    }

    _lastAlertedOrderId = normalizedOrderId;
    final generation = ++_generation;
    _stopTimer?.cancel();
    if (_isPlaying) {
      _isPlaying = false;
      await _player.stop();
    }
    if (generation != _generation) return;

    await _player.startLoop(maxDuration: maxDuration);
    if (generation != _generation) {
      await _player.stop();
      return;
    }

    _isPlaying = true;
    _stopTimer = Timer(maxDuration, () {
      if (generation != _generation) return;
      _isPlaying = false;
      unawaited(_player.stop());
    });
  }

  Future<void> stop() async {
    _generation++;
    _stopTimer?.cancel();
    _stopTimer = null;
    if (!_isPlaying) return;
    _isPlaying = false;
    await _player.stop();
  }

  void dispose() {
    unawaited(stop());
  }
}
