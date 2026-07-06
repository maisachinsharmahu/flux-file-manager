package com.example.flux.viewer.video

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import java.io.File

/**
 * FluxVideoView — native video viewer utilizing Android's MediaPlayer and SurfaceView.
 *
 * Implements PlatformView and listens to command MethodChannels.
 * Fits Rule 3 (Zero external libraries) and Rule 4 (Hardware accelerated rendering).
 */
class FluxVideoView(
    private val context: Context,
    viewId: Int,
    creationParams: Map<String, Any>?,
    private val methodChannel: MethodChannel
) : PlatformView, SurfaceHolder.Callback {

    private val sourcePath = creationParams?.get("path") as? String
        ?: throw IllegalArgumentException("Missing video path parameter")

    private val surfaceView = SurfaceView(context)
    private var mediaPlayer: MediaPlayer? = null
    private var isPrepared = false

    init {
        surfaceView.holder.addCallback(this)
        
        // Listen for playback control methods from Flutter
        methodChannel.setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }
    }

    override fun getView(): View = surfaceView

    override fun dispose() {
        methodChannel.setMethodCallHandler(null)
        releasePlayer()
    }

    // ── Surface Lifecycle Callback ──────────────────────────────────────────

    override fun surfaceCreated(holder: SurfaceHolder) {
        initializePlayer(holder)
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {}

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        mediaPlayer?.setDisplay(null)
    }

    // ── Player Initialization & Control ──────────────────────────────────────

    private fun initializePlayer(holder: SurfaceHolder) {
        try {
            mediaPlayer = MediaPlayer().apply {
                setDisplay(holder)
                setDataSource(this@FluxVideoView.context, Uri.fromFile(File(sourcePath)))
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MOVIE)
                        .build()
                )
                // Non-blocking preparation
                setOnPreparedListener { mp ->
                    isPrepared = true
                    // Adjust aspect ratio by matching dimensions on ready if desired
                    methodChannel.invokeMethod("onPrepared", mapOf(
                        "duration" to mp.duration,
                        "width" to mp.videoWidth,
                        "height" to mp.videoHeight
                    ))
                }
                setOnCompletionListener {
                    methodChannel.invokeMethod("onCompleted", null)
                }
                setOnErrorListener { _, what, extra ->
                    methodChannel.invokeMethod("onError", "MediaPlayer error: what=$what extra=$extra")
                    true
                }
                prepareAsync()
            }
        } catch (e: Exception) {
            android.util.Log.e("FluxVideoView", "MediaPlayer init error: ${e.message}")
            methodChannel.invokeMethod("onError", e.message)
        }
    }

    private fun releasePlayer() {
        mediaPlayer?.let {
            it.stop()
            it.release()
        }
        mediaPlayer = null
        isPrepared = false
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val player = mediaPlayer
        if (player == null) {
            result.error("PLAYER_RELEASED", "MediaPlayer is not initialized", null)
            return
        }

        when (call.method) {
            "play" -> {
                if (isPrepared) {
                    player.start()
                    result.success(true)
                } else result.success(false)
            }
            "pause" -> {
                if (isPrepared && player.isPlaying) {
                    player.pause()
                    result.success(true)
                } else result.success(false)
            }
            "seekTo" -> {
                val position = call.argument<Int>("position") ?: 0
                if (isPrepared) {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        player.seekTo(position.toLong(), MediaPlayer.SEEK_CLOSEST)
                    } else {
                        @Suppress("DEPRECATION")
                        player.seekTo(position)
                    }
                    result.success(true)
                } else result.success(false)
            }
            "getDuration" -> {
                result.success(if (isPrepared) player.duration else 0)
            }
            "getCurrentPosition" -> {
                result.success(if (isPrepared) player.currentPosition else 0)
            }
            "isPlaying" -> {
                result.success(isPrepared && player.isPlaying)
            }
            else -> result.notImplemented()
        }
    }
}
