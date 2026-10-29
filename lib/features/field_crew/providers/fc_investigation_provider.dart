import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../location/crew_investigation_session.dart';

final fcInvestigationProvider = Provider.autoDispose
    .family<CrewInvestigationSession, String>((ref, taskId) {
      final auth = Supabase.instance.client.auth;
      final store = _InvestigationStore();
      final session = CrewInvestigationSession(
        actorId: () => auth.currentUser?.id,
        positions: preciseInvestigationPositions,
        onCompleted: store.save,
        loadSaved: store.load,
      );
      final subscription = auth.onAuthStateChange.listen((_) {
        if (ref.mounted) session.refreshActor();
      });
      ref.onDispose(() {
        unawaited(subscription.cancel());
        session.dispose();
      });
      return session;
    });

// Completed evidence only. Partial timers cannot resume from wall-clock time.
class _InvestigationStore {
  Future<void> _pending = Future.value();
  String _key(String scope) => 'crew_investigation_v1:$scope';
  Future<Map<String, dynamic>?> load(String scope) async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(
        _key(scope),
      );
      return raw == null
          ? null
          : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(Map<String, dynamic> snapshot) {
    final encoded = jsonEncode(snapshot);
    final key = _key(snapshot['scope'] as String);
    final write = _pending.catchError((Object _) {}).then((_) async {
      final saved = await (await SharedPreferences.getInstance()).setString(
        key,
        encoded,
      );
      if (!saved) throw StateError('Investigation storage failed');
    });
    _pending = write;
    return write;
  }
}
