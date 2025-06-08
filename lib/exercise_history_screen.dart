import 'package:flutter/material.dart';
import 'exercise_db.dart';

class ExerciseHistoryScreen extends StatefulWidget {
  const ExerciseHistoryScreen({Key? key}) : super(key: key);

  @override
  ExerciseHistoryScreenState createState() => ExerciseHistoryScreenState();
}

class ExerciseHistoryScreenState extends State<ExerciseHistoryScreen> {
  late Future<List<ExerciseRecord>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    _recordsFuture = ExerciseDatabase.instance.fetchAllRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('運動歷史紀錄')),
      body: FutureBuilder<List<ExerciseRecord>>(
        future: _recordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('讀取失敗: \\${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('尚無運動紀錄'));
          }
          final records = snapshot.data!;
          return ListView.separated(
            itemCount: records.length,
            separatorBuilder: (_, __) => Divider(),
            itemBuilder: (context, i) {
              final r = records[i];
              final totalWorkout = r.workoutTime * r.cycles * r.sets;
              final totalRest = r.restTime * r.cycles * r.sets;
              return ListTile(
                title: Text('運動時間：${_formatDuration(r.durationSeconds)}'),
                subtitle: Text('Workout: ${totalWorkout}s, Rest: ${totalRest}s, Cycles: ${r.cycles}, Sets: ${r.sets}\n${_formatDateTime(r.dateTime)}'),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inHours)}:${twoDigits(d.inMinutes % 60)}:${twoDigits(d.inSeconds % 60)}';
  }
  String _formatDateTime(String dt) {
    final d = DateTime.parse(dt);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
