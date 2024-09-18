# EasySpeechToText

## 插件簡介

**EasySpeechToText** 是一個為 Flutter 應用提供語音識別功能的插件，支持 iOS 和 Android 平台。它提供了統一且易於使用的 Dart 介面，讓開發者可以輕鬆地在應用中實現即時流式語音識別和錄音檔轉文字的功能。

## 功能特性

- **跨平台支持**：同時支援 iOS 和 Android 平台的語音識別功能。
- **即時語音識別**：提供即時的語音轉文字功能，適用於語音輸入等場景。
- **錄音檔轉文字**：支援將錄製的音頻檔案轉換為文字。
- **自訂詞彙（僅 iOS）**：在 iOS 平台上支援自訂詞彙，提高特定詞彙的識別準確度。
- **簡潔的 Dart 介面**：統一的 API 設計，方便開發者快速上手。
- **非同步處理**：使用 `Future` 和 `Stream`，高效處理非同步操作。

## 安裝方法

在您的 `pubspec.yaml` 文件中添加以下依賴：

```yaml
dependencies:
  easy_speech_to_text: ^0.1.0
```

然後在專案目錄下運行：

```bash
flutter pub get
```

## 基本使用示例

### 初始化語音識別引擎

```dart
import 'package:easy_speech_to_text/easy_speech_to_text.dart';

void initializeSpeech() async {
  try {
    await EasySpeechToText.instance.initialize(
      engine: SpeechEngine.native, // 預設使用系統原生語音引擎
    );
  } catch (e) {
    print("初始化失敗: $e");
  }
}
```

### 檢查和請求權限

```dart
void checkPermissions() async {
  bool hasPermission = await EasySpeechToText.instance.hasPermission();
  if (!hasPermission) {
    bool granted = await EasySpeechToText.instance.requestPermission();
    print(granted ? "權限獲取成功" : "權限獲取失敗");
  }
}
```

### 開始語音識別

```dart
void startListening() {
  EasySpeechToText.instance.startListening(
    onResult: (text) {
      print("識別結果: $text");
    },
    onError: (error) {
      print("錯誤: $error");
    },
    partialResults: true, // 是否返回部分識別結果
  );
}
```

### 停止語音識別

```dart
void stopListening() async {
  await EasySpeechToText.instance.stopListening();
  print("語音識別已停止");
}
```

### 將音頻檔案轉文字

```dart
void transcribeFile(String filePath) async {
  String? result = await EasySpeechToText.instance.transcribe(
    filePath: filePath,
  );
  print("轉錄結果: $result");
}
```

### 設定自訂詞彙

```dart
void setCustomWords() {
  EasySpeechToText.instance.setCustomWords(['Flutter', 'Dart']);
  print("自訂詞彙已設定");
}
```

## API 說明

### `initialize`

初始化語音識別引擎。支持的語音引擎包括 `native`（原生引擎），將來還可擴展為第三方雲端服務如 Google 或 Azure。

```dart
Future<void> initialize({
  SpeechEngine engine = SpeechEngine.native,
  Map<String, dynamic>? options,
});
```

- **engine**: 指定語音引擎，預設為原生引擎。
- **options**: 額外的引擎配置選項。

### `hasPermission`

檢查是否已獲取語音識別和麥克風權限。

```dart
Future<bool> hasPermission();
```

- **返回**: `true` 表示權限已獲取，`false` 表示權限未獲取。

### `requestPermission`

請求語音識別和麥克風權限。

```dart
Future<bool> requestPermission();
```

- **返回**: `true` 表示權限請求成功，`false` 表示請求被拒。

### `startListening`

開始語音識別並監聽結果。當識別結果或錯誤發生時，會調用指定的回調函數。

```dart
Future<void> startListening({
  String? localeId,
  List<String>? customWords,
  bool partialResults = true,
  Duration? pauseFor,
  required Function(String text) onResult,
  Function(String error)? onError,
});
```

- **localeId**: 指定識別語言。
- **customWords**: 自訂詞彙庫（僅 iOS 支援）。
- **partialResults**: 是否返回部分識別結果。
- **pauseFor**: 自動停止識別的間隔時間。
- **onResult**: 識別結果的回調函數。
- **onError**: 錯誤發生時的回調函數。

### `stopListening`

停止語音識別並返回最終結果。

```dart
Future<void> stopListening();
```

### `cancelListening`

取消語音識別，不返回任何結果。

```dart
Future<void> cancelListening();
```

### `transcribe`

將錄音檔案轉換為文字。

```dart
Future<String?> transcribe({
  required String filePath,
  String? localeId,
  List<String>? customWords,
});
```

- **filePath**: 錄音檔案的路徑。
- **localeId**: 指定語言。
- **customWords**: 自訂詞彙庫。

### `setCustomWords`

設定全局自訂詞彙，用來提高語音識別中特定詞彙的識別準確度（僅 iOS 支援）。

```dart
void setCustomWords(List<String> words);
```

- **words**: 自訂詞彙的列表。

### `getAvailableLanguages`

獲取當前引擎支持的語言列表。

```dart
Future<List<LocaleName>> getAvailableLanguages();
```

- **返回**: 一個包含語言代碼和名稱的列表。

## iOS 平台權限設置

在使用 iOS 語音識別功能時，您需要在應用的 `Info.plist` 文件中添加以下權限設置：

```xml
<key>NSMicrophoneUsageDescription</key>
<string>我們需要存取您的麥克風來進行語音識別。</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>我們需要使用語音識別來轉換語音為文字。</string>
```

這些權限用於向用戶解釋應用程式需要麥克風和語音識別的原因，否則應用將無法執行語音識別功能。

## 注意事項

- **權限設置**：使用語音識別功能前，請確保已獲取麥克風和語音識別的訪問權限。
- **自訂詞彙支持**：
  - **iOS**：支持透過 `contextualStrings` 添加自訂詞彙，以提高特定詞彙的識別準確度。
  - **Android**：目前 Android 暫不支持自訂詞彙功能，後續版本將引入該功能。
- **隱私政策**：在應用中使用語音識別時，請遵守相關的隱私政策和法規，保護用戶的語音數據安全。

## 貢獻指南

歡迎任何形式的貢獻！如果您有興趣參與本專案的開發，請遵循以下步驟：

1. **Fork 本倉庫**：點擊右上角的 "Fork" 按鈕，將本專案複製到您的帳戶中。
2. **克隆到本地**：使用 `git clone` 將 Fork 後的倉庫克隆到本地。
3. **創建分支**：為您的修改創建一個新的分支，例如 `feature/my-new-feature`。
4. **提交修改**：在本地進行開發，並提交代碼到您的分支。
5. **發起 Pull Request**：將您的分支推送到 GitHub，並發起 Pull Request，描述您的修改內容和目的。

## 許可證信息

本專案採用 [MIT 許可證](LICENSE) 開源。您可以自由地使用、修改和分發本專案的代碼，但需要保留原作者的版權聲明和許可證資訊。
