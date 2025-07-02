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
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:pie_chart/pie_chart.dart';

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

class TabataApp extends StatefulWidget {
  const TabataApp({super.key});

  @override
  State<TabataApp> createState() => _TabataAppState();
}

class _TabataAppState extends State<TabataApp> {
  Locale? _locale;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<TabataState>(context, listen: false);
      setState(() {
        _themeMode = state.themeMode;
      });
      state.addListener(() {
        setState(() {
          _themeMode = state.themeMode;
        });
      });
    });
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

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
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      locale: _locale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      ],
      home: TabataScreen(
        onLocaleChanged: setLocale,
        onThemeModeChanged: (mode) {
          final state = Provider.of<TabataState>(context, listen: false);
          state.setThemeMode(mode);
        },
      ),
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
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
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
    int? themeIdx = prefs.getInt('themeMode');
    if (themeIdx != null) {
      _themeMode = ThemeMode.values[themeIdx];
    }
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
  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
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
  final Function(Locale)? onLocaleChanged;
  final Function(ThemeMode)? onThemeModeChanged;
  const TabataScreen({super.key, this.onLocaleChanged, this.onThemeModeChanged});

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
    WakelockPlus.enable(); // 防止螢幕關閉
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
    WakelockPlus.disable(); // 停止時釋放 wakelock
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
        workoutName: _currentPresetName,
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
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.deepOrange, size: 48),
                SizedBox(height: 18),
                Text(
                  AppLocalizations.of(context)!.confirmStopWorkout,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.endWorkoutNoSave,
                  style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    SizedBox(width: 18),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(AppLocalizations.of(context)!.delete, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
      workoutName: _currentPresetName,
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events_rounded, color: Colors.amber.shade700, size: 54),
              SizedBox(height: 18),
              Text(
                AppLocalizations.of(context)!.workoutResultReport,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _reportRow(AppLocalizations.of(context)!.workoutTime, _formatDuration(record.durationSeconds)),
                    SizedBox(height: 8),
                    _reportRow(AppLocalizations.of(context)!.workoutSeconds, '$totalWorkout'),
                    SizedBox(height: 8),
                    _reportRow(AppLocalizations.of(context)!.restSeconds, '$totalRest'),
                    SizedBox(height: 8),
                    _reportRow(AppLocalizations.of(context)!.cycles, '${record.cycles}'),
                    SizedBox(height: 8),
                    _reportRow(AppLocalizations.of(context)!.sets, '${record.sets}'),
                    SizedBox(height: 8),
                    _reportRow(AppLocalizations.of(context)!.dateTime, _formatDateTime(record.dateTime)),
                  ],
                ),
              ),
              SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _resetTimer();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(AppLocalizations.of(context)!.confirm, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber[900])),
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

  void _resetTimer() async {
    WakelockPlus.disable(); // 重設時釋放 wakelock
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
          case 'cycles':
            mainColor = Colors.blue.shade400;
            iconData = Icons.repeat;
            break;
          case 'sets':
            mainColor = Colors.purple.shade400;
            iconData = Icons.layers;
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
                  AppLocalizations.of(context)!.setPhaseTime(phase),
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
                    hintText: AppLocalizations.of(context)!.pleaseEnterSeconds,
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
                        child: Text(AppLocalizations.of(context)!.cancel),
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
                        child: Text(AppLocalizations.of(context)!.confirm, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
        displayText = isLastRest ? AppLocalizations.of(context)!.done : AppLocalizations.of(context)!.go;
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
        phaseText = AppLocalizations.of(context)!.prep;
        iconData = Icons.timer;
        break;
      case 'WORK':
        gradient = LinearGradient(
          colors: [Colors.red.shade400, Colors.pink.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        textColor = Colors.white;
        phaseText = AppLocalizations.of(context)!.work;
        iconData = Icons.fitness_center;
        break;
      case 'REST':
        gradient = LinearGradient(
          colors: [Colors.green.shade400, Colors.teal.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        textColor = Colors.white;
        phaseText = AppLocalizations.of(context)!.rest;
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
      margin: EdgeInsets.all(16 * scale),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, size: 48 * scale, color: textColor),
          SizedBox(height: 12 * scale),
          Text(
            phaseText,
            style: TextStyle(fontSize: 48 * scale, color: textColor, fontWeight: FontWeight.bold, letterSpacing: 2 * scale),
          ),
          SizedBox(height: 16 * scale),
          // 圓形倒數進度條
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 300 * scale,
                height: 300 * scale,
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
                  fontSize: (displayText == AppLocalizations.of(context)!.done || displayText == AppLocalizations.of(context)!.go) 
                  ? 72 * scale : 120 * scale,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  shadows: [
                    Shadow(blurRadius: 12 * scale, color: Colors.black26, offset: Offset(0, 4 * scale)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * scale),
          // Cycle and Set on separate lines
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.repeat, color: textColor, size: 24 * scale),
              SizedBox(width: 8 * scale),
              Text(
                AppLocalizations.of(context)!.cycle(_currentCycle, state.cycles),
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
                AppLocalizations.of(context)!.set(_currentSet, state.sets),
                style: TextStyle(fontSize: 24 * scale, color: textColor),
              ),
            ],
          ),
          SizedBox(height: 12 * scale),
          if (showElapsed)
            Builder(
              builder: (context) {
                final d = Duration(seconds: _elapsedSeconds);
                String twoDigits(int n) => n.toString().padLeft(2, '0');
                final timeStr = '${twoDigits(d.inHours)}:${twoDigits(d.inMinutes % 60)}:${twoDigits(d.inSeconds % 60)}';
                return Text(AppLocalizations.of(context)!.elapsed(timeStr), style: TextStyle(fontSize: 18 * scale, color: Colors.white, fontWeight: FontWeight.bold));
              },
            ),
          SizedBox(height: 12 * scale),
          // 控制按鈕
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 上一個狀態
              IconButton(
                icon: Icon(Icons.skip_previous, size: 36 * scale, color: textColor),
                tooltip: AppLocalizations.of(context)!.previousState,
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
                tooltip: _isRunning ? AppLocalizations.of(context)!.pause : AppLocalizations.of(context)!.continueWorkout,
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
                tooltip: AppLocalizations.of(context)!.nextState,
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
                _currentPresetName ?? AppLocalizations.of(context)!.untitledActivity,
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
                                AppLocalizations.of(context)!.switchActivity,
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
                                  icon: Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 22),
                                  tooltip: AppLocalizations.of(context)!.deleteActivity,
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => Dialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 48),
                                              SizedBox(height: 18),
                                              Text(
                                                AppLocalizations.of(context)!.deleteActivity,
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.redAccent,
                                                  letterSpacing: 1.2,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                AppLocalizations.of(context)!.confirmDeleteActivity(preset.name),
                                                style: TextStyle(fontSize: 16, color: Colors.black87),
                                                textAlign: TextAlign.center,
                                              ),
                                              SizedBox(height: 28),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: OutlinedButton(
                                                      onPressed: () => Navigator.pop(context, false),
                                                      style: OutlinedButton.styleFrom(
                                                        foregroundColor: Colors.grey,
                                                        side: BorderSide(color: Colors.grey.shade300),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                                        padding: EdgeInsets.symmetric(vertical: 14),
                                                      ),
                                                      child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(fontSize: 16)),
                                                    ),
                                                  ),
                                                  SizedBox(width: 18),
                                                  Expanded(
                                                    child: ElevatedButton(
                                                      onPressed: () => Navigator.pop(context, true),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.redAccent,
                                                        foregroundColor: Colors.white,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                                        padding: EdgeInsets.symmetric(vertical: 14),
                                                      ),
                                                      child: Text(AppLocalizations.of(context)!.delete, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
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
                                      showAppSnackBar(context, AppLocalizations.of(context)!.activityDeleted(preset.name));
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
                            showAppSnackBar(context, AppLocalizations.of(context)!.activityLoaded(preset.name));
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
                                  AppLocalizations.of(context)!.createNewActivity,
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
                                    hintText: AppLocalizations.of(context)!.pleaseEnterActivityName,
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
                                        child: Text(AppLocalizations.of(context)!.cancel),
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
                                        child: Text(AppLocalizations.of(context)!.create, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                      showAppSnackBar(context, AppLocalizations.of(context)!.activityCreated(name));
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
                          AppLocalizations.of(context)!.createNewActivity,
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
            margin: EdgeInsets.symmetric(vertical: 6 * scale, horizontal: 16 * scale),
            padding: EdgeInsets.symmetric(vertical: 10 * scale, horizontal: 12 * scale),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer, color: Colors.orange.shade900, size: 20 * scale),
                SizedBox(width: 8 * scale),
                Text(AppLocalizations.of(context)!.prep, style: TextStyle(fontSize: 18 * scale, color: Colors.orange.shade900, fontWeight: FontWeight.bold)),
                SizedBox(width: 12 * scale),
                Text(
                  state.prepTime.toString(),
                  style: TextStyle(fontSize: 18 * scale, color: Colors.orange.shade900, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8 * scale),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.orange.shade900, size: 20 * scale),
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
            margin: EdgeInsets.symmetric(vertical: 6 * scale, horizontal: 16 * scale),
            padding: EdgeInsets.symmetric(vertical: 10 * scale, horizontal: 12 * scale),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center, color: Colors.white, size: 20 * scale),
                SizedBox(width: 8 * scale),
                Text(AppLocalizations.of(context)!.work, style: TextStyle(fontSize: 18 * scale, color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(width: 12 * scale),
                Text(
                  state.workTime.toString(),
                  style: TextStyle(fontSize: 18 * scale, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8 * scale),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.white, size: 20 * scale),
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
            margin: EdgeInsets.symmetric(vertical: 6 * scale, horizontal: 16 * scale),
            padding: EdgeInsets.symmetric(vertical: 10 * scale, horizontal: 12 * scale),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.self_improvement, color: Colors.white, size: 20 * scale),
                SizedBox(width: 8 * scale),
                Text(AppLocalizations.of(context)!.rest, style: TextStyle(fontSize: 18 * scale, color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(width: 12 * scale),
                Text(
                  state.restTime.toString(),
                  style: TextStyle(fontSize: 18 * scale, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8 * scale),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.white, size: 20 * scale),
                  onPressed: () => _showEditDialog('Rest', state.restTime, state.updateRestTime),
                ),
              ],
            ),
          ),
          // Cycles 卡片
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
            margin: EdgeInsets.symmetric(vertical: 6 * scale, horizontal: 16 * scale),
            padding: EdgeInsets.symmetric(vertical: 10 * scale, horizontal: 12 * scale),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.repeat, color: Colors.white, size: 20 * scale),
                SizedBox(width: 8 * scale),
                Text(AppLocalizations.of(context)!.cycles, style: TextStyle(fontSize: 18 * scale, color: Colors.white)),
                SizedBox(width: 12 * scale),
                Text(
                  state.cycles.toString(),
                  style: TextStyle(fontSize: 18 * scale, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8 * scale),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.white, size: 20 * scale),
                  onPressed: () {
                    _showEditDialog('Cycles', state.cycles, (v) => state.updateCycles(v));
                  },
                  tooltip: AppLocalizations.of(context)!.editCycles,
                ),
              ],
            ),
          ),
          // Sets 卡片
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.deepPurple.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16 * scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withAlpha((0.3 * 255).toInt()),
                  blurRadius: 8 * scale,
                  offset: Offset(0, 4 * scale),
                ),
              ],
            ),
            margin: EdgeInsets.symmetric(vertical: 6 * scale, horizontal: 16 * scale),
            padding: EdgeInsets.symmetric(vertical: 10 * scale, horizontal: 12 * scale),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.layers, color: Colors.white, size: 20 * scale),
                SizedBox(width: 8 * scale),
                Text(AppLocalizations.of(context)!.sets, style: TextStyle(fontSize: 18 * scale, color: Colors.white)),
                SizedBox(width: 12 * scale),
                Text(
                  state.sets.toString(),
                  style: TextStyle(fontSize: 18 * scale, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8 * scale),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.white, size: 20 * scale),
                  onPressed: () {
                    _showEditDialog('Sets', state.sets, (v) => state.updateSets(v));
                  },
                  tooltip: AppLocalizations.of(context)!.editSets,
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
    final bool showBanner = (_isBannerLoaded && _bannerAd != null) && (_selectedIndex == 0);
    final double bannerHeight = showBanner ? _bannerAd!.size.height.toDouble() : 0.0;
    final double availableHeight = (screenHeight - bannerHeight).clamp(200.0, screenHeight);
    if (availableHeight < 1000) {
      scale = (availableHeight / 1000).clamp(0.6, 1.0);
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
                        AppLocalizations.of(context)!.start,
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
        title: Text(
          _selectedIndex == 0
              ? AppLocalizations.of(context)!.tabataTimer
              : AppLocalizations.of(context)!.exerciseHistory,
          style: TextStyle(fontSize: 22 * scale),
        ),
        leading: !showSetup
            ? IconButton(
                icon: Icon(Icons.close, size: 22 * scale),
                tooltip: AppLocalizations.of(context)!.stop,
                onPressed: () => _stopTimer(userInitiated: true),
              )
            : null,
        actions: [
          if (_selectedIndex == 1)
            IconButton(
              icon: Icon(Icons.pie_chart, size: 22 * scale),
              tooltip: AppLocalizations.of(context)!.viewExerciseRatio,
              onPressed: () async {
                int dialogSelectedRange = 5;
                final allRecords = await ExerciseDatabase.instance.fetchAllRecords();
                showDialog(
                  context: context,
                  builder: (context) => StatefulBuilder(
                    builder: (context, setState) {
                      final now = DateTime.now();
                      final start = now.subtract(Duration(days: dialogSelectedRange - 1));
                      final Set<String> exerciseDayStrs = allRecords.map((r) => r.dateTime.substring(0, 10)).toSet();
                      int exerciseCount = 0;
                      for (int i = 0; i < dialogSelectedRange; i++) {
                        final d = start.add(Duration(days: i));
                        final dStr = "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
                        if (exerciseDayStrs.contains(dStr)) exerciseCount++;
                      }
                      int restCount = dialogSelectedRange - exerciseCount;
                      final dataMap = {
                        AppLocalizations.of(context)!.exercised: exerciseCount.toDouble(),
                        AppLocalizations.of(context)!.noExercise: restCount.toDouble(),
                      };
                      final percent = (exerciseCount / dialogSelectedRange * 100).toStringAsFixed(1);
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
                                  Text(AppLocalizations.of(context)!.viewExerciseRatio, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                                  Text(AppLocalizations.of(context)!.range, style: TextStyle(fontSize: 15)),
                                  DropdownButton<int>(
                                    value: dialogSelectedRange,
                                    items: [5, 7, 14, 30, 90, 180, 360].map((v) => DropdownMenuItem(value: v, child: Text("$v ${AppLocalizations.of(context)!.days}"))).toList(),
                                    onChanged: (v) {
                                      if (v != null) setState(() => dialogSelectedRange = v);
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(AppLocalizations.of(context)!.daysExercised(exerciseCount), style: TextStyle(fontSize: 15)),
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
                              Text(AppLocalizations.of(context)!.exerciseRatio(exerciseCount, percent, dialogSelectedRange), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(AppLocalizations.of(context)!.close),
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
          IconButton(
            icon: Icon(Icons.settings, size: 22 * scale),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    onLocaleChanged: widget.onLocaleChanged,
                    onThemeModeChanged: widget.onThemeModeChanged,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          if (showBanner)
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
    try {
      _bgmPlayer = AudioPlayer(); // 每次都 new 新的
      String asset = phase == 'workout' ? 'sounds/mystery.wav' : 'sounds/rest.wav';
      await _bgmPlayer!.setSource(AssetSource(asset));
      await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer!.resume();
    } catch (e) {
      debugPrint('播放 BGM 失敗: $e');
      _bgmPlayer = null;
    }
  }

  Future<void> _stopBgm() async {
    if (_bgmPlayer != null) {
      try {
        await _bgmPlayer!.stop();
        await _bgmPlayer!.dispose();
      } catch (e) {
        debugPrint('Error stopping BGM: ' + e.toString());
      }
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

// 將 showAppSnackBar 移到全域（class 外部）
void showAppSnackBar(BuildContext context, String message, {IconData? icon, Color? color, int milliseconds = 1500}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 22),
            SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: color ?? Colors.blueAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      duration: Duration(milliseconds: milliseconds),
      elevation: 8,
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    ),
  );
}