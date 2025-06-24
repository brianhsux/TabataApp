import 'package:flutter/material.dart';
import 'exercise_db.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pie_chart/pie_chart.dart';

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
  int _selectedRange = 5; // 預設5天
  final List<int> _rangeOptions = [5, 7, 14, 30, 90, 180, 360];
  int _dialogSelectedRange = 5; // dialog 內用

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
          IconButton(
            icon: Icon(Icons.pie_chart),
            tooltip: '查看運動佔比',
            onPressed: () {
              _dialogSelectedRange = _selectedRange;
              showDialog(
                context: context,
                builder: (context) => StatefulBuilder(
                  builder: (context, setState) {
                    final now = DateTime.now();
                    final start = now.subtract(Duration(days: _dialogSelectedRange - 1));
                    final Set<String> exerciseDayStrs = _allRecords.map((r) => r.dateTime.substring(0, 10)).toSet();
                    int exerciseCount = 0;
                    for (int i = 0; i < _dialogSelectedRange; i++) {
                      final d = start.add(Duration(days: i));
                      final dStr = "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
                      if (exerciseDayStrs.contains(dStr)) exerciseCount++;
                    }
                    int restCount = _dialogSelectedRange - exerciseCount;
                    final dataMap = {
                      "有運動": exerciseCount.toDouble(),
                      "沒運動": restCount.toDouble(),
                    };
                    final percent = (exerciseCount / _dialogSelectedRange * 100).toStringAsFixed(1);
                    return Dialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('運動佔比統計', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("區間：", style: TextStyle(fontSize: 15)),
                                DropdownButton<int>(
                                  value: _dialogSelectedRange,
                                  items: _rangeOptions.map((v) => DropdownMenuItem(value: v, child: Text("$v 天"))).toList(),
                                  onChanged: (v) {
                                    if (v != null) setState(() => _dialogSelectedRange = v);
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text("（${exerciseCount}天有運動）", style: TextStyle(fontSize: 15)),
                            SizedBox(height: 8),
                            SizedBox(
                              height: 140,
                              child: PieChart(
                                dataMap: dataMap,
                                chartType: ChartType.disc,
                                colorList: [Colors.blueAccent, Colors.grey[300]!],
                                chartValuesOptions: ChartValuesOptions(
                                  showChartValuesInPercentage: true,
                                  showChartValues: false,
                                  showChartValueBackground: false,
                                ),
                                legendOptions: LegendOptions(
                                  showLegends: true,
                                  legendPosition: LegendPosition.right,
                                  legendTextStyle: TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text("${_dialogSelectedRange}天內運動${exerciseCount}天，佔比 $percent%", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('關閉'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
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
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          child: Material(
                            color: Colors.white,
                            elevation: selected ? 6 : 2,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
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
                              child: Stack(
                                children: [
                                  // 主題色條
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(18),
                                          bottomLeft: Radius.circular(18),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Icon
                                        Padding(
                                          padding: const EdgeInsets.only(right: 12, top: 2),
                                          child: Icon(Icons.fitness_center, color: Colors.blueAccent, size: 28),
                                        ),
                                        // 主要內容
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      r.workoutName?.isNotEmpty == true ? r.workoutName! : '未命名活動',
                                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 0.5),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    _formatDuration(r.durationSeconds),
                                                    style: TextStyle(fontSize: 14, color: Colors.blueAccent, fontWeight: FontWeight.w600),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(Icons.timer, size: 16, color: Colors.grey[500]),
                                                  SizedBox(width: 3),
                                                  Text('W:${r.workoutTime}s', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                                  SizedBox(width: 10),
                                                  Icon(Icons.self_improvement, size: 16, color: Colors.grey[500]),
                                                  SizedBox(width: 3),
                                                  Text('R:${r.restTime}s', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                                  SizedBox(width: 10),
                                                  Icon(Icons.repeat, size: 16, color: Colors.grey[500]),
                                                  SizedBox(width: 3),
                                                  Text('C:${r.cycles}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                                  SizedBox(width: 10),
                                                  Icon(Icons.layers, size: 16, color: Colors.grey[500]),
                                                  SizedBox(width: 3),
                                                  Text('S:${r.sets}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                                ],
                                              ),
                                              SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.calendar_today, size: 15, color: Colors.grey[400]),
                                                  SizedBox(width: 4),
                                                  Text(_formatDateTime(r.dateTime), style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Checkbox
                                        if (r.id != null)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 8, top: 2),
                                            child: Checkbox(
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
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
      rowHeight: 40,
      daysOfWeekHeight: 20,
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(fontSize: 12),
        weekendStyle: TextStyle(fontSize: 12),
      ),
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
