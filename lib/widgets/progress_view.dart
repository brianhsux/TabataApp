import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../l10n/app_localizations.dart';

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
    final localizations = AppLocalizations.of(context)!;
    String displayText = remainingTime == 0
        ? (currentPhase == 'PREP' || currentPhase == 'REST'
            ? localizations.go
            : '--')
        : remainingTime.toString();
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
          // 圓形倒數進度條
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: _getProgress(currentPhase, remainingTime, totalCycles, totalSets),
                  strokeWidth: 14,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Text(
                displayText,
                style: TextStyle(fontSize: 120, fontWeight: FontWeight.bold, color: textColor, shadows: [
                  Shadow(blurRadius: 12, color: Colors.black26, offset: Offset(0, 4)),
                ]),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.repeat, color: textColor),
              SizedBox(width: 8),
              Text(
                localizations.cycle(currentCycle, totalCycles),
                style: TextStyle(fontSize: 24, color: textColor),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.layers, color: textColor),
              SizedBox(width: 8),
              Text(
                localizations.set(currentSet, totalSets),
                style: TextStyle(fontSize: 24, color: textColor),
              ),
            ],
          ),
          SizedBox(height: 24),
          if (showElapsed)
            Builder(
              builder: (context) {
                final d = Duration(seconds: elapsedSeconds);
                String twoDigits(int n) => n.toString().padLeft(2, '0');
                final timeStr = '${twoDigits(d.inHours)}:${twoDigits(d.inMinutes % 60)}:${twoDigits(d.inSeconds % 60)}';
                return Text(localizations.elapsed(timeStr), style: TextStyle(fontSize: 18, color: Colors.blueGrey));
              },
            ),
          SizedBox(height: 24),
          controls,
        ],
      ),
    );
  }

  double _getProgress(String phase, int remaining, int totalCycles, int totalSets) {
    // 根據 phase 決定總秒數
    int total = 1;
    switch (phase) {
      case 'PREP':
        total = (remaining > 0) ? remaining : 1;
        break;
      case 'WORK':
        total = (remaining > 0) ? remaining : 1;
        break;
      case 'REST':
        total = (remaining > 0) ? remaining : 1;
        break;
      default:
        total = (remaining > 0) ? remaining : 1;
    }
    // 這裡需要外部傳入 phase 對應的總秒數，暫時用 remaining 當作 placeholder
    // 實際應用時應該傳入 phase 對應的總時間
    return total > 0 ? (total - remaining) / total : 0.0;
  }
} 