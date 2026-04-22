import 'package:supabase_flutter/supabase_flutter.dart';

/// Syncs daily crop-care scores to the `crop_care_history` table in Supabase.
///
/// Each day only one score per device+crop is stored (upsert on conflict).
/// The historical average is computed server-side via a simple SELECT AVG.
class CropCareHistorySync {
  static const String _table = 'crop_care_history';

  SupabaseClient get _client => Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Upload today's score for a device+crop.
  ///
  /// [score01] is a 0.0–1.0 value (soilControlScore01).
  /// If the user already has a row for today it will be updated (upsert).
  Future<void> uploadDailyScore({
    required String deviceId,
    required String cropId,
    required double score01,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      await _client.from(_table).upsert(<String, dynamic>{
        'user_id': userId,
        'device_id': deviceId,
        'crop_id': cropId,
        'score': score01.clamp(0.0, 1.0),
        'recorded_at': _todayIso(),
      }, onConflict: 'user_id,device_id,crop_id,recorded_at');
    } catch (_) {
      // Best-effort — the app works fine without cloud history.
    }
  }

  /// Fetch the lifetime average score for a device+crop.
  ///
  /// Returns `null` if there are no rows or the user is not signed in.
  Future<double?> fetchLifetimeAverage({
    required String deviceId,
    required String cropId,
  }) async {
    final userId = _userId;
    if (userId == null) return null;

    try {
      final data = await _client
          .from(_table)
          .select('score')
          .eq('user_id', userId)
          .eq('device_id', deviceId)
          .eq('crop_id', cropId)
          .order('recorded_at', ascending: false)
          .limit(365);

      final rows = data as List<dynamic>;
      if (rows.isEmpty) return null;

      double sum = 0;
      int count = 0;
      for (final row in rows) {
        final s = (row as Map<String, dynamic>)['score'];
        if (s is num) {
          sum += s.toDouble();
          count++;
        }
      }

      return count > 0 ? (sum / count) : null;
    } catch (_) {
      return null;
    }
  }

  /// Fetch all daily scores for a device+crop (for potential chart use).
  Future<List<DailyCareScore>> fetchHistory({
    required String deviceId,
    required String cropId,
  }) async {
    final userId = _userId;
    if (userId == null) return const <DailyCareScore>[];

    try {
      final data = await _client
          .from(_table)
          .select('score, recorded_at')
          .eq('user_id', userId)
          .eq('device_id', deviceId)
          .eq('crop_id', cropId)
          .order('recorded_at', ascending: true)
          .limit(365);

      final rows = data as List<dynamic>;
      return rows.map((row) {
        final m = row as Map<String, dynamic>;
        return DailyCareScore(
          score01: (m['score'] as num).toDouble(),
          recordedAt: DateTime.parse(m['recorded_at'] as String),
        );
      }).toList();
    } catch (_) {
      return const <DailyCareScore>[];
    }
  }

  String _todayIso() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

/// A single day's crop care score.
class DailyCareScore {
  const DailyCareScore({required this.score01, required this.recordedAt});

  final double score01;
  final DateTime recordedAt;
}
