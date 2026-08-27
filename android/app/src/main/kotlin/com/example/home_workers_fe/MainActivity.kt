package com.example.home_workers_fe

import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Handler
import android.os.Looper
import com.homeworkers.app.R
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private companion object {
        const val CHANNEL_NAME = "com.homeworkers.app/incoming_order_sound"
        const val MAX_RING_DURATION_MS = 30_000L
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var incomingOrderPlayer: MediaPlayer? = null
    private val stopSoundRunnable = Runnable { stopIncomingOrderSound() }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startLoop" -> {
                        val requestedDuration =
                            call.argument<Number>("maxDurationMs")?.toLong()
                                ?: MAX_RING_DURATION_MS
                        startIncomingOrderSound(
                            requestedDuration.coerceIn(1_000L, MAX_RING_DURATION_MS)
                        )
                        result.success(null)
                    }

                    "stop" -> {
                        stopIncomingOrderSound()
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun startIncomingOrderSound(maxDurationMs: Long) {
        stopIncomingOrderSound()

        val audioAttributes =
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
        incomingOrderPlayer =
            MediaPlayer.create(
                applicationContext,
                R.raw.notif_orderan_masuk,
                audioAttributes,
                AudioManager.AUDIO_SESSION_ID_GENERATE,
            )?.apply {
                isLooping = true
                setOnErrorListener { _, _, _ ->
                    stopIncomingOrderSound()
                    true
                }
                start()
            }

        mainHandler.postDelayed(stopSoundRunnable, maxDurationMs)
    }

    private fun stopIncomingOrderSound() {
        mainHandler.removeCallbacks(stopSoundRunnable)
        incomingOrderPlayer?.let { player ->
            runCatching {
                if (player.isPlaying) player.stop()
            }
            player.release()
        }
        incomingOrderPlayer = null
    }

    override fun onDestroy() {
        stopIncomingOrderSound()
        super.onDestroy()
    }
}
