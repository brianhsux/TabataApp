import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_screen.dart';
import 'exercise_db.dart';
import 'exercise_history_screen.dart'; // <-- 新增匯入
import 'widgets/progress_view.dart';
import 'widgets/setup_view.dart';
import 'widgets/countdown_controls.dart';
import 'widgets/exercise_report_dialog.dart';
import 'widgets/cycle_set_block.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(
    ChangeNotifierProvider(
      create: (context) => TabataState(),
      child: TabataApp(),
    ),
  );
}

class TabataApp extends StatelessWidget {
  const TabataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TabataApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 24, color: Colors.black),
          bodyMedium: TextStyle(fontSize: 18, color: Colors.black),
        ),
      ),
      home: TabataScreen(),
    );
  }
}

// State management class
class TabataState with ChangeNotifier {
  int prepTime = 10;
  int workTime = 45;
  int restTime = 15;
  int cycles = 8;
  int sets = 1;
  bool bgmEnabled = true;
  static const int defaultPrepTime = 10;
  static const int defaultWorkTime = 45;
  static const int defaultRestTime = 15;
  static const int defaultCycles = 8;
  static const int defaultSets = 1;
  TabataState() {
    _loadPreferences();
  }
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    bgmEnabled = prefs.getBool('bgmEnabled') ?? true;
    prepTime = prefs.getInt('prepTime') ?? defaultPrepTime;
    workTime = prefs.getInt('workTime') ?? defaultWorkTime;
    restTime = prefs.getInt('restTime') ?? defaultRestTime;
    cycles = prefs.getInt('cycles') ?? defaultCycles;
    sets = prefs.getInt('sets') ?? defaultSets;
    notifyListeners();
  }
  void setBgmEnabled(bool value) async {
    bgmEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bgmEnabled', value);
  }
  void updatePrepTime(int newTime) async {
    prepTime = newTime;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('prepTime', newTime);
  }
  void updateWorkTime(int newTime) async {
    workTime = newTime;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('workTime', newTime);
  }
  void updateRestTime(int newTime) async {
    restTime = newTime;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('restTime', newTime);
  }
  void updateCycles(int newCycles) async {
    cycles = newCycles;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cycles', newCycles);
  }
  void updateSets(int newSets) async {
    sets = newSets;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sets', newSets);
  }
  Future<void> resetPreferences() async {
    prepTime = defaultPrepTime;
    workTime = defaultWorkTime;
    restTime = defaultRestTime;
    cycles = defaultCycles;
    sets = defaultSets;
    bgmEnabled = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('prepTime', defaultPrepTime);
    await prefs.setInt('workTime', defaultWorkTime);
    await prefs.setInt('restTime', defaultRestTime);
    await prefs.setInt('cycles', defaultCycles);
    await prefs.setInt('sets', defaultSets);
    await prefs.setBool('bgmEnabled', true);
  }
}

class TabataScreen extends StatefulWidget {
  const TabataScreen({super.key});

  @override
  _TabataScreenState createState() => _TabataScreenState();
}

class _TabataScreenState extends State<TabataScreen> {
  late StopWatchTimer _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioPlayer? _bgmPlayer;
  bool _isRunning = false;
  bool _hasStarted = false;
  String _currentPhase = 'PREP';
  int _currentCycle = 1;
  int _currentSet = 1;
  int _remainingTime = 0;
  int? _lastBeepSecond; // 避免重複播放同一秒音效

  // 新增：運動進行秒數與 Timer
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;
  int _selectedIndex = 0; // 0: timer, 1: history
  String? _currentPresetName;
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _initTimer();

    // Initialize _remainingTime with the prepTime from TabataState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = context.read<TabataState>();
        // Make sure we're using the correct prepTime value (10 seconds)
        int prepTimeMillis = (state.prepTime + 1) * 1000;
        
        // Properly set the initial timer value
        _timer.setPresetTime(mSec: prepTimeMillis);
        
