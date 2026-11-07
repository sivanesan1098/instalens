import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Service wrapping Google ML Kit Text Recognition for on-device OCR on video frames & images.
class OcrService {
  TextRecognizer? _textRecognizer;

  OcrService() {
    _initRecognizer();
  }

  void _initRecognizer() {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      }
    } catch (e) {
      debugPrint('ML Kit TextRecognizer initialization skipped/failed: $e');
    }
  }

  /// Scans an image file at [imagePath] and returns all recognized text.
  Future<String> scanImageText(String imagePath) async {
    if (_textRecognizer == null) {
      _initRecognizer();
    }
    if (_textRecognizer == null) {
      return '';
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer!.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      debugPrint('Error during on-device OCR: $e');
      return '';
    }
  }

  /// Extracts structured snippet cards from recognized text blocks.
  Future<List<Map<String, dynamic>>> scanImageSnippets(
    String imagePath, {
    String? timestamp,
  }) async {
    if (_textRecognizer == null) {
      _initRecognizer();
    }
    if (_textRecognizer == null) {
      return [];
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer!.processImage(inputImage);
      final snippets = <Map<String, dynamic>>[];

      for (final block in recognizedText.blocks) {
        final text = block.text.trim();
        if (text.isNotEmpty) {
          snippets.add({
            'timestamp': timestamp ?? '0:01',
            'text': text,
            'confidence': 0.95,
          });
        }
      }
      return snippets;
    } catch (e) {
      debugPrint('Error scanning image snippets: $e');
      return [];
    }
  }

  /// Closes and releases ML Kit native resources.
  void dispose() {
    _textRecognizer?.close();
    _textRecognizer = null;
  }
}

