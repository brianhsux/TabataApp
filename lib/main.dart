import 'package:flutter/material.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';

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
        primarySwatch: Colors.blue,
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 24, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 18, color: Colors.white),
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
  bool _isRunning = false;
  String _currentPhase = 'PREP';
  int _currentCycle = 1;
  int _currentSet = 1;
  int _remainingTime = 0;
  int _totalDurationMillis = 0;

  @override
  void initState() {
    super.initState();
    _initTimer();

    // Initialize _remainingTime with the prepTime from TabataState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final state = context.read<TabataState>();
        // Make sure we're using the correct prepTime value (10 seconds)
        int prepTimeMillis = state.prepTime * 1000;
        _totalDurationMillis = prepTimeMillis;
        
        // Properly set the initial timer value
        _timer.setPresetTime(mSec: prepTimeMillis);
        
        setState(() {
          _remainingTime = state.prepTime;
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
              // Debug print to track timer changes

              print('Timer update: $_remainingTime seconds remaining');
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
    super.dispose();
  }

  void _startTimer() {
    // Only set preset time if timer is not already running
    if (!_isRunning) {
      final state = Provider.of<TabataState>(context, listen: false);
      int presetMillis;
      
      // Ensure timer is correctly initialized
      _timer.onStopTimer();
      
      // Fix for prep time counting from 20 instead of 10
      if (_currentPhase == 'PREP') {
        // Debug print to confirm prep time
        print("Starting PREP phase with ${state.prepTime} seconds");
        
        // Explicitly set the correct prep time in milliseconds
        presetMillis = state.prepTime * 1000;
        print('Setting preset time to PREP phase: ${presetMillis}');

        _remainingTime = state.prepTime;
      } else if (_currentPhase == 'WORK') {
        presetMillis = state.workTime * 1000;
        _remainingTime = state.workTime;
      } else { // REST
        presetMillis = state.restTime * 1000;
        _remainingTime = state.restTime;
      }
      
      // First reset the timer completely
      _timer.onResetTimer();
      // Then set the preset time - order matters here
      _timer.setPresetTime(mSec: presetMillis);
      
      // Make sure _remainingTime is correctly set (especially for PREP)
      setState(() {
        _remainingTime = _currentPhase == 'PREP' ? state.prepTime : 
                         _currentPhase == 'WORK' ? state.workTime : state.restTime;
      });
    }
    
    _timer.onStartTimer();
    
    setState(() {
      _isRunning = true;
    });
    _playSound();
  }

  void _stopTimer() {
    _timer.onStopTimer();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer.onStopTimer(); // Make sure to stop first
    
    // Clean up old timer first
    _timer.dispose();
    
    // Create a new timer instance to ensure it's properly initialized
    _initTimer();
    
    if (mounted) {
      final state = Provider.of<TabataState>(context, listen: false);
      // Ensure we're using the correct prep time (10 seconds)
      int prepTimeMillis = state.prepTime * 1000;
      
      // Debug logging to see what's happening
      print('Reset Timer - Using prep time: ${state.prepTime} seconds');
      
      _timer.setPresetTime(mSec: prepTimeMillis);
      
      setState(() {
        _isRunning = false;
        _currentPhase = 'PREP';
        _currentCycle = 1;
        _currentSet = 1;
        _remainingTime = state.prepTime;
        _totalDurationMillis = prepTimeMillis;
        // Print to confirm setState applied correctly
        print('Reset Timer - _remainingTime set to: $_remainingTime seconds');
      });
    }
  }

  void _handlePhaseTransition() async {
    final state = Provider.of<TabataState>(context, listen: false);
    // Debug log to show transition
    print('Phase transition from: $_currentPhase');
    
    // Remove the _remainingTime <= 0 check since onEnded already confirms the timer is done
    if (_isRunning) {
      _playSound();
      if (_currentPhase == 'PREP') {
        print('Transitioning from PREP to WORK');
        // First stop the timer
        _timer.onStopTimer();
        
        setState(() {
          _currentPhase = 'WORK';
          _remainingTime = state.workTime;
          print('Setting remaining time to WORK phase: ${state.workTime}'); 
        });
        
        // Order matters: reset first, then set preset time
        _timer.onResetTimer();
        _timer.setPresetTime(mSec: state.workTime * 1000);
        _timer.onStartTimer();
        
        print('Started WORK phase with ${state.workTime} seconds');
      } else if (_currentPhase == 'WORK') {
        print('Transitioning from WORK to REST');
        // First stop the timer
        _timer.onStopTimer();
        
        setState(() {
          _currentPhase = 'REST';
          _remainingTime = state.restTime;
          print('Setting remaining time to REST phase: ${state.restTime}');
        });
        
        // Order matters: reset first, then set preset time
        _timer.onResetTimer();
        _timer.setPresetTime(mSec: state.restTime * 1000);
        _timer.onStartTimer();
        
        print('Started REST phase with ${state.restTime} seconds');
      } else if (_currentPhase == 'REST') {
        // Check if we have more cycles in current set
        if (_currentCycle < state.cycles) {
          setState(() {
            _currentCycle++;
            _currentPhase = 'WORK';
            _remainingTime = state.workTime;
            print('Setting remaining time to WORK phase: ${state.workTime}');
          });
          _timer.setPresetTime(mSec: state.workTime * 1000);
          _timer.onResetTimer();
          _timer.onStartTimer();
        } 
        // Check if we have more sets after completing all cycles
        else if (_currentSet < state.sets) {
          setState(() {
            _currentSet++;
            _currentCycle = 1;
            _currentPhase = 'PREP';
            _remainingTime = state.prepTime;
            print('Setting remaining time to PREP phase: ${state.prepTime}');
          });
          _timer.setPresetTime(mSec: state.prepTime * 1000);
          _timer.onResetTimer();
          _timer.onStartTimer();
        } 
        // All cycles and sets completed
        else {
          _stopTimer();
          _resetTimer();
        }
      }
    }
  }

  void _playSound() async {
    await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
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
    Color backgroundColor;
    Color textColor;
    String phaseText;
    
    // Make sure the displayed time is correct based on the current phase
    int displayTime = _remainingTime;
    if (!_isRunning) {
      displayTime = _currentPhase == 'PREP' ? state.prepTime : 
                   _currentPhase == 'WORK' ? state.workTime : state.restTime;
    }

    switch (_currentPhase) {
      case 'PREP':
        backgroundColor = Colors.yellow;
        textColor = Colors.black;
        phaseText = 'Prep';
        break;
      case 'WORK':
        backgroundColor = Colors.red;
        textColor = Colors.white;
        phaseText = 'Work';
        break;
      case 'REST':
        backgroundColor = Colors.green;
        textColor = Colors.white;
        phaseText = 'Rest';
        break;
      default:
        backgroundColor = Colors.grey; // Fallback
        textColor = Colors.black;
        phaseText = _currentPhase;
    }

    return Container(
      color: backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              phaseText,
              style: TextStyle(fontSize: 48, color: textColor, fontWeight: FontWeight.bold),
            ),
            Text(
              '$displayTime',
              style: TextStyle(fontSize: 120, fontWeight: FontWeight.bold, color: textColor),
            ),
            SizedBox(height: 20),
            Text(
              'Cycle: $_currentCycle / ${state.cycles}',
              style: TextStyle(fontSize: 24, color: textColor),
            ),
            Text(
              'Set: $_currentSet / ${state.sets}',
              style: TextStyle(fontSize: 24, color: textColor),
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
              color: Colors.yellow,
              padding: EdgeInsets.symmetric(vertical: 10), // Added padding for better spacing
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Prep', style: TextStyle(fontSize: 24, color: Colors.black)),
                  SizedBox(width: 10),
                  Text(
                    state.prepTime.toString(),
                    style: TextStyle(fontSize: 24, color: Colors.black),
                  ),
                  SizedBox(width: 10),
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.black),
                    onPressed: () => _showEditDialog('Prep', state.prepTime, state.updatePrepTime),
                  ),
                ],
              ),
            ),
            // Exercise block
            Container(
              color: Colors.red,
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_note, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Work', style: Theme.of(context).textTheme.bodyLarge),
                  SizedBox(width: 10),
                  Text(
                    state.workTime.toString(),
                    style: Theme.of(context).textTheme.bodyLarge,
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
              color: Colors.green,
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Rest', style: Theme.of(context).textTheme.bodyLarge),
                  SizedBox(width: 10),
                  Text(
                    state.restTime.toString(),
                    style: Theme.of(context).textTheme.bodyLarge,
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
              color: Colors.blue,
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cycles block
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_library, color: Colors.white),
                        SizedBox(height: 10),
                        Text('Cycles', style: Theme.of(context).textTheme.bodyMedium),
                        Text(
                          state.cycles.toString(),
                          style: Theme.of(context).textTheme.bodyLarge,
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
                        Icon(Icons.alarm, color: Colors.white),
                        SizedBox(height: 10),
                        Text('Sets', style: Theme.of(context).textTheme.bodyMedium),
                        Text(
                          state.sets.toString(),
                          style: Theme.of(context).textTheme.bodyLarge,
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
              // Placeholder for potential global settings, or remove if redundant
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
}