import 'package:flutter/material.dart';
import 'exercise_db.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pie_chart/pie_chart.dart';
import 'main.dart' as main;
import 'l10n/app_localizations.dart';

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
        title: Text(AppLocalizations.of(context)!.deleteConfirmation),
        content: Text(AppLocalizations.of(context)!.confirmDeleteSelectedRecord),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.of(context)!.delete)),
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
        // title 移除，actions 移除
      ),
      body: FutureBuilder<List<ExerciseRecord>>(
        future: _recordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text(AppLocalizations.of(context)!.loadFailed(snapshot.error.toString())));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Column(
              children: [
                _buildCalendar([]),
                Expanded(child: Center(child: Text(AppLocalizations.of(context)!.noExerciseRecord))),
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
                  ? Center(child: Text(AppLocalizations.of(context)!.noRecordThisDay))
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
                            color: Theme.of(context).cardColor,
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
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Checkbox
                                  if (r.id != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4, right: 4, top: 12),
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
                                        activeColor: Colors.blueAccent,
                                      ),
                                    ),
                                  // 內容
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  r.workoutName?.isNotEmpty == true ? r.workoutName! : AppLocalizations.of(context)!.untitledActivity,
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
                                              Text(AppLocalizations.of(context)!.workoutTimeShort(r.workoutTime), style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                              SizedBox(width: 10),
                                              Icon(Icons.self_improvement, size: 16, color: Colors.grey[500]),
                                              SizedBox(width: 3),
                                              Text(AppLocalizations.of(context)!.restTimeShort(r.restTime), style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                              SizedBox(width: 10),
                                              Icon(Icons.repeat, size: 16, color: Colors.grey[500]),
                                              SizedBox(width: 3),
                                              Text(AppLocalizations.of(context)!.cyclesShort(r.cycles), style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                              SizedBox(width: 10),
                                              Icon(Icons.layers, size: 16, color: Colors.grey[500]),
                                              SizedBox(width: 3),
                                              Text(AppLocalizations.of(context)!.setsShort(r.sets), style: TextStyle(fontSize: 13, color: Colors.grey[700])),
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
                                  ),
                                  // 編輯 icon
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8, top: 8),
                                    child: Material(
                                      color: Colors.orange.withOpacity(0.12),
                                      shape: CircleBorder(),
                                      child: InkWell(
                                        customBorder: CircleBorder(),
                                        onTap: () async {
                                          final edited = await showDialog<ExerciseRecord>(
                                            context: context,
                                            builder: (context) {
                                              final nameCtrl = TextEditingController(text: r.workoutName ?? '');
                                              final workCtrl = TextEditingController(text: r.workoutTime.toString());
                                              final restCtrl = TextEditingController(text: r.restTime.toString());
                                              final cyclesCtrl = TextEditingController(text: r.cycles.toString());
                                              final setsCtrl = TextEditingController(text: r.sets.toString());
                                              final durationCtrl = TextEditingController(text: r.durationSeconds.toString());
                                              final dateCtrl = TextEditingController(text: r.dateTime.substring(0, 16));
                                              DateTime? pickedDateTime = DateTime.tryParse(r.dateTime);
                                              final initialTime = pickedDateTime != null
                                                  ? TimeOfDay(hour: pickedDateTime!.hour, minute: pickedDateTime!.minute)
                                                  : TimeOfDay.now();
                                              return Dialog(
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                                                  child: SingleChildScrollView(
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Icon(Icons.edit, color: Colors.orange, size: 22),
                                                            SizedBox(width: 8),
                                                            Text(AppLocalizations.of(context)!.editRecord, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                                                          ],
                                                        ),
                                                        SizedBox(height: 18),
                                                        TextField(
                                                          controller: nameCtrl,
                                                          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.activityName),
                                                        ),
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: TextField(
                                                                controller: workCtrl,
                                                                keyboardType: TextInputType.number,
                                                                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.workSeconds),
                                                              ),
                                                            ),
                                                            SizedBox(width: 8),
                                                            Expanded(
                                                              child: TextField(
                                                                controller: restCtrl,
                                                                keyboardType: TextInputType.number,
                                                                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.restSeconds),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: TextField(
                                                                controller: cyclesCtrl,
                                                                keyboardType: TextInputType.number,
                                                                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.cycles),
                                                              ),
                                                            ),
                                                            SizedBox(width: 8),
                                                            Expanded(
                                                              child: TextField(
                                                                controller: setsCtrl,
                                                                keyboardType: TextInputType.number,
                                                                decoration: InputDecoration(labelText: AppLocalizations.of(context)!.sets),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        TextField(
                                                          controller: durationCtrl,
                                                          keyboardType: TextInputType.number,
                                                          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.totalWorkoutSeconds),
                                                        ),
                                                        TextField(
                                                          controller: dateCtrl,
                                                          readOnly: true,
                                                          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.dateTime),
                                                          onTap: () async {
                                                            // 選日期
                                                            final date = await showDatePicker(
                                                              context: context,
                                                              initialDate: pickedDateTime ?? DateTime.now(),
                                                              firstDate: DateTime(2000),
                                                              lastDate: DateTime(2100),
                                                              builder: (context, child) {
                                                                return Theme(
                                                                  data: Theme.of(context).copyWith(
                                                                    textTheme: Theme.of(context).textTheme.copyWith(
                                                                      titleLarge: TextStyle(fontSize: 16),
                                                                      bodyLarge: TextStyle(fontSize: 14),
                                                                      labelLarge: TextStyle(fontSize: 13),
                                                                    ),
                                                                  ),
                                                                  child: child!,
                                                                );
                                                              },
                                                            );
                                                            if (date != null) {
                                                              // 選時間
                                                              final time = await showTimePicker(
                                                                context: context,
                                                                initialTime: initialTime,
                                                                builder: (context, child) {
                                                                  return Theme(
                                                                    data: Theme.of(context).copyWith(
                                                                      textTheme: Theme.of(context).textTheme.copyWith(
                                                                        titleLarge: TextStyle(fontSize: 16),
                                                                        bodyLarge: TextStyle(fontSize: 14),
                                                                        labelLarge: TextStyle(fontSize: 13),
                                                                      ),
                                                                    ),
                                                                    child: child!,
                                                                  );
                                                                },
                                                              );
                                                              if (time != null) {
                                                                pickedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                                                final str = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                                                dateCtrl.text = str;
                                                              }
                                                            }
                                                          },
                                                        ),
                                                        SizedBox(height: 18),
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: OutlinedButton(
                                                                onPressed: () => Navigator.pop(context, null),
                                                                child: Text(AppLocalizations.of(context)!.cancel),
                                                              ),
                                                            ),
                                                            SizedBox(width: 12),
                                                            Expanded(
                                                              child: ElevatedButton(
                                                                onPressed: () {
                                                                  final edited = ExerciseRecord(
                                                                    id: r.id,
                                                                    workoutName: nameCtrl.text,
                                                                    workoutTime: int.tryParse(workCtrl.text) ?? r.workoutTime,
                                                                    restTime: int.tryParse(restCtrl.text) ?? r.restTime,
                                                                    cycles: int.tryParse(cyclesCtrl.text) ?? r.cycles,
                                                                    sets: int.tryParse(setsCtrl.text) ?? r.sets,
                                                                    durationSeconds: int.tryParse(durationCtrl.text) ?? r.durationSeconds,
                                                                    dateTime: dateCtrl.text.isNotEmpty ? dateCtrl.text : r.dateTime,
                                                                  );
                                                                  Navigator.pop(context, edited);
                                                                },
                                                                child: Text(AppLocalizations.of(context)!.save, style: TextStyle(fontWeight: FontWeight.bold)),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                          if (edited != null) {
                                            await ExerciseDatabase.instance.updateRecord(edited);
                                            setState(_refreshRecords);
                                            main.showAppSnackBar(context, AppLocalizations.of(context)!.recordUpdated, icon: Icons.check_circle, color: Colors.green);
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Icon(Icons.edit, color: Colors.orange, size: 20),
                                        ),
                                      ),
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
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    String monthLabel;
    if (locale.languageCode == 'zh') {
      monthLabel = "${_focusedDay.year}年 ${_focusedDay.month.toString().padLeft(2, '0')}月";
    } else {
      // 英文或其他語系顯示英文月份
      final monthNames = [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      monthLabel = "${monthNames[_focusedDay.month]} ${_focusedDay.year}";
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                });
              },
            ),
            Text(
              monthLabel,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                });
              },
            ),
          ],
        ),
        TableCalendar(
          headerVisible: false,
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
        ),
      ],
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
