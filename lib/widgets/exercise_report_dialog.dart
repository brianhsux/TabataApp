import 'package:flutter/material.dart';

class ExerciseReportDialog extends StatelessWidget {
  final String durationText;
  final int totalWorkout;
  final int totalRest;
  final int cycles;
  final int sets;
  final String dateText;
  final VoidCallback onConfirm;

  const ExerciseReportDialog({
    super.key,
    required this.durationText,
    required this.totalWorkout,
    required this.totalRest,
    required this.cycles,
    required this.sets,
    required this.dateText,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('運動結果報告'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('運動時間：$durationText'),
          Text('Workout 秒數：$totalWorkout'),
          Text('Rest 秒數：$totalRest'),
          Text('Cycles：$cycles'),
          Text('Sets：$sets'),
          Text('日期：$dateText'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onConfirm,
          child: Text('確定'),
        ),
      ],
    );
  }
} 