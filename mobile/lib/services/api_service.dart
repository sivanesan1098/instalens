import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/extraction_result.dart';
import '../models/progress_event.dart';

/// Service connecting to the FastAPI backend microservice (backend.py).
class ApiService {
  String _baseUrl;

  ApiService({String? baseUrl})
      : _baseUrl = baseUrl ?? _defaultBaseUrl();

  static String _defaultBaseUrl() {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  String get baseUrl => _baseUrl;

  set baseUrl(String url) {
    _baseUrl = url.replaceAll(RegExp(r'/+$'), '');
  }

  String get wsBaseUrl {
    if (_baseUrl.startsWith('https://')) {
      return 'wss://${_baseUrl.substring(8)}';
    } else if (_baseUrl.startsWith('http://')) {
      return 'ws://${_baseUrl.substring(7)}';
    }
    return 'ws://$_baseUrl';
  }

  /// Verifies if the backend server is reachable.
  Future<bool> checkHealth() async {
    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 4));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Extracts an Instagram Reel or Video via POST /api/extract with optional WebSocket progress.
  Future<ExtractionResult> extractReel(
    String url, {
    Function(ProgressEvent)? onProgress,
  }) async {
    final clientId = const Uuid().v4();
    WebSocketChannel? channel;
    StreamSubscription? sub;

    if (onProgress != null) {
      try {
        final wsUri = Uri.parse('$wsBaseUrl/ws/progress/$clientId');
        channel = WebSocketChannel.connect(wsUri);
        sub = channel.stream.listen((message) {
          try {
            final data = json.decode(message.toString()) as Map<String, dynamic>;
            final event = ProgressEvent.fromJson(data);
            onProgress(event);
          } catch (e) {
            debugPrint('Error parsing WebSocket progress event: $e');
          }
        }, onError: (e) {
          debugPrint('WebSocket progress stream error: $e');
        });
      } catch (e) {
        debugPrint('Could not initialize progress WebSocket: $e');
      }
    }

    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/extract'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'url': url,
          'client_id': clientId,
        }),
      ).timeout(const Duration(minutes: 3));

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        return ExtractionResult.fromJson(data);
      } else {
        final errorMsg = _extractErrorMessage(resp);
        throw HttpException('HTTP ${resp.statusCode}: $errorMsg');
      }
    } finally {
      await sub?.cancel();
      await channel?.sink.close();
    }
  }

  /// Extracts a single photo or carousel post via POST /api/extract/post.
  Future<PostExtractionResult> extractPost(String url) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/api/extract/post'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'url': url}),
    ).timeout(const Duration(seconds: 45));

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      return PostExtractionResult.fromJson(data);
    } else {
      final errorMsg = _extractErrorMessage(resp);
      throw HttpException('HTTP ${resp.statusCode}: $errorMsg');
    }
  }

  /// Extracts a profile or creator stack via POST /api/extract/profile.
  Future<ProfileExtractionResult> extractProfile(String url) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/api/extract/profile'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'url': url}),
    ).timeout(const Duration(minutes: 2));

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body) as Map<String, dynamic>;
      return ProfileExtractionResult.fromJson(data);
    } else {
      final errorMsg = _extractErrorMessage(resp);
      throw HttpException('HTTP ${resp.statusCode}: $errorMsg');
    }
  }

  String _extractErrorMessage(http.Response resp) {
    try {
      final body = json.decode(resp.body) as Map<String, dynamic>;
      return body['detail'] as String? ?? resp.body;
    } catch (_) {
      return resp.body.isNotEmpty ? resp.body : resp.reasonPhrase ?? 'Unknown error';
    }
  }
}

