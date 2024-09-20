package com.example.easy_speech_to_text

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaPlayer
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File

/** EasySpeechToTextPlugin */
class EasySpeechToTextPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {

  private lateinit var methodChannel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private lateinit var context: Context
  private var activity: Activity? = null
  private var speechRecognizer: SpeechRecognizer? = null
  private lateinit var intent: Intent
  private var eventSink: EventChannel.EventSink? = null

  private val REQUEST_RECORD_AUDIO_PERMISSION = 200
  private var isFinalResultProcessed = false  // 標誌變數，跟蹤是否已處理最終結果

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "easy_speech_to_text/methods")
    methodChannel.setMethodCallHandler(this)

    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "easy_speech_to_text/events")
    eventChannel.setStreamHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "initialize" -> initializeSpeechRecognizer(call, result)
      "startListening" -> startListening(call, result)
      "stopListening" -> stopListening(result)
      "hasPermission" -> result.success(hasPermission())
      "requestPermission" -> requestPermission(result)
      else -> result.notImplemented()
    }
  }

  private fun initializeSpeechRecognizer(call: MethodCall, result: Result) {
    if (SpeechRecognizer.isRecognitionAvailable(context)) {
      speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
      speechRecognizer?.setRecognitionListener(object : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) {}

        override fun onBeginningOfSpeech() {}

        override fun onRmsChanged(rmsdB: Float) {}

        override fun onBufferReceived(buffer: ByteArray?) {}

        override fun onEndOfSpeech() {}

        override fun onError(error: Int) {
          val errorMessage = when (error) {
            SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
            SpeechRecognizer.ERROR_CLIENT -> "Client side error"
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
            SpeechRecognizer.ERROR_NETWORK -> "Network error"
            SpeechRecognizer.ERROR_NO_MATCH -> "No match found"
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognition service busy"
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech input"
            else -> "Unknown error"
          }

          if (error == SpeechRecognizer.ERROR_NO_MATCH) {
            eventSink?.success(mapOf("result" to "", "error" to "No match found"))
          } else {
            eventSink?.error("recognition_error", errorMessage, null)
          }
        }

        override fun onResults(results: Bundle?) {
          isFinalResultProcessed = true  // 標誌最終結果已處理

          val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
          if (!matches.isNullOrEmpty()) {
            val resultMap = mapOf("result" to matches[0])
            eventSink?.success(resultMap)
          }

          // 在得到結果後重新啟動辨識
          speechRecognizer?.startListening(intent)
        }

        override fun onPartialResults(partialResults: Bundle?) {
          if (isFinalResultProcessed) return  // 已處理最終結果則跳過部分結果

          val partialMatches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
          if (!partialMatches.isNullOrEmpty()) {
            val resultMap = mapOf("result" to partialMatches[0])
            eventSink?.success(resultMap)
          }
        }

        override fun onEvent(eventType: Int, params: Bundle?) {}
      })

      // 設定 localeId 為中文（台灣），如果 Dart 層提供了 localeId，則使用提供的
      val localeId = call.argument<String>("localeId") ?: "zh_TW"
      intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
        putExtra(RecognizerIntent.EXTRA_LANGUAGE, localeId)  // 支援 localeId
        putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
        putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
      }
      result.success(null)
    } else {
      result.error("Speech recognition not available", null, null)
    }
  }

  private fun startListening(call: MethodCall, result: Result) {
    isFinalResultProcessed = false  // 每次開始辨識時重設
    val partialResults = call.argument<Boolean>("partialResults") ?: true
    intent.putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, partialResults)

    if (speechRecognizer != null) {
      speechRecognizer?.startListening(intent)
      result.success(null)
    } else {
      result.error("SpeechRecognizer not initialized", null, null)
    }
  }

  private fun stopListening(result: Result) {
    speechRecognizer?.stopListening()
    speechRecognizer?.destroy()  // 銷毀 speechRecognizer
    speechRecognizer = null  // 確保後續重新初始化
    result.success(null)
  }

  private fun hasPermission(): Boolean {
    return ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
  }

  private fun requestPermission(result: Result) {
    if (activity == null) {
      result.error("Activity not attached", null, null)
      return
    }
    ActivityCompat.requestPermissions(activity!!, arrayOf(Manifest.permission.RECORD_AUDIO), REQUEST_RECORD_AUDIO_PERMISSION)
  }

  private fun transcribe(call: MethodCall, result: Result) {
    // 取得 filePath
    val filePath = call.argument<String>("filePath")
    if (filePath == null) {
      result.error("invalid_arguments", "File path is required", null)
      return
    }

    // 確認 filePath 指向有效的檔案
    val file = File(filePath)
    if (!file.exists()) {
      result.error("file_not_found", "File at path $filePath not found", null)
      return
    }

    // 初始化 MediaPlayer 用來播放音檔，並使用 SpeechRecognizer 做音檔轉錄
    val mediaPlayer = MediaPlayer()
    try {
      mediaPlayer.setDataSource(filePath)
      mediaPlayer.prepare()

      speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
      speechRecognizer?.setRecognitionListener(object : RecognitionListener {
        override fun onReadyForSpeech(params: Bundle?) {}

        override fun onBeginningOfSpeech() {}

        override fun onRmsChanged(rmsdB: Float) {}

        override fun onBufferReceived(buffer: ByteArray?) {}

        override fun onEndOfSpeech() {}

        override fun onError(error: Int) {
          val errorMessage = when (error) {
            SpeechRecognizer.ERROR_AUDIO -> "Audio recording error"
            SpeechRecognizer.ERROR_CLIENT -> "Client side error"
            SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Insufficient permissions"
            SpeechRecognizer.ERROR_NETWORK -> "Network error"
            SpeechRecognizer.ERROR_NO_MATCH -> "No match found"
            SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognition service busy"
            SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "No speech input"
            else -> "Unknown error"
          }
          result.error("recognition_error", errorMessage, null)
        }

        override fun onResults(results: Bundle?) {
          val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
          if (!matches.isNullOrEmpty()) {
            result.success(matches[0])  // 返回辨識到的文本
          } else {
            result.success(null)
          }
        }

        override fun onPartialResults(partialResults: Bundle?) {}

        override fun onEvent(eventType: Int, params: Bundle?) {}
      })

      val audioIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
        putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
        putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
      }

      // 開始播放音檔並使用 SpeechRecognizer 進行轉錄
      mediaPlayer.start()
      mediaPlayer.setOnCompletionListener {
        speechRecognizer?.startListening(audioIntent)
      }

    } catch (e: Exception) {
      result.error("media_error", "Error playing media: ${e.message}", null)
    }
  }

  override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
    if (requestCode == REQUEST_RECORD_AUDIO_PERMISSION) {
      val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
      eventSink?.success(mapOf("permissionGranted" to granted))
    }
    return true
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
  }

  override fun onCancel(arguments: Any?) {
    eventSink = null
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
    speechRecognizer?.destroy()
    speechRecognizer = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }
}