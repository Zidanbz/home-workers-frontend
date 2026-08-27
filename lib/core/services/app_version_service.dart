import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:home_workers_fe/core/models/app_version_policy.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

abstract class AppVersionPolicyRepository {
  Future<AppVersionPolicy?> readCachedPolicy();

  Future<AppVersionPolicy> fetchPolicy({
    required String platform,
    required int currentBuild,
  });

  Future<void> savePolicy(AppVersionPolicy policy);
}

class AppVersionService implements AppVersionPolicyRepository {
  AppVersionService({
    String? baseUrl,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 3),
  }) : _baseUrl = _normalizeBaseUrl(
         baseUrl ??
             dotenv.env['API_BASE_URL'] ??
             'https://api-eh5nicgdhq-uc.a.run.app/api',
       ),
       _client = client ?? http.Client();

  static const String _cacheKey = 'app_version_policy_cache_v1';

  final String _baseUrl;
  final http.Client _client;
  final Duration requestTimeout;

  @override
  Future<AppVersionPolicy?> readCachedPolicy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_cacheKey);
      if (encoded == null || encoded.isEmpty) return null;

      final decoded = jsonDecode(encoded);
      if (decoded is! Map) return null;
      final cache = Map<String, dynamic>.from(decoded);
      if (cache['sourceBaseUrl'] != _baseUrl || cache['policy'] is! Map) {
        return null;
      }
      return AppVersionPolicy.fromJson(
        Map<String, dynamic>.from(cache['policy'] as Map),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AppVersionPolicy> fetchPolicy({
    required String platform,
    required int currentBuild,
  }) async {
    final uri = Uri.parse('$_baseUrl/app/version-policy').replace(
      queryParameters: {'platform': platform, 'build': currentBuild.toString()},
    );
    final response = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('Version policy gagal dimuat (${response.statusCode}).');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const FormatException('Respons version policy tidak valid.');
    }
    final body = Map<String, dynamic>.from(decoded);
    if (body['success'] != true || body['data'] is! Map) {
      throw const FormatException('Respons version policy tidak valid.');
    }
    return AppVersionPolicy.fromJson(
      Map<String, dynamic>.from(body['data'] as Map),
    );
  }

  @override
  Future<void> savePolicy(AppVersionPolicy policy) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode({
        'sourceBaseUrl': _baseUrl,
        'cachedAt': DateTime.now().toUtc().toIso8601String(),
        'policy': policy.toJson(),
      }),
    );
  }

  static String _normalizeBaseUrl(String value) {
    return value.trim().replaceFirst(RegExp(r'/+$'), '');
  }
}