        setState(() {
          _remainingTime = state.prepTime + 1;
          // Force update to ensure timer shows correct prep time
          debugPrint('Initial prep time: 	${state.prepTime}');
        });
      }
    });

    // 初始化 Banner 廣告
    _bannerAd = BannerAd(
      //adUnitId: 'ca-app-pub-6481271799327768/7011967574',
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // 測試用
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }
  
  void _initTimer() {
    // Create a new timer instance
    _timer = StopWatchTimer(
      mode: StopWatchMode.countDown,
      onEnded: () {
        // When timer ends, trigger phase transition
        _handlePhaseTransition();
      },
      presetMillisecond: 10000, // Default to 10 seconds (for prep time)
      onChangeRawSecond: (value) {
        if (mounted && _isRunning) {
          setState(() {
            // We handle the time in onChangeRawSecond instead of rawTime.listen
            // to avoid conflicts and get better precision
            // Only update if remaining time is not already 0
            if (value >= 0) {
              _remainingTime = value;
              // 倒數音效與特殊音效
              if (_currentPhase == 'PREP' && value == (context.read<TabataState>().prepTime + 1)) {
                // PREP開始時不播聲音
              } else {
                _playCountdownBeep(_remainingTime);
              }
            }
          });
        }
      },
    );
    
    // Immediately set the timer to the correct phase time after creation
    if (mounted) {
      try {
        final state = Provider.of<TabataState>(context, listen: false);
        if (_currentPhase == 'PREP') {
          _timer.setPresetTime(mSec: state.prepTime * 1000);
        }
      } catch (e) {
        // Provider might not be available during initial call
        debugPrint('Provider not available yet during timer initialization: $e');
      }
    }
  }

  // 新增：啟動/停止運動秒數 Timer
  void _startElapsedTimer() {
    _elapsedSeconds = 0;
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }
  void _stopElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
  }

  @override
  void dispose() {
    _timer.dispose();
    _audioPlayer.dispose();
    _bgmPlayer?.dispose();
    _stopElapsedTimer(); // 確保釋放 Timer
    _bannerAd?.dispose();
    super.dispose();
  }

  void _startTimer() {
    _hasStarted = true;
    _startElapsedTimer(); // 運動一開始就啟動計時
    // Only set preset time if timer is not already running
    if (!_isRunning) {
      final state = Provider.of<TabataState>(context, listen: false);
      int presetMillis;
      // Ensure timer is correctly initialized
      _timer.onStopTimer();
      // Add 1 second to each phase for a full countdown experience
      if (_currentPhase == 'PREP') {
        presetMillis = (state.prepTime + 1) * 1000;
        _remainingTime = state.prepTime + 1;
      } else if (_currentPhase == 'WORK') {
        presetMillis = (state.workTime + 1) * 1000;
        _remainingTime = state.workTime + 1;
      } else { // REST
        presetMillis = (state.restTime + 1) * 1000;
        _remainingTime = state.restTime + 1;
      }
      _timer.onResetTimer();
      _timer.setPresetTime(mSec: presetMillis);
      setState(() {
        _remainingTime = _currentPhase == 'PREP' ? state.prepTime + 1 :
                         _currentPhase == 'WORK' ? state.workTime + 1 : state.restTime + 1;
      });
    }
    _timer.onStartTimer();
    setState(() {
      _isRunning = true;
    });
    if (_currentPhase == 'WORK') {
      _playBgm('workout');
    } else if (_currentPhase == 'REST') {
      _playBgm('rest');
    }
  }

  void _stopTimer({bool userInitiated = false, bool showReportDirectly = false}) async {
    await _stopBgm();
    _timer.onStopTimer();
    setState(() {
      _isRunning = false;
    });
    _stopElapsedTimer();
    if (showReportDirectly) {
      final state = Provider.of<TabataState>(context, listen: false);
      final endTime = DateTime.now();
      final duration = _elapsedSeconds;
      final record = ExerciseRecord(
        workoutTime: state.workTime,
        restTime: state.restTime,
        cycles: state.cycles,
        sets: state.sets,
        durationSeconds: duration,
        dateTime: endTime.toIso8601String(),
      );
      await ExerciseDatabase.instance.insertRecord(record);
      _showExerciseReportDialogFromRecord(record);
      return;
    }
    if (userInitiated) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('確定要停止運動嗎？'),
          content: Text('這將結束本次運動，且不會儲存紀錄。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('否'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('是'),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        // 若使用者選否，繼續運動（從暫停秒數繼續）
        // 不要 setState(_isRunning = true) 以避免 build 觸發 _remainingTime 重設
        _isRunning = true;
        _timer.onStartTimer();
        if (_currentPhase == 'WORK') {
          _playBgm('workout');
        } else if (_currentPhase == 'REST') {
          _playBgm('rest');
        }
        return;
      }
      // 若選是，回到設置頁並重設 timer
      _resetTimer();
      return;
    }
    final state = Provider.of<TabataState>(context, listen: false);
    final endTime = DateTime.now();
    final duration = _elapsedSeconds;
    final record = ExerciseRecord(
      workoutTime: state.workTime,
      restTime: state.restTime,
      cycles: state.cycles,
      sets: state.sets,
      durationSeconds: duration,
      dateTime: endTime.toIso8601String(),
    );
    await ExerciseDatabase.instance.insertRecord(record);
    _showExerciseReportDialogFromRecord(record);
  }

  void _showExerciseReportDialogFromRecord(ExerciseRecord record) {
    final totalWorkout = record.workoutTime * record.cycles * record.sets;
    final totalRest = record.restTime * record.cycles * record.sets;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('運動結果報告'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('運動時間：${_formatDuration(record.durationSeconds)}'),
            Text('Workout 秒數：$totalWorkout'),
            Text('Rest 秒數：$totalRest'),
            Text('Cycles：${record.cycles}'),
            Text('Sets：${record.sets}'),
            Text('日期：${_formatDateTime(record.dateTime)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetTimer();
            },
            child: Text('確定'),
          ),
        ],
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

  void _resetTimer() async {
    await _stopBgm(); // reset 時也停止背景音樂
    _timer.onStopTimer();
    _timer.dispose();
    _initTimer();
    _stopElapsedTimer(); // 停止本地秒數計時
    if (mounted) {
      final state = Provider.of<TabataState>(context, listen: false);
      int prepTimeMillis = (state.prepTime + 1) * 1000;
      _timer.setPresetTime(mSec: prepTimeMillis);
      setState(() {
        _isRunning = false;
        _hasStarted = false;
        _currentPhase = 'PREP';
        _currentCycle = 1;
        _currentSet = 1;
        _remainingTime = state.prepTime + 1;
        _elapsedSeconds = 0;
      });
    }
  }

  void _handlePhaseTransition() async {
    final state = Provider.of<TabataState>(context, listen: false);
    debugPrint('Phase transition from: $_currentPhase');
    if (_isRunning) {
      await _stopBgm();
      if (_currentPhase == 'PREP') {
        _timer.onStopTimer();
        setState(() {
          _currentPhase = 'WORK';
          _remainingTime = state.workTime + 1;
        });
        _timer.onResetTimer();
        _timer.setPresetTime(mSec: (state.workTime + 1) * 1000);
        await _playBgm('workout'); // 播放workout背景音樂
        _timer.onStartTimer();
      } else if (_currentPhase == 'WORK') {
        _timer.onStopTimer();
        setState(() {
          _currentPhase = 'REST';
          _remainingTime = state.restTime + 1;
        });
        _timer.onResetTimer();
        _timer.setPresetTime(mSec: (state.restTime + 1) * 1000);
        await _playBgm('rest'); // 播放rest背景音樂
        _timer.onStartTimer();
      } else if (_currentPhase == 'REST') {
        if (_currentCycle < state.cycles) {
          setState(() {
            _currentCycle++;
            _currentPhase = 'WORK';
            _remainingTime = state.workTime + 1;
          });
          _timer.setPresetTime(mSec: (state.workTime + 1) * 1000);
          _timer.onResetTimer();
          await _playBgm('workout'); // 播放workout背景音樂
          _timer.onStartTimer();
        } else if (_currentSet < state.sets) {
          setState(() {
            _currentSet++;
            _currentCycle = 1;
            _currentPhase = 'PREP';
            _remainingTime = state.prepTime + 1;
          });
          _timer.setPresetTime(mSec: (state.prepTime + 1) * 1000);
          _timer.onResetTimer();
          _timer.onStartTimer();
        } else {
          // 最後一輪workout結束時也要累積
          _stopTimer(showReportDirectly: true);
          _resetTimer();
        }
      }
    }
  }

  // 倒數音效與特殊音效
  Future<void> _playCountdownBeep(int second) async {
    if (_lastBeepSecond == second) return;
    _lastBeepSecond = second;
    if (_currentPhase == 'PREP' || _currentPhase == 'REST') {
      if (second == 3 || second == 2 || second == 1) {
        await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
      } else if (second == 0) {
        await _audioPlayer.play(AssetSource('sounds/start.wav'));
      }
    } else if (_currentPhase == 'WORK') {
      if (second == 0) {
        await _audioPlayer.play(AssetSource('sounds/victory.wav'));
      }
    }
  }

  void _showEditDialog(String phase, int currentTime, Function(int) onUpdate) {
    int newTime = currentTime;
    TextEditingController controller = TextEditingController(text: currentTime.toString());
    showDialog(
      context: context,
      builder: (context) {
        Color mainColor;
        IconData iconData;
        switch (phase.toLowerCase()) {
          case 'prep':
            mainColor = Colors.orange.shade400;
            iconData = Icons.timer;
            break;
          case 'work':
            mainColor = Colors.red.shade400;
            iconData = Icons.fitness_center;
            break;
          case 'rest':
            mainColor = Colors.green.shade400;
            iconData = Icons.self_improvement;
            break;
          default:
            mainColor = Colors.blueGrey;
            iconData = Icons.settings;
        }
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconData, color: mainColor, size: 40),
                SizedBox(height: 12),
                Text(
                  '設定 $phase 時間',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: mainColor,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 18),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '請輸入秒數',
                    filled: true,
                    fillColor: mainColor.withOpacity(0.08),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(fontSize: 18),
                  autofocus: true,
                  onSubmitted: (v) => Navigator.pop(context, v.trim()),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, null),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('取消'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          newTime = int.tryParse(controller.text) ?? currentTime;
                          if (newTime > 0) {
                            onUpdate(newTime);
                          }
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('確認', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressView(TabataState state, {bool showElapsed = false, double scale = 1.0}) {
    LinearGradient gradient;
    Color textColor;
    String phaseText;
    IconData iconData;
    // Make sure the displayed time is correct based on the current phase
    int displayTime = _remainingTime;
    String displayText = '';
    if (_currentPhase == 'PREP' || _currentPhase == 'REST') {
      if (_remainingTime == 0) {
        // 最後一個cycle、最後一個set、rest狀態且倒數到0時顯示Done
        final isLastRest = _currentPhase == 'REST' &&
          _currentCycle == state.cycles &&
          _currentSet == state.sets;
        displayText = isLastRest ? 'Done' : 'Go';
      } else {
        displayText = displayTime.toString();
      }
    } else if (_currentPhase == 'WORK') {
      if (_remainingTime == 0) {
        displayText = '--';
      } else {
        displayText = displayTime.toString();
      }
    } else {
      displayText = displayTime.toString();
    }
    switch (_currentPhase) {
      case 'PREP':
        gradient = LinearGradient(
          colors: [Colors.yellow.shade200, Colors.orange.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        textColor = Colors.orange.shade900;
        phaseText = 'Prep';
        iconData = Icons.timer;
        break;
      case 'WORK':
        gradient = LinearGradient(
          colors: [Colors.red.shade400, Colors.pink.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        textColor = Colors.white;
        phaseText = 'Work';
        iconData = Icons.fitness_center;
        break;
      case 'REST':
        gradient = LinearGradient(
          colors: [Colors.green.shade400, Colors.teal.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        textColor = Colors.white;
        phaseText = 'Rest';
        iconData = Icons.self_improvement;
        break;
      default:
        gradient = LinearGradient(
          colors: [Colors.grey.shade300, Colors.grey.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        textColor = Colors.black;
        phaseText = _currentPhase;
        iconData = Icons.hourglass_empty;
    }
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(32 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.08 * 255).toInt()),
            blurRadius: 16 * scale,
            offset: Offset(0, 8 * scale),
          ),
        ],
      ),
      margin: EdgeInsets.all(24 * scale),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, size: 64 * scale, color: textColor),
          SizedBox(height: 16 * scale),
          Text(
            phaseText,
            style: TextStyle(fontSize: 48 * scale, color: textColor, fontWeight: FontWeight.bold, letterSpacing: 2 * scale),
          ),
          // 圓形倒數進度條
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 240 * scale,
                height: 240 * scale,
                child: CircularProgressIndicator(
                  value: _getProgress(),
                  strokeWidth: 16 * scale,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Text(
                displayText,
                style: TextStyle(
                  fontSize: displayText == 'Done' ? 72 * scale : 120 * scale,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  shadows: [
                    Shadow(blurRadius: 12 * scale, color: Colors.black26, offset: Offset(0, 4 * scale)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20 * scale),
          // Cycle and Set on separate lines
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.repeat, color: textColor, size: 24 * scale),
              SizedBox(width: 8 * scale),
              Text(
                'Cycle:  $_currentCycle / ${state.cycles}',
                style: TextStyle(fontSize: 24 * scale, color: textColor),
              ),
            ],
          ),
          SizedBox(height: 12 * scale),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.layers, color: textColor, size: 24 * scale),
              SizedBox(width: 8 * scale),
              Text(
                'Set:  $_currentSet / ${state.sets}',
                style: TextStyle(fontSize: 24 * scale, color: textColor),
              ),
            ],
          ),
          SizedBox(height: 24 * scale),
          if (showElapsed)
            Builder(
              builder: (context) {
                final d = Duration(seconds: _elapsedSeconds);
                String twoDigits(int n) => n.toString().padLeft(2, '0');
                final timeStr = '${twoDigits(d.inHours)}:${twoDigits(d.inMinutes % 60)}:${twoDigits(d.inSeconds % 60)}';
                return Text('本次運動已進行：$timeStr', style: TextStyle(fontSize: 18 * scale, color: Colors.blueGrey));
              },
            ),
          SizedBox(height: 24 * scale),
          // 控制按鈕
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 上一個狀態
              IconButton(
                icon: Icon(Icons.skip_previous, size: 36 * scale, color: textColor),
                tooltip: '上一個狀態',
                onPressed: () {
                  final state = context.read<TabataState>();
                  if (_currentPhase == 'REST') {
                    setState(() {
                      _currentPhase = 'WORK';
                      _remainingTime = state.workTime + 1;
                      _isRunning = true;
                    });
                    _timer.onStopTimer();
                    _timer.onResetTimer();
                    _timer.setPresetTime(mSec: (state.workTime + 1) * 1000);
                    _timer.onStartTimer();
                    _playBgm('workout');
                  } else if (_currentPhase == 'WORK') {
                    if (_currentCycle > 1) {
                      setState(() {
                        _currentCycle--;
                        _currentPhase = 'REST';
                        _remainingTime = state.restTime + 1;
                        _isRunning = true;
                      });
                      _timer.onStopTimer();
                      _timer.onResetTimer();
                      _timer.setPresetTime(mSec: (state.restTime + 1) * 1000);
                      _timer.onStartTimer();
                      _playBgm('rest');
                    }
                  }
                },
              ),
              // 暫停/繼續按鈕
              IconButton(
                icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 48 * scale, color: textColor),
                tooltip: _isRunning ? '暫停' : '繼續',
                onPressed: () {
                  if (_isRunning) {
                    _pauseTimer();
                  } else {
                    _resumeTimer();
                  }
                },
              ),
              // 下一個狀態
              IconButton(
                icon: Icon(Icons.skip_next, size: 36 * scale, color: textColor),
                tooltip: '下一個狀態',
                onPressed: () {
                  final state = context.read<TabataState>();
                  if (_currentPhase == 'PREP') {
                    setState(() {
                      _currentPhase = 'WORK';
                      _remainingTime = state.workTime + 1;
                      _isRunning = true;
                    });
                    _timer.onStopTimer();
                    _timer.onResetTimer();
                    _timer.setPresetTime(mSec: (state.workTime + 1) * 1000);
                    _timer.onStartTimer();
                    _playBgm('workout');
                  } else if (_currentPhase == 'WORK') {
                    setState(() {
                      _currentPhase = 'REST';
                      _remainingTime = state.restTime + 1;
                      _isRunning = true;
                    });
                    _timer.onStopTimer();
                    _timer.onResetTimer();
                    _timer.setPresetTime(mSec: (state.restTime + 1) * 1000);
                    _timer.onStartTimer();
                    _playBgm('rest');
                  } else if (_currentPhase == 'REST') {
                    if (_currentCycle < state.cycles) {
                      setState(() {
                        _currentCycle++;
                        _currentPhase = 'WORK';
                        _remainingTime = state.workTime + 1;
                        _isRunning = true;
                      });
                      _timer.onStopTimer();
                      _timer.onResetTimer();
                      _timer.setPresetTime(mSec: (state.workTime + 1) * 1000);
                      _timer.onStartTimer();
                      _playBgm('workout');
                    } else if (_currentCycle == state.cycles && _currentSet < state.sets) {
                      // 進入下一個 set
                      setState(() {
                        _currentSet++;
                        _currentCycle = 1;
                        _currentPhase = 'WORK';
                        _remainingTime = state.workTime + 1;
                        _isRunning = true;
                      });
                      _timer.onStopTimer();
                      _timer.onResetTimer();
                      _timer.setPresetTime(mSec: (state.workTime + 1) * 1000);
                      _timer.onStartTimer();
                      _playBgm('workout');
                    } else if (_currentCycle == state.cycles && _currentSet == state.sets) {
                      // 最後一個 cycle 和最後一個 set，直接顯示結算報告
                      _stopTimer(showReportDirectly: true);
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 新增：運動模板控制元件
  Widget _buildTemplateControls(TabataState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 目前活動名稱以卡片質感顯示，有副標題、漸層、圓角、陰影
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade100, Colors.deepPurple.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.18),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                _currentPresetName ?? '尚未選擇活動',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.deepPurple.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          // 切換活動與建立新活動按鈕同一行
          Row(
            children: [
              // 切換活動下拉選單
              Expanded(
                child: FutureBuilder<List<WorkoutPreset>>(
                  key: ValueKey((_currentPresetName ?? '') + '_' + DateTime.now().millisecondsSinceEpoch.toString()),
                  future: ExerciseDatabase.instance.fetchAllPresets(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return SizedBox();
                    final presets = snapshot.data!;
                    final selectedPreset = presets.where((p) => p.name == _currentPresetName).isNotEmpty
                        ? presets.firstWhere((p) => p.name == _currentPresetName)
                        : null;
                    return DropdownButtonHideUnderline(
                      child: DropdownButton2<WorkoutPreset>(
                        customButton: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade100, Colors.blue.shade300], // 切換活動用藍色系
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.12),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.swap_horiz, color: Colors.blue.shade700, size: 22),
                              SizedBox(width: 6),
                              Text(
                                '切換活動',
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Icon(Icons.keyboard_arrow_down_rounded, color: Colors.blue.shade700, size: 22),
                            ],
                          ),
                        ),
                        dropdownStyleData: DropdownStyleData(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.08),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        items: presets.map((preset) {
                          return DropdownMenuItem<WorkoutPreset>(
                            value: preset,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.bookmark, color: Colors.blueAccent),
                                    SizedBox(width: 8),
                                    Text(
                                      preset.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueAccent,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                                  tooltip: '刪除活動',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('刪除活動'),
                                        content: Text('確定要刪除「${preset.name}」這個活動嗎？'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: Text('取消'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: Text('刪除', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ExerciseDatabase.instance.deletePresetByName(preset.name);
                                      if (_currentPresetName == preset.name) {
                                        setState(() {
                                          _currentPresetName = null;
                                        });
                                      } else {
                                        setState(() {});
                                      }
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已刪除活動 ${preset.name}')));
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        value: selectedPreset,
                        onChanged: (preset) {
                          if (preset != null) {
                            state.updatePrepTime(preset.prepTime);
                            state.updateWorkTime(preset.workTime);
                            state.updateRestTime(preset.restTime);
                            state.updateCycles(preset.cycles);
                            state.updateSets(preset.sets);
                            setState(() {
                              _currentPresetName = preset.name;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已載入活動 ${preset.name}')));
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: 16),
              // 建立新活動按鈕
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    String? name = await showDialog<String>(
                      context: context,
                      builder: (context) {
                        TextEditingController controller = TextEditingController();
                        return Dialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_circle_outline, color: Colors.pink.shade400, size: 40),
                                SizedBox(height: 12),
                                Text(
                                  '建立新活動',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.pink.shade400,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: 18),
                                TextField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    hintText: '請輸入活動名稱',
                                    filled: true,
                                    fillColor: Colors.pink.shade50,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  style: TextStyle(fontSize: 18),
                                  autofocus: true,
                                  onSubmitted: (v) => Navigator.pop(context, v.trim()),
                                ),
                                SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.pop(context, null),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.grey,
                                          side: BorderSide(color: Colors.grey.shade300),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                        child: Text('取消'),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.pop(context, controller.text.trim()),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.pink.shade400,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          padding: EdgeInsets.symmetric(vertical: 14),
                                        ),
                                        child: Text('建立', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                    if (name != null && name.isNotEmpty) {
                      final preset = WorkoutPreset(
                        name: name,
                        prepTime: state.prepTime,
                        workTime: state.workTime,
                        restTime: state.restTime,
                        cycles: state.cycles,
                        sets: state.sets,
                      );
                      await ExerciseDatabase.instance.insertPreset(preset);
                      setState(() {
                        _currentPresetName = name;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已建立活動 $name')));
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.pink.shade100, Colors.pink.shade300], // 建立新活動用粉紅色系
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.withOpacity(0.12),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline, color: Colors.pink.shade700, size: 22),
                        SizedBox(width: 6),
                        Text(
                          '建立新活動',
                          style: TextStyle(
                            color: Colors.pink.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetupView(TabataState state, {double scale = 1.0}) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTemplateControls(state),
          // Preparation block
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.yellow.shade200, Colors.orange.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16 * scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.yellow.withAlpha((0.3 * 255).toInt()),
                  blurRadius: 8 * scale,
                  offset: Offset(0, 4 * scale),
                ),
              ],
            ),
            margin: EdgeInsets.symmetric(vertical: 8 * scale, horizontal: 16 * scale),
            padding: EdgeInsets.symmetric(vertical: 16 * scale, horizontal: 12 * scale),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer, color: Colors.orange.shade900),
                SizedBox(width: 10 * scale),
                Text('Prep', style: TextStyle(fontSize: 24 * scale, color: Colors.orange.shade900, fontWeight: FontWeight.bold)),
                SizedBox(width: 10 * scale),
                Text(
                  state.prepTime.toString(),
                  style: TextStyle(fontSize: 24 * scale, color: Colors.orange.shade900, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 10 * scale),
                IconButton(
                  icon: Icon(Icons.settings, color: Colors.orange.shade900),
                  onPressed: () => _showEditDialog('Prep', state.prepTime, state.updatePrepTime),
                ),
              ],
            ),
          ),
          // Exercise block
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.pink.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16 * scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withAlpha((0.3 * 255).toInt()),
                  blurRadius: 8 * scale,
                  offset: Offset(0, 4 * scale),
                ),
              ],
            ),
            margin: EdgeInsets.symmetric(vertical: 8 * scale, horizontal: 16 * scale),
            padding: EdgeInsets.symmetric(vertical: 16 * scale, horizontal: 12 * scale),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center, color: Colors.white),
                SizedBox(width: 10 * scale),
                Text('Work', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(width: 10 * scale),
                Text(
                  state.workTime.toString(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 10 * scale),
                IconButton(
                  icon: Icon(Icons.settings, color: Colors.white),
                  onPressed: () => _showEditDialog('Work', state.workTime, state.updateWorkTime),
                ),
              ],
            ),
          ),
          // Rest block
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.teal.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16 * scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withAlpha((0.3 * 255).toInt()),
                  blurRadius: 8 * scale,
                  offset: Offset(0, 4 * scale),
                ),
              ],
            ),
            margin: EdgeInsets.symmetric(vertical: 8 * scale, horizontal: 16 * scale),
            padding: EdgeInsets.symmetric(vertical: 16 * scale, horizontal: 12 * scale),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.self_improvement, color: Colors.white),
                SizedBox(width: 10 * scale),
                Text('Rest', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(width: 10 * scale),
                Text(
                  state.restTime.toString(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 10 * scale),
                IconButton(
                  icon: Icon(Icons.settings, color: Colors.white),
                  onPressed: () => _showEditDialog('Rest', state.restTime, state.updateRestTime),
                ),
              ],
            ),
          ),
          // Bottom cycles and sets block
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.indigo.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16 * scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withAlpha((0.3 * 255).toInt()),
                  blurRadius: 8 * scale,
                  offset: Offset(0, 4 * scale),
                ),
              ],
            ),
            margin: EdgeInsets.symmetric(vertical: 8 * scale, horizontal: 16 * scale),
            padding: EdgeInsets.symmetric(vertical: 6 * scale, horizontal: 8 * scale),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.repeat, color: Colors.white, size: 18 * scale),
                    SizedBox(width: 2 * scale),
                    Text('Cycles', style: TextStyle(fontSize: 18 * scale, color: Colors.white)),
                    SizedBox(width: 2 * scale),
                    IconButton(
                      icon: Icon(Icons.remove, color: Colors.white, size: 18 * scale),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        if (state.cycles > 1) state.updateCycles(state.cycles - 1);
                      },
                    ),
                    Text(
                      state.cycles.toString(),
                      style: TextStyle(fontSize: 15 * scale, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, color: Colors.white, size: 18 * scale),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => state.updateCycles(state.cycles + 1),
                    ),
                  ],
                ),
                SizedBox(height: 4 * scale),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.layers, color: Colors.white, size: 18 * scale),
                    SizedBox(width: 2 * scale),
                    Text('Sets', style: TextStyle(fontSize: 18 * scale, color: Colors.white)),
                    SizedBox(width: 2 * scale),
                    IconButton(
                      icon: Icon(Icons.remove, color: Colors.white, size: 18 * scale),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        if (state.sets > 1) state.updateSets(state.sets - 1);
                      },
                    ),
                    Text(
                      state.sets.toString(),
                      style: TextStyle(fontSize: 15 * scale, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, color: Colors.white, size: 18 * scale),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => state.updateSets(state.sets + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TabataState>();
    // 只在初始狀態才重設 _remainingTime
    bool showSetup = !_hasStarted && _currentPhase == 'PREP' && _currentCycle == 1 && _currentSet == 1;
    if (showSetup) {
      if (_remainingTime != state.prepTime) {
        _remainingTime = state.prepTime;
      }
    }

    // 動態縮放：螢幕高度小於900時線性縮小UI，並扣除 banner 高度
    final screenHeight = MediaQuery.of(context).size.height;
    print('DEBUG: screenHeight = ' + screenHeight.toString());
    double scale = 1.0;
    final bannerHeight = 50.0;
    final availableHeight = screenHeight - bannerHeight;
    if (availableHeight < 900) {
      scale = (availableHeight / 900).clamp(0.7, 1.0);
    }

    final List<Widget> _pages = [
      Column(
        children: [
          Expanded(
            child: showSetup ? _buildSetupView(state, scale: scale) : _buildProgressView(state, showElapsed: true, scale: scale),
          ),
          if (showSetup)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 52 * scale,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28 * scale),
                    ),
                    elevation: 8,
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.black45,
                  ).copyWith(
                    backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) => null),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                  onPressed: _startTimer,
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.pinkAccent, Colors.deepPurpleAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28 * scale),
                    ),
                    child: Container(
                      height: 52 * scale,
                      alignment: Alignment.center,
                      child: Text(
                        'Start',
                        style: TextStyle(
                          fontSize: 18 * scale,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 8, color: Colors.black26, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      ExerciseHistoryScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Tabata Timer', style: TextStyle(fontSize: 22 * scale)),
        leading: !showSetup
            ? IconButton(
                icon: Icon(Icons.close, size: 22 * scale),
                tooltip: 'Stop',
                onPressed: () => _stopTimer(userInitiated: true),
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, size: 22 * scale),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          if (_isBannerLoaded && _bannerAd != null)
            Container(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 22 * scale), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.history, size: 22 * scale), label: ''),
        ],
      ),
    );
  }

  Future<void> _playBgm(String phase) async {
    final state = Provider.of<TabataState>(context, listen: false);
    if (!state.bgmEnabled) return;
    await _stopBgm();
    _bgmPlayer = AudioPlayer();
    String asset = phase == 'workout' ? 'assets/sounds/mystery.wav' : 'assets/sounds/rest.wav';
    await _bgmPlayer!.setSource(AssetSource(asset.replaceFirst('assets/', '')));
    await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer!.resume();
  }

  Future<void> _stopBgm() async {
    if (_bgmPlayer != null) {
      await _bgmPlayer!.stop();
      await _bgmPlayer!.dispose();
      _bgmPlayer = null;
    }
  }

  void _pauseTimer() {
    _timer.onStopTimer();
    _stopElapsedTimer();
    _stopBgm();
    setState(() {
      _isRunning = false;
    });
  }
  void _resumeTimer() {
    _hasStarted = true;
    _timer.onStartTimer();
    _startElapsedTimer();
    setState(() {
      _isRunning = true;
    });
    if (_currentPhase == 'WORK') {
      _playBgm('workout');
    } else if (_currentPhase == 'REST') {
      _playBgm('rest');
    }
  }

  double _getProgress() {
    int total = 1;
    final state = context.read<TabataState>();
    switch (_currentPhase) {
      case 'PREP':
        total = state.prepTime + 1;
        break;
      case 'WORK':
        total = state.workTime + 1;
        break;
      case 'REST':
        total = state.restTime + 1;
        break;
      default:
        total = _remainingTime > 0 ? _remainingTime : 1;
    }
    return total > 0 ? (total - _remainingTime) / total : 0.0;
  }
}