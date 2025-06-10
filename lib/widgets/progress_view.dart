import 'package:flutter/material.dart';

class ProgressViewWidget extends StatelessWidget {
  final String currentPhase;
  final int remainingTime;
  final int currentCycle;
  final int currentSet;
  final int elapsedSeconds;
  final int totalCycles;
  final int totalSets;
  final Color textColor;
  final LinearGradient gradient;
  final String phaseText;
  final IconData iconData;
  final Widget controls;
  final bool showElapsed;

  const ProgressViewWidget({
    super.key,
    required this.currentPhase,
    required this.remainingTime,
    required this.currentCycle,
    required this.currentSet,
    required this.elapsedSeconds,
    required this.totalCycles,
    required this.totalSets,
    required this.textColor,
    required this.gradient,
    required this.phaseText,
    required this.iconData,
    required this.controls,
    this.showElapsed = true,
  });

  @override
  Widget build(BuildContext context) {
    String displayText = remainingTime == 0 ? (currentPhase == 'PREP' || currentPhase == 'REST' ? 'Go' : '--') : remainingTime.toString();
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.08 * 255).toInt()),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      margin: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, size: 64, color: textColor),
          SizedBox(height: 16),
          Text(
            phaseText,
            style: TextStyle(fontSize: 48, color: textColor, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          Text(
            displayText,
            style: TextStyle(fontSize: 120, fontWeight: FontWeight.bold, color: textColor, shadows: [
              Shadow(blurRadius: 12, color: Colors.black26, offset: Offset(0, 4)),
            ]),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.repeat, color: textColor),
              SizedBox(width: 8),
              Text('Cycle:  $currentCycle / $totalCycles', style: TextStyle(fontSize: 24, color: textColor)),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.layers, color: textColor),
              SizedBox(width: 8),
              Text('Set:  $currentSet / $totalSets', style: TextStyle(fontSize: 24, color: textColor)),
            ],
          ),
          SizedBox(height: 24),
          if (showElapsed)
            Builder(
              builder: (context) {
                final d = Duration(seconds: elapsedSeconds);
                String twoDigits(int n) => n.toString().padLeft(2, '0');
                final timeStr = '${twoDigits(d.inHours)}:${twoDigits(d.inMinutes % 60)}:${twoDigits(d.inSeconds % 60)}';
                return Text('本次運動已進行：$timeStr', style: TextStyle(fontSize: 18, color: Colors.blueGrey));
              },
            ),
          SizedBox(height: 24),
          controls,
        ],
      ),
    );
  }
} 