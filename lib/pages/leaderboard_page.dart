import 'package:flutter/material.dart';
import '../services/db_service.dart';

// display top 20 scores from database
class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          // refresh score list
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {}); // Force rebuild to refresh stream
            },
          ),
        ],
      ),
      // listen for real-time score updates
      body: StreamBuilder<List<ScoreEntry>>(
        stream: DBService.instance.topScoresStream(limit: 20),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            print('[Leaderboard Error] ${snap.error}');
            return Center(child: Text('Error: ${snap.error}'));
          }
          final list = snap.data ?? [];
          print('[Leaderboard] Fetched ${list.length} scores');
          for (final e in list) {
            print('[Leaderboard] Score: ${e.nickname} - ${e.score} pts - ${e.timeSeconds}s');
          }
          if (list.isEmpty) {
            return const Center(child: Text('No scores yet'));
          }
          // show rank, name, time, score for each entry
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = list[i];
              return ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(e.nickname),
                subtitle: Text('Time: ${e.timeSeconds}s'),
                trailing: Text('${e.score}', style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          );
        },
      ),
    );
  }
}
