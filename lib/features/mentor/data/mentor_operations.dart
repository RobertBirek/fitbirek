import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'mentor_api.dart';
import 'mentor_models.dart';

/// Only opaque IDs/fingerprints enter preferences. Content stays on the server.
/// Independent of transport and route lifetime; each account has its own key.
class MentorOperationRegistry {
  MentorOperationRegistry(this.accountId);
  final String accountId;
  bool _disposed = false;
  bool _busy = false;
  void dispose() => _disposed = true;
  void _check() {
    if (_disposed || accountId.isEmpty) throw const MentorException();
  }

  String get storageKey =>
      'mentor.operations.v1.${const Uuid().v5(Namespace.url.value, accountId)}';
  String fingerprint(String text) =>
      const Uuid().v5(Namespace.url.value, '$accountId:${text.trim()}');

  /// Always reconcile, including on the first click after reload. A failed GET
  /// is not permission to allocate another paid request.
  Future<MentorOperation> resolve(
    MentorApi api,
    String kind, {
    String? sessionId,
    String? subjectId,
    String? text,
    bool regenerate = false,
  }) async {
    _check();
    if (_busy) throw const MentorException('operation_pending');
    _busy = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _check();
      final rows = (jsonDecode(prefs.getString(storageKey) ?? '[]') as List)
          .cast<Map>();
      final hash = text == null ? null : fingerprint(text);
      final slot = rows
          .where(
            (r) =>
                r['kind'] == kind &&
                r['session_id'] == sessionId &&
                r['subject_id'] == subjectId &&
                r['fingerprint'] == hash,
          )
          .lastOrNull;
      final remote = (await api.operations(
        sessionId: sessionId,
        subjectId: subjectId,
        kind: kind == 'chat' ? 'message' : kind,
      )).toList();
      remote.sort(
        (a, b) => (b.createdAt?.millisecondsSinceEpoch ?? 0).compareTo(
          a.createdAt?.millisecondsSinceEpoch ?? 0,
        ),
      );
      _check();
      final matches = remote
          .where(
            (o) =>
                o.kind == kind &&
                (sessionId == null || o.sessionId == sessionId) &&
                (kind != 'tts' ||
                    o.subjectId == subjectId ||
                    o.subjectId == null) &&
                (kind != 'chat' ||
                    o.userText == null ||
                    fingerprint(o.userText!) == hash),
          )
          .toList();
      MentorOperation? previous = matches.firstOrNull;
      final latestChat = remote
          .where((o) => o.kind == 'chat' && o.sessionId == sessionId)
          .firstOrNull;
      if (kind == 'chat' && previous == null && slot == null && !regenerate) {
        final row = rows
            .where((r) => r['kind'] == 'chat' && r['session_id'] == sessionId)
            .lastOrNull;
        if (row != null) {
          final old = await api.operation(row['request_id'] as String);
          _check();
          if (old == null || old.state != 'complete') {
            throw const MentorException('operation_pending');
          }
        }
      }
      if (kind == 'chat' &&
          previous == null &&
          slot == null &&
          !regenerate &&
          latestChat != null &&
          latestChat.state != 'complete') {
        throw const MentorException('operation_pending');
      }
      if (slot != null) {
        previous =
            await api.operation(slot['request_id'] as String) ??
            MentorOperation(
              requestId: slot['request_id'] as String,
              kind: kind,
              state: 'unknown',
              sessionId: sessionId,
              subjectId: subjectId,
            );
        _check();
      }
      if (previous != null && !regenerate) {
        // A new recording cannot recreate the original bytes. Never associate
        // different audio with the old request, nor silently allocate a new ID.
        if (kind == 'stt') throw const MentorException('result_unavailable');
        if (slot == null) {
          rows.add({
            'request_id': previous.requestId,
            'kind': kind,
            'session_id': sessionId,
            'subject_id': subjectId,
            'fingerprint': hash,
          });
          if (!await prefs.setString(storageKey, jsonEncode(rows))) {
            throw const MentorException();
          }
          _check();
        }
        return previous;
      }
      final id = const Uuid().v4();
      rows.removeWhere(
        (r) =>
            r['kind'] == kind &&
            r['session_id'] == sessionId &&
            r['subject_id'] == subjectId &&
            r['fingerprint'] == hash,
      );
      rows.add({
        'request_id': id,
        'kind': kind,
        'session_id': sessionId,
        'subject_id': subjectId,
        'fingerprint': hash,
      });
      if (!await prefs.setString(storageKey, jsonEncode(rows))) {
        throw const MentorException();
      }
      _check();
      return MentorOperation(
        requestId: id,
        kind: kind,
        state: 'new',
        sessionId: sessionId,
        subjectId: subjectId,
      );
    } finally {
      _busy = false;
    }
  }
}
