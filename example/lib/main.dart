import 'dart:io';

import 'package:easy_speech_to_text_example/recording_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:easy_speech_to_text/easy_speech_to_text.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easy Speech to Text Example',
      home: const HomePage(), // 使用 HomePage 作為主頁
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final EasySpeechToText _speechToText = EasySpeechToText();
  String _recognizedText = '';
  bool _isListening = false;
  bool _isTranscribing = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
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

  void _startListening() {
    setState(() {
      _isListening = true;
      _recognizedText = ''; // 清空之前的辨識結果
    });

    _speechToText.startListening(
      localeId: 'zh_TW',
      onResult: (text) {
        setState(() {
          if (!_recognizedText.endsWith(text)) {
            debugPrint('Recognized: $text');
            _recognizedText += text;
          }
        });
      },
      onError: (error) {
        debugPrint('Error: $error');
        if (error != 'No match found') {
          setState(() {
            _isListening = false;
          });
        }
      },
    );
  }

  void _stopListening() {
    _speechToText.stopListening();
    setState(() {
      _isListening = false;
    });
  }

  void _cancelListening() {
    _speechToText.cancelListening();
    setState(() {
      _isListening = false;
      _recognizedText = '';
    });
  }

  Future<void> _transcribeRecording() async {
    setState(() {
      _isTranscribing = true;
      _recognizedText = ''; // 清空之前的結果
    });

    try {
      // 獲取應用程式文件目錄
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/1_16k.wav';

      // 檢查檔案是否已經存在，若不存在則從 assets 複製
      final file = File(filePath);
      if (!file.existsSync()) {
        final byteData = await rootBundle.load('assets/1_16k.wav');
        await file.writeAsBytes(byteData.buffer.asUint8List());
      }

      final result = await _speechToText.transcribe(filePath: filePath);
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Easy Speech to Text Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecordingPage(),
                    ),
                  );
                },
                child: const Text('Go to Recording Page'),
              ),
            ),
            const SizedBox(height: 20),
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
            _isListening
                ? ElevatedButton(
                    onPressed: _stopListening,
                    child: const Text('Stop Listening'),
                  )
                : ElevatedButton(
                    onPressed: _startListening,
                    child: const Text('Start Listening'),
                  ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _cancelListening,
              child: const Text('Cancel Listening'),
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
