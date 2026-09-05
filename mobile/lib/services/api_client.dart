import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// L'émulateur Android route son propre "localhost" vers lui-même ;
/// 10.0.2.2 est l'alias spécial qui pointe vers la machine hôte.
/// Sur un vrai appareil, remplacer par l'IP réseau du serveur Laravel.
String get hoteServeur =>
    (!kIsWeb && Platform.isAndroid) ? '10.0.2.2' : '127.0.0.1';

String get apiBase => 'http://$hoteServeur:8000/api';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class ApiClient {
  static const _tokenKey = 'onele_token';

  Future<String?> get token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, String>> _headers({bool withBody = false}) async {
    final headers = {'Accept': 'application/json'};
    if (withBody) headers['Content-Type'] = 'application/json';
    final t = await token;
    if (t != null) headers['Authorization'] = 'Bearer $t';
    return headers;
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode == 204 || res.body.isEmpty) return null;
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  void _throwIfError(http.Response res, dynamic data) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    final message = (data is Map && data['message'] is String)
        ? data['message'] as String
        : 'Une erreur est survenue (${res.statusCode}).';
    throw ApiException(message, res.statusCode);
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$apiBase$path').replace(queryParameters: query);
    final res = await http.get(uri, headers: await _headers());
    final data = _decode(res);
    _throwIfError(res, data);
    return data;
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final res = await http.post(
      Uri.parse('$apiBase$path'),
      headers: await _headers(withBody: true),
      body: body != null ? jsonEncode(body) : null,
    );
    final data = _decode(res);
    _throwIfError(res, data);
    return data;
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final res = await http.put(
      Uri.parse('$apiBase$path'),
      headers: await _headers(withBody: true),
      body: body != null ? jsonEncode(body) : null,
    );
    final data = _decode(res);
    _throwIfError(res, data);
    return data;
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final res = await http.patch(
      Uri.parse('$apiBase$path'),
      headers: await _headers(withBody: true),
      body: body != null ? jsonEncode(body) : null,
    );
    final data = _decode(res);
    _throwIfError(res, data);
    return data;
  }

  Future<void> delete(String path) async {
    final res = await http.delete(
      Uri.parse('$apiBase$path'),
      headers: await _headers(),
    );
    final data = _decode(res);
    _throwIfError(res, data);
  }
}
