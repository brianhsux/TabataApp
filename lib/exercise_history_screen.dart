import 'package:flutter/material.dart';
import 'exercise_db.dart';
import 'package:table_calendar/table_calendar.dart';

class ExerciseHistoryScreen extends StatefulWidget {
  const ExerciseHistoryScreen({super.key});

  @override
  ExerciseHistoryScreenState createState() => ExerciseHistoryScreenState();
}

class ExerciseHistoryScreenState extends State<ExerciseHistoryScreen> {
  late Future<List<ExerciseRecord>> _recordsFuture;
  final Set<int> _selectedIds = {};
  Set<DateTime> _exerciseDays = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<ExerciseRecord> _allRecords = [];

  @override
  void initState() {
    super.initState();
    _refreshRecords();
  }

  void _refreshRecords() {
    setState(() {
      _recordsFuture = ExerciseDatabase.instance.fetchAllRecords();
      _selectedIds.clear();
    });
  }

  void _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('刪除確認'),
        content: Text('確定要刪除選取的紀錄嗎？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('刪除')),
        ],
      ),
    );
    if (confirm == true) {
      await ExerciseDatabase.instance.deleteRecordsByIds(_selectedIds.toList());
      _refreshRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('運動歷史紀錄'),
        actions: [
          if (_selectedIds.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete),
              tooltip: '刪除選取',
              onPressed: _deleteSelected,
            ),
        ],
      ),
      body: FutureBuilder<List<ExerciseRecord>>(
        future: _recordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('讀取失敗: \\${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Column(
              children: [
                _buildCalendar([]),
                Expanded(child: Center(child: Text('尚無運動紀錄'))),
              ],
            );
          }
          final records = snapshot.data!;
          _allRecords = records;
          _exerciseDays = records.map((r) => DateTime.parse(r.dateTime)).map((d) => DateTime(d.year, d.month, d.day)).toSet();
          final selectedDay = _selectedDay ?? DateTime.now();
          final filteredRecords = records.where((r) {
            final d = DateTime.parse(r.dateTime);
            return d.year == selectedDay.year && d.month == selectedDay.month && d.day == selectedDay.day;
          }).toList();
          return Column(
            children: [
              _buildCalendar(records),
              Expanded(
                child: filteredRecords.isEmpty
                  ? Center(child: Text('這天沒有運動紀錄'))
                  : ListView.separated(
                      itemCount: filteredRecords.length,
                      separatorBuilder: (_, __) => Divider(),
                      itemBuilder: (context, i) {
                        final r = filteredRecords[i];
                        final totalWorkout = r.workoutTime * r.cycles * r.sets;
                        final totalRest = r.restTime * r.cycles * r.sets;
                        final selected = r.id != null && _selectedIds.contains(r.id);
                        return ListTile(
                          leading: r.id != null
                              ? Checkbox(
                                  value: selected,
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        _selectedIds.add(r.id!);
                                      } else {
                                        _selectedIds.remove(r.id);
                                      }
                                    });
                                  },
                                )
                              : null,
                          title: Text('運動時間：${_formatDuration(r.durationSeconds)}'),
                          subtitle: Text('Workout: ${totalWorkout}s, Rest: ${totalRest}s, Cycles: ${r.cycles}, Sets: ${r.sets}\n${_formatDateTime(r.dateTime)}'),
                          onLongPress: r.id != null
                              ? () {
                                  setState(() {
                                    if (_selectedIds.contains(r.id)) {
                                      _selectedIds.remove(r.id);
                                    } else {
                                      _selectedIds.add(r.id!);
                                    }
                                  });
                                }
                              : null,
                        );
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalendar(List<ExerciseRecord> records) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2100, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      availableCalendarFormats: const {CalendarFormat.month: '月'},
      calendarFormat: CalendarFormat.month,
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Colors.blueAccent,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.pinkAccent,
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          final isExerciseDay = _exerciseDays.contains(DateTime(day.year, day.month, day.day));
          if (isExerciseDay) {
            return Positioned(
              bottom: 1,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }
          return null;
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
