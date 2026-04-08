import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  // ── Change this to your machine's local IP when testing on a real phone
  // ── Example: static const String base = 'http://192.168.1.10:8000';
  static const base = "http://10.127.233.212:8000";

  // ─────────────────────────────────────────────
  // SETUP — called once during onboarding
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> setupUser({
    required String name,
    required String language,
    required String level,
    required String goal,
  }) async {
    final res = await http.post(
      Uri.parse('$base/setup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'language': language,
        'level': level,
        'goal': goal,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Setup failed: ${res.body}');
    }
    return jsonDecode(res.body);
  }

  // ─────────────────────────────────────────────
  // DASHBOARD — home screen data
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboard(String userId) async {
    final res = await http.get(Uri.parse('$base/dashboard/$userId'));
    if (res.statusCode != 200) {
      throw Exception('Dashboard failed: ${res.body}');
    }
    return jsonDecode(res.body);
  }

  // ─────────────────────────────────────────────
  // SPEECH — get today's session content
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getTodaySession(String userId) async {
    final res = await http.get(Uri.parse('$base/speech/today/$userId'));
    if (res.statusCode != 200) {
      throw Exception('Get session failed: ${res.body}');
    }
    return jsonDecode(res.body);
  }

  // ─────────────────────────────────────────────
  // SPEECH — score one word/phrase recording
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> scoreWord({
  required String userId,
  required String planId,   // ✅ NEW
  required String language,
  required String targetText,
  required String audioPath,
}) async {
  final req = http.MultipartRequest(
    'POST',
    Uri.parse('$base/speech/score-word'),
  );

  req.fields['user_id'] = userId;
  req.fields['plan_id'] = planId;   // ✅ NEW
  req.fields['language'] = language;
  req.fields['target_text'] = targetText;

  req.files.add(await http.MultipartFile.fromPath('audio', audioPath));

  final streamed = await req.send();
  final res = await http.Response.fromStream(streamed);

  return jsonDecode(res.body);
}

  // ─────────────────────────────────────────────
  // SPEECH — complete session, save scores
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> completeSession({
    required String userId,
    required String planId,
    required String language,
    required String topic,
    required List<Map<String, dynamic>> wordScores,
  }) async {
    final res = await http.post(
      Uri.parse('$base/speech/complete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'plan_id': planId,
        'language': language,
        'topic': topic,
        'word_scores': wordScores,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Complete session failed: ${res.body}');
    }
    return jsonDecode(res.body);
  }
}