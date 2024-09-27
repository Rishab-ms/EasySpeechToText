
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:easy_speech_to_text/easy_speech_to_text.dart';
import 'package:flutter_sound/flutter_sound.dart';

class RecordingPage extends StatefulWidget {
  const RecordingPage({super.key});

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  final EasySpeechToText _speechToText = EasySpeechToText();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isTranscribing = false;
  String _recognizedText = '';
  String _recordingPath = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
    await _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    try {
      await _speechToText.initialize();
      bool hasPermission = await _speechToText.hasPermission();
      if (!hasPermission) {
        hasPermission = await _speechToText.requestPermission();
      }
      if (!hasPermission) {
        debugPrint('Permission not granted');
      }
    } catch (e) {
      debugPrint('Error initializing speech recognition: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _recordingPath = '${directory.path}/recording.wav';

      await _recorder.startRecorder(toFile: _recordingPath);
      setState(() {
        _isRecording = true;
        _recognizedText = '';
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _playRecording() async {
    try {
      if (_recordingPath.isEmpty) return;
      await _player.startPlayer(fromURI: _recordingPath);
      setState(() {
        _isPlaying = true;
      });

      _player.setSubscriptionDuration(const Duration(milliseconds: 100));
      _player.onProgress!.listen((event) {
        if (event.position >= event.duration) {
          setState(() {
            _isPlaying = false;
          });
        }
      });
    } catch (e) {
      debugPrint('Error playing recording: $e');
    }
  }

  Future<void> _stopPlaying() async {
    try {
      await _player.stopPlayer();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      debugPrint('Error stopping playback: $e');
    }
  }

  Future<void> _transcribeRecording() async {
    setState(() {
      _isTranscribing = true;
      _recognizedText = ''; // 清空之前的結果
    });

    try {
      final result = await _speechToText.transcribe(filePath: _recordingPath);
      setState(() {
        _recognizedText = result ?? 'Transcription failed or no result';
      });
    } catch (e) {
      debugPrint('Error transcribing recording: $e');
      setState(() {
        _recognizedText = 'Error transcribing recording: $e';
      });
    } finally {
      setState(() {
        _isTranscribing = false;
      });
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recording Page')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Recognized Text:',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _recognizedText,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _isRecording
                ? ElevatedButton(
                    onPressed: _stopRecording,
                    child: const Text('Stop Recording'),
                  )
                : ElevatedButton(
                    onPressed: _startRecording,
                    child: const Text('Start Recording'),
                  ),
            const SizedBox(height: 10),
            _isPlaying
                ? ElevatedButton(
                    onPressed: _stopPlaying,
                    child: const Text('Stop Playing'),
                  )
                : ElevatedButton(
                    onPressed: _playRecording,
                    child: const Text('Play Recording'),
                  ),
            const SizedBox(height: 10),
            _isTranscribing
                ? const ElevatedButton(
                    onPressed: null,
                    child: Text('Transcribing...'),
                  )
                : ElevatedButton(
                    onPressed: _transcribeRecording,
                    child: const Text('Transcribe Recording'),
                  ),
          ],
        ),
      ),
    );
  }
}
