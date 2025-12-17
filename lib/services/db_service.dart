import 'package:cloud_firestore/cloud_firestore.dart';

class ScoreEntry {
  final String nickname;
  final int score;
  final int timeSeconds;
  final DateTime createdAt;

  ScoreEntry({
    required this.nickname,
    required this.score,
    required this.timeSeconds,
    required this.createdAt,
  });

  // converts firestore document to ScoreEntry object
  factory ScoreEntry.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();

    int toIntValue(dynamic value) {
      if (value == null) {
        return 0;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? 0;
      }
      return 0;
    }

    int scoreVal = toIntValue(data['Score'] ?? data['score'] ?? 0);
    int timeVal = toIntValue(data['Time'] ?? data['time'] ?? 0);
    String nicknameVal = (data['Name'] ?? data['nickname'] ?? 'Unknown').toString();

    return ScoreEntry(
      nickname: nicknameVal,
      score: scoreVal,
      timeSeconds: timeVal,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class DBService {
  DBService._private();
  static final DBService instance = DBService._private();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // this is for saving player score to firebase database
  Future<void> saveScore({
    required String nickname,
    required int score,
    required int timeSeconds,
  }) async {
    try {
      await _db.collection('scorecollect').doc('score').collection('score').add({
        'Name': nickname,
        'Score': score,
        'Time': timeSeconds,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('[DBService Error] Failed to save score: $e');
    }
  }

  // gets top scores from database as a stream so it updates in real time
  Stream<List<ScoreEntry>> topScoresStream({int limit = 20}) {
    final q = _db
        .collection('scorecollect')
        .doc('score')
        .collection('score')
        .orderBy('Score', descending: true)
        .orderBy('Time', descending: false)
        .limit(limit);

    print('[DBService] Starting leaderboard query at scorecollect/score/score');

    return q.snapshots(includeMetadataChanges: true).handleError((error) {
      throw error;
    }).map((snapshot) {
      final entries = snapshot.docs.map((d) => ScoreEntry.fromDoc(d as QueryDocumentSnapshot<Map<String, dynamic>>)).toList();
      return entries;
    });
  }
}
