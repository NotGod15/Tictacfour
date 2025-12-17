import 'package:cloud_firestore/cloud_firestore.dart';

// data model for leaderboard score entry
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

  // convert Firestore document to ScoreEntry
  factory ScoreEntry.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();

    // safely convert value to integer
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

    // Try both capitalized and lowercase field names for compatibility
    int scoreVal = toIntValue(data['Score'] ?? data['score'] ?? 0);
    int timeVal = toIntValue(data['Time'] ?? data['time'] ?? 0);
    String nicknameVal = (data['Name'] ?? data['nickname'] ?? 'Unknown').toString();

    print('[Leaderboard Debug] Loaded: nickname=$nicknameVal, score=$scoreVal, time=$timeVal, doc=${d.id}');

    return ScoreEntry(
      nickname: nicknameVal,
      score: scoreVal,
      timeSeconds: timeVal,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// singleton service for Firestore database operations
class DBService {
  DBService._private();
  static final DBService instance = DBService._private();

  // Firestore instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // save player score to database
  Future<void> saveScore({
    required String nickname,
    required int score,
    required int timeSeconds,
  }) async {
    try {
      // Save to scorecollect/score subcollection with capitalized field names
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

  // stream of top scores from database
  Stream<List<ScoreEntry>> topScoresStream({int limit = 20}) {
    // query Firestore for scores ordered by score desc, time asc
    final q = _db
        .collection('scorecollect')
        .doc('score')
        .collection('score')
        .orderBy('Score', descending: true)
        .orderBy('Time', descending: false)
        .limit(limit);

    print('[DBService] Starting leaderboard query at scorecollect/score/score');

    return q.snapshots(includeMetadataChanges: true).handleError((error) {
      print('[DBService Query Error] $error');
      throw error;
    }).map((snapshot) {
      print('[DBService] Query returned ${snapshot.docs.length} documents');
      print('[DBService] Metadata - fromCache: ${snapshot.metadata.isFromCache}, hasPendingWrites: ${snapshot.metadata.hasPendingWrites}');
      
      for (final doc in snapshot.docs) {
        print('[DBService] Raw doc ${doc.id}: ${doc.data()}');
      }
      
      final entries = snapshot.docs.map((d) => ScoreEntry.fromDoc(d as QueryDocumentSnapshot<Map<String, dynamic>>)).toList();
      print('[DBService] Parsed ${entries.length} score entries');
      return entries;
    });
  }
}
