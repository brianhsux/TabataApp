import 'package:flutter/material.dart';

class CountdownControlsWidget extends StatelessWidget {
  final VoidCallback onPrev;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onNext;
  final bool isRunning;
  final Color textColor;

  const CountdownControlsWidget({
    super.key,
    required this.onPrev,
    required this.onPause,
    required this.onResume,
    required this.onNext,
    required this.isRunning,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(Icons.skip_previous, size: 36, color: textColor),
          tooltip: '上一個狀態',
          onPressed: onPrev,
        ),
        IconButton(
          icon: Icon(isRunning ? Icons.pause : Icons.play_arrow, size: 48, color: textColor),
          tooltip: isRunning ? '暫停' : '繼續',
          onPressed: isRunning ? onPause : onResume,
        ),
        IconButton(
          icon: Icon(Icons.skip_next, size: 36, color: textColor),
          tooltip: '下一個狀態',
          onPressed: onNext,
        ),
      ],
    );
  }
} 