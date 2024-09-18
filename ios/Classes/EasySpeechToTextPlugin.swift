import Flutter
import UIKit
import Speech

public class EasySpeechToTextPlugin: NSObject, FlutterPlugin {
    
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var eventSink: FlutterEventSink?
    
    // MethodChannel & EventChannel identifiers
    static let methodChannelName = "easy_speech_to_text/methods"
    static let eventChannelName = "easy_speech_to_text/events"

    // Register the plugin
    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: eventChannelName, binaryMessenger: registrar.messenger())
        
        let instance = EasySpeechToTextPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }
}

// Handle event streaming
extension EasySpeechToTextPlugin: FlutterStreamHandler {
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}

// Handle method calls
extension EasySpeechToTextPlugin {
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initialize(call, result: result)
        case "hasPermission":
            hasPermission(result: result)
        case "requestPermission":
            requestPermission(result: result)
        case "startListening":
            startListening(call, result: result)
        case "stopListening":
            stopListening(result: result)
        case "cancelListening":
            cancelListening(result: result)
        case "transcribe":
            transcribe(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // Initialize speech recognizer
    func initialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]
        let localeId = args?["localeId"] as? String ?? Locale.current.identifier
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeId))
        
        if self.speechRecognizer == nil {
            result(FlutterError(code: "speech_recognizer_unavailable", message: "Speech recognizer not available for locale: \(localeId)", details: nil))
        } else {
            result(nil)
        }
    }
    
    // Check if the app has permission
    func hasPermission(result: @escaping FlutterResult) {
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        let micStatus = AVAudioSession.sharedInstance().recordPermission
        result(authStatus == .authorized && micStatus == .granted)
    }
    
    // Request permission for speech recognition and microphone
    func requestPermission(result: @escaping FlutterResult) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            AVAudioSession.sharedInstance().requestRecordPermission { micStatus in
                result(authStatus == .authorized && micStatus)
            }
        }
    }
    
    // Start listening for speech
    func startListening(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      guard let recognizer = self.speechRecognizer, recognizer.isAvailable else {
          result(FlutterError(code: "speech_recognizer_unavailable", message: "Speech recognizer not available", details: nil))
          return
      }
      
      let args = call.arguments as? [String: Any]
      let localeId = args?["localeId"] as? String
      let customWords = args?["customWords"] as? [String]
      let partialResults = args?["partialResults"] as? Bool ?? true
      let pauseFor = args?["pauseFor"] as? Int // milliseconds

      print("Starting listening for locale: \(localeId)")

      if let localeId = localeId {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeId))
      }

      print("Current locale: \(self.speechRecognizer?.locale.identifier ?? "Unknown")")


      recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
      recognitionRequest?.shouldReportPartialResults = partialResults
      
      if let customWords = customWords {
          recognitionRequest?.contextualStrings = customWords
      }

      let inputNode = audioEngine.inputNode
      let recordingFormat = inputNode.outputFormat(forBus: 0)

      inputNode.removeTap(onBus: 0)

      inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
          self.recognitionRequest?.append(buffer)
      }

      audioEngine.prepare()

      do {
          try audioEngine.start()
      } catch {
          result(FlutterError(code: "audio_engine_error", message: "Failed to start audio engine", details: error.localizedDescription))
          return
      }

      recognitionTask = recognizer.recognitionTask(with: recognitionRequest!) { result, error in
          if let result = result {
              let transcription = result.bestTranscription.formattedString
              if let eventSink = self.eventSink {
                  eventSink(["result": transcription])
              }
          }

          if let error = error {
              if let eventSink = self.eventSink {
                  eventSink(FlutterError(code: "recognition_error", message: error.localizedDescription, details: nil))
              }
          }
      }

      if let pauseFor = pauseFor {
          DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(pauseFor)) {
              self.stopListening(result: { _ in })
          }
      }

      result(nil)
    }

    // Stop listening for speech
    func stopListening(result: @escaping FlutterResult) {
      if audioEngine.isRunning {
          audioEngine.stop()
          audioEngine.inputNode.removeTap(onBus: 0)  // 移除 input tap
          recognitionRequest?.endAudio()
          recognitionTask?.cancel()
          recognitionRequest = nil
          recognitionTask = nil
      }
      result(nil)
    }

    
    // Cancel listening without returning a result
    func cancelListening(result: @escaping FlutterResult) {
        recognitionTask?.cancel()
        recognitionRequest = nil
        result(nil)
    }
    
    // Transcribe an audio file to text
    func transcribe(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]
        
        // Get file path
        guard let filePath = args?["filePath"] as? String else {
            result(FlutterError(code: "invalid_arguments", message: "File path is required", details: nil))
            return
        }
        
        // Get localeId
        let localeId = args?["localeId"] as? String
        if let localeId = localeId {
            self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeId))
        }

        // Get custom words
        let customWords = args?["customWords"] as? [String]
        
        let url = URL(fileURLWithPath: filePath)
        let request = SFSpeechURLRecognitionRequest(url: url)
        
        // Set custom words for the request if provided
        if let customWords = customWords {
            request.contextualStrings = customWords
        }

        // Perform speech recognition
        speechRecognizer?.recognitionTask(with: request) { (transcriptionResult, error) in
            if let transcriptionResult = transcriptionResult {
                result(transcriptionResult.bestTranscription.formattedString)
            } else if let error = error {
                result(FlutterError(code: "transcription_error", message: error.localizedDescription, details: nil))
            }
        }
    }

}
