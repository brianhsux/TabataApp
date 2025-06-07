import 'package:flutter/material.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => TabataState(),
      child: TabataApp(),
    ),
  );
}

class TabataApp extends StatelessWidget {
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
  int prepTime = 10; // Preparation time (seconds) - explicitly set to 10
  int workTime = 45; // Exercise time (seconds)
  int restTime = 15; // Rest time (seconds)
  int cycles = 8; // Number of cycles
  int sets = 1; // Number of sets

  // BGM 開關狀態
  bool bgmEnabled = true;
  TabataState() {
    _loadBgmPreference();
  }
  Future<void> _loadBgmPreference() async {
    final prefs = await SharedPreferences.getInstance();
    bgmEnabled = prefs.getBool('bgmEnabled') ?? true;
    notifyListeners();
  }
  void setBgmEnabled(bool value) async {
    bgmEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bgmEnabled', value);
  }

  void updatePrepTime(int newTime) {
    prepTime = newTime;
    notifyListeners();
  }

  void updateWorkTime(int newTime) {
    workTime = newTime;
    notifyListeners();
  }

  void updateRestTime(int newTime) {
    restTime = newTime;
    notifyListeners();
  }

  void updateCycles(int newCycles) {
    cycles = newCycles;
    notifyListeners();
  }

  void updateSets(int newSets) {
    sets = newSets;
    notifyListeners();
  }
}

class TabataScreen extends StatefulWidget {
  @override
  _TabataScreenState createState() => _TabataScreenState();
}

class _TabataScreenState extends State<TabataScreen> {
  late StopWatchTimer _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioPlayer? _bgmPlayer;
  bool _isRunning = false;
  String _currentPhase = 'PREP';
  int _currentCycle = 1;
  int _currentSet = 1;
  int _remainingTime = 0;
  int _totalDurationMillis = 0;
  int? _lastBeepSecond; // 避免重複播放同一秒音效

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
        _totalDurationMillis = prepTimeMillis;
        
        // Properly set the initial timer value
        _timer.setPresetTime(mSec: prepTimeMillis);
        
        setState(() {
          _remainingTime = state.prepTime + 1;
          // Force update to ensure timer shows correct prep time
          print('Initial prep time: ${state.prepTime}');
        });
      }
    });
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
        print('Provider not available yet during timer initialization: $e');
      }
    }
  }

  @override
  void dispose() {
    _timer.dispose();
    _audioPlayer.dispose();
    _bgmPlayer?.dispose();
    super.dispose();
  }

  void _startTimer() {
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

  void _stopTimer() async {
    await _stopBgm(); // stop 時也停止背景音樂
    _timer.onStopTimer();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() async {
    await _stopBgm(); // reset 時也停止背景音樂
    _timer.onStopTimer();
    _timer.dispose();
    _initTimer();
    if (mounted) {
      final state = Provider.of<TabataState>(context, listen: false);
      int prepTimeMillis = (state.prepTime + 1) * 1000;
      _timer.setPresetTime(mSec: prepTimeMillis);
      setState(() {
        _isRunning = false;
        _currentPhase = 'PREP';
        _currentCycle = 1;
        _currentSet = 1;
        _remainingTime = state.prepTime + 1;
        _totalDurationMillis = prepTimeMillis;
      });
    }
  }

  void _handlePhaseTransition() async {
    final state = Provider.of<TabataState>(context, listen: false);
    print('Phase transition from: $_currentPhase');
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
          _stopTimer();
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
    // Store the current value from text field to ensure it's captured before dialog closes
    TextEditingController controller = TextEditingController(text: currentTime.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $phase Time (seconds)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            // newTime is updated via controller in actions
          },
          decoration: InputDecoration(
            hintText: currentTime.toString(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              newTime = int.tryParse(controller.text) ?? currentTime;
              if (newTime > 0) { // Optional: ensure time is positive
                onUpdate(newTime);
              }
              Navigator.pop(context);
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressView(TabataState state) {
    LinearGradient gradient;
    Color textColor;
    String phaseText;
    IconData iconData;
    // Make sure the displayed time is correct based on the current phase
    int displayTime = _remainingTime;
    String displayText = '';
    if (_currentPhase == 'PREP' || _currentPhase == 'REST') {
      if (_remainingTime == 0) {
        displayText = 'Go';
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
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      margin: EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
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
            // Cycle and Set on separate lines
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.repeat, color: textColor),
                SizedBox(width: 8),
                Text(
                  'Cycle:  $_currentCycle / ${state.cycles}',
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
                  'Set:  $_currentSet / ${state.sets}',
                  style: TextStyle(fontSize: 24, color: textColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupView(TabataState state) {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Preparation block
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.yellow.shade200, Colors.orange.shade200],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, color: Colors.orange.shade900),
                  SizedBox(width: 10),
                  Text('Prep', style: TextStyle(fontSize: 24, color: Colors.orange.shade900, fontWeight: FontWeight.bold)),
                  SizedBox(width: 10),
                  Text(
                    state.prepTime.toString(),
                    style: TextStyle(fontSize: 24, color: Colors.orange.shade900, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 10),
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
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Work', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(width: 10),
                  Text(
                    state.workTime.toString(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 10),
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
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.self_improvement, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Rest', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(width: 10),
                  Text(
                    state.restTime.toString(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 10),
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
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              margin: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cycles block
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.repeat, color: Colors.white),
                        SizedBox(height: 10),
                        Text('Cycles', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
                        Text(
                          state.cycles.toString(),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, color: Colors.white),
                              onPressed: () {
                                if (state.cycles > 1) state.updateCycles(state.cycles - 1);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.add, color: Colors.white),
                              onPressed: () => state.updateCycles(state.cycles + 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Sets block
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.layers, color: Colors.white),
                        SizedBox(height: 10),
                        Text('Sets', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
                        Text(
                          state.sets.toString(),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, color: Colors.white),
                              onPressed: () {
                                if (state.sets > 1) state.updateSets(state.sets - 1);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.add, color: Colors.white),
                              onPressed: () => state.updateSets(state.sets + 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TabataState>();
    // Ensure _remainingTime is initialized correctly on phase or settings changes
    if (!_isRunning && _currentPhase == 'PREP') {
      if (_remainingTime != state.prepTime) {
        _remainingTime = state.prepTime;
      }
    } else if (!_isRunning && _currentPhase == 'WORK') {
      if (_remainingTime != state.workTime) {
        _remainingTime = state.workTime;
      }
    } else if (!_isRunning && _currentPhase == 'REST') {
      if (_remainingTime != state.restTime) {
        _remainingTime = state.restTime;
      }
    }


    return Scaffold(
      appBar: AppBar(
        title: Text('Tabata Timer'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
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
        children: [
          Expanded(
            child: _isRunning ? _buildProgressView(state) : _buildSetupView(state),
          ),
          // Start/Stop/Reset buttons
          Padding(
            padding: const EdgeInsets.all(16.0), // Increased padding
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Better spacing for buttons
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                  onPressed: _isRunning ? _stopTimer : _startTimer,
                  child: Text(_isRunning ? 'Stop' : 'Start', style: TextStyle(fontSize: 18)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                  onPressed: _resetTimer,
                  child: Text('Reset', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
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
}