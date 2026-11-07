import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/extraction_result.dart';
import '../models/progress_event.dart';
import '../services/extraction_coordinator.dart';

enum ExtractionMode { reel, post, profile }

enum ExtractionStatus { idle, loading, success, error }

class ExtractionProvider extends ChangeNotifier {
  final ExtractionCoordinator coordinator;

  ExtractionMode _mode = ExtractionMode.reel;
  ExtractionStatus _status = ExtractionStatus.idle;
  String _currentUrl = '';
  ProgressEvent? _currentProgress;
  String? _errorMessage;
  int? _errorStatusCode;

  ExtractionResult? _reelResult;
  PostExtractionResult? _postResult;
  ProfileExtractionResult? _profileResult;

  bool _useBackendFallback = false;
  String _backendBaseUrl = 'http://10.0.2.2:8000';
  List<Map<String, dynamic>> _recentExtractions = [];

  ExtractionProvider({ExtractionCoordinator? coordinator})
      : coordinator = coordinator ?? ExtractionCoordinator() {
    _loadSettingsAndHistory();
  }

  ExtractionMode get mode => _mode;
  ExtractionStatus get status => _status;
  String get currentUrl => _currentUrl;
  ProgressEvent? get currentProgress => _currentProgress;
  String? get errorMessage => _errorMessage;
  int? get errorStatusCode => _errorStatusCode;

  ExtractionResult? get reelResult => _reelResult;
  PostExtractionResult? get postResult => _postResult;
  ProfileExtractionResult? get profileResult => _profileResult;

  bool get useBackendFallback => _useBackendFallback;
  String get backendBaseUrl => _backendBaseUrl;
  List<Map<String, dynamic>> get recentExtractions => _recentExtractions;

  void setMode(ExtractionMode newMode) {
    if (_mode != newMode) {
      _mode = newMode;
      notifyListeners();
    }
  }

  void resetToIdle() {
    _status = ExtractionStatus.idle;
    _errorMessage = null;
    _errorStatusCode = null;
    _currentProgress = null;
    notifyListeners();
  }

  Future<void> _loadSettingsAndHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _useBackendFallback = prefs.getBool('use_backend_fallback') ?? false;
      _backendBaseUrl = prefs.getString('backend_base_url') ??
          coordinator.apiService.baseUrl;
      coordinator.apiService.baseUrl = _backendBaseUrl;

      final historyJson = prefs.getString('recent_extractions');
      if (historyJson != null) {
        final list = json.decode(historyJson) as List<dynamic>;
        _recentExtractions = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings/history: $e');
    }
  }

  Future<void> updateSettings({
    required bool useBackendFallback,
    required String backendBaseUrl,
  }) async {
    _useBackendFallback = useBackendFallback;
    _backendBaseUrl = backendBaseUrl;
    coordinator.apiService.baseUrl = backendBaseUrl;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('use_backend_fallback', useBackendFallback);
      await prefs.setString('backend_base_url', backendBaseUrl);
    } catch (_) {}

    notifyListeners();
  }

  Future<void> startExtraction(String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      _errorMessage = 'Please enter a valid Instagram URL';
      _errorStatusCode = 400;
      _status = ExtractionStatus.error;
      notifyListeners();
      return;
    }

    _currentUrl = cleanUrl;
    _status = ExtractionStatus.loading;
    _errorMessage = null;
    _errorStatusCode = null;
    _reelResult = null;
    _postResult = null;
    _profileResult = null;
    _currentProgress = ProgressEvent(
      stage: 'init',
      step: 1,
      totalSteps: 5,
      message: 'Connecting to Instagram content pipeline...',
      timestamp: DateTime.now().toIso8601String(),
    );
    notifyListeners();

    try {
      switch (_mode) {
        case ExtractionMode.reel:
          _reelResult = await coordinator.extractReel(
            cleanUrl,
            useBackendFallback: _useBackendFallback,
            onProgress: (event) {
              _currentProgress = event;
              notifyListeners();
            },
          );
          _saveToHistory(
            title: _reelResult!.title.isNotEmpty ? _reelResult!.title : 'Instagram Reel',
            author: _reelResult!.author,
            thumbnail: _reelResult!.thumbnailUrl,
            linkCount: _reelResult!.videoLinks.length + _reelResult!.captionLinks.length,
            url: cleanUrl,
          );
          break;

        case ExtractionMode.post:
          _postResult = await coordinator.extractPost(
            cleanUrl,
            useBackendFallback: _useBackendFallback,
          );
          _saveToHistory(
            title: _postResult!.title.isNotEmpty ? _postResult!.title : 'Instagram Post',
            author: _postResult!.author,
            thumbnail: _postResult!.thumbnail,
            linkCount: _postResult!.captionLinks.length,
            url: cleanUrl,
          );
          break;

        case ExtractionMode.profile:
          _profileResult = await coordinator.extractProfile(
            cleanUrl,
            useBackendFallback: _useBackendFallback,
          );
          _saveToHistory(
            title: _profileResult!.profileName,
            author: _profileResult!.profileName,
            thumbnail: null,
            linkCount: _profileResult!.allCaptionLinks.length,
            url: cleanUrl,
          );
          break;
      }
      _status = ExtractionStatus.success;
    } catch (e) {
      debugPrint('Extraction error: $e');
      _status = ExtractionStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('HttpException: ', '');
      if (_errorMessage!.contains('403') || _errorMessage!.toLowerCase().contains('private')) {
        _errorStatusCode = 403;
      } else {
        _errorStatusCode = 500;
      }
    }

    notifyListeners();
  }

  void cancelExtraction() {
    _status = ExtractionStatus.idle;
    _currentProgress = null;
    notifyListeners();
  }

  Future<void> _saveToHistory({
    required String title,
    required String author,
    String? thumbnail,
    required int linkCount,
    required String url,
  }) async {
    final item = {
      'title': title,
      'author': author,
      'thumbnail': thumbnail ?? '',
      'linkCount': linkCount,
      'url': url,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _recentExtractions.removeWhere((e) => e['url'] == url);
    _recentExtractions.insert(0, item);
    if (_recentExtractions.length > 10) {
      _recentExtractions = _recentExtractions.sublist(0, 10);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('recent_extractions', json.encode(_recentExtractions));
    } catch (_) {}
  }

  Future<void> clearHistory() async {
    _recentExtractions.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('recent_extractions');
    } catch (_) {}
    notifyListeners();
  }

  @override
  void dispose() {
    coordinator.dispose();
    super.dispose();
  }
}

