import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// Sends push notifications via Firebase Cloud Messaging's HTTP v1 API.
/// There's no official Firebase Admin SDK for Dart, so this does the
/// Google OAuth2 service-account exchange manually.
class FcmService {
  static String? _cachedAccessToken;
  static DateTime? _cachedTokenExpiry;

  static String get _projectId {
    final id = Platform.environment['FCM_PROJECT_ID'];
    if (id == null || id.isEmpty) {
      throw StateError('FCM_PROJECT_ID is not set.');
    }
    return id;
  }

  static String get _clientEmail {
    final email = Platform.environment['FCM_CLIENT_EMAIL'];
    if (email == null || email.isEmpty) {
      throw StateError('FCM_CLIENT_EMAIL is not set.');
    }
    return email;
  }

  static String get _privateKeyPem {
    final raw = Platform.environment['FCM_PRIVATE_KEY'];
    if (raw == null || raw.isEmpty) {
      throw StateError('FCM_PRIVATE_KEY is not set.');
    }
    // Multi-line PEM keys pasted into a single-line env var usually end up
    // with literal backslash-n sequences — convert those to real newlines.
    return raw.replaceAll(r'\n', '\n');
  }

  static Future<String> _getAccessToken() async {
    if (_cachedAccessToken != null &&
        _cachedTokenExpiry != null &&
        DateTime.now().isBefore(_cachedTokenExpiry!)) {
      return _cachedAccessToken!;
    }

    final now = DateTime.now().toUtc();
    final iat = now.millisecondsSinceEpoch ~/ 1000;
    final exp = now.add(const Duration(minutes: 55)).millisecondsSinceEpoch ~/ 1000;

    final jwt = JWT({
      'iss': _clientEmail,
      'scope': 'https://www.googleapis.com/auth/firebase.messaging',
      'aud': 'https://oauth2.googleapis.com/token',
      'iat': iat,
      'exp': exp,
    });

    final signed = jwt.sign(
      RSAPrivateKey(_privateKeyPem),
      algorithm: JWTAlgorithm.RS256,
    );

    final response = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': signed,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('FCM_AUTH_FAILED: ${response.statusCode} ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    _cachedAccessToken = decoded['access_token'] as String;
    _cachedTokenExpiry = DateTime.now().add(const Duration(minutes: 50));
    return _cachedAccessToken!;
  }

  /// Sends the same notification to a list of device tokens. Never throws —
  /// a notification failure should never break the request that triggered
  /// it (logging a transaction, assigning a task, etc.).
  static Future<void> sendToTokens(
    List<String> tokens, {
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    if (tokens.isEmpty) return;

    String accessToken;
    try {
      accessToken = await _getAccessToken();
    } catch (e) {
      print('FCM_LOG: Could not get access token: $e');
      return;
    }

    final uri = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
    );

    for (final token in tokens) {
      try {
        final response = await http.post(
          uri,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'message': {
              'token': token,
              'notification': {'title': title, 'body': body},
              'data': data,
            },
          }),
        );
        if (response.statusCode != 200) {
          print('FCM_LOG: Send failed: ${response.statusCode} ${response.body}');
        }
      } catch (e) {
        print('FCM_LOG: Send error: $e');
      }
    }
  }
}