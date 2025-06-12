import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ExerciseRecord {
  final int? id;
  final String? workoutName;
  final int workoutTime;
  final int restTime;
  final int cycles;
  final int sets;
  final int durationSeconds;
  final String dateTime;

  ExerciseRecord({
    this.id,
    this.workoutName,
    required this.workoutTime,
    required this.restTime,
    required this.cycles,
    required this.sets,
    required this.durationSeconds,
    required this.dateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutName': workoutName,
      'workoutTime': workoutTime,
      'restTime': restTime,
      'cycles': cycles,
      'sets': sets,
      'durationSeconds': durationSeconds,
      'dateTime': dateTime,
    };
  }

  factory ExerciseRecord.fromMap(Map<String, dynamic> map) {
    return ExerciseRecord(
      id: map['id'],
      workoutName: map['workoutName'],
      workoutTime: map['workoutTime'],
      restTime: map['restTime'],
      cycles: map['cycles'],
      sets: map['sets'],
      durationSeconds: map['durationSeconds'],
      dateTime: map['dateTime'],
    );
  }
}

class WorkoutPreset {
  final int? id;
  final String name;
  final int prepTime;
  final int workTime;
  final int restTime;
  final int cycles;
  final int sets;

  WorkoutPreset({
    this.id,
    required this.name,
    required this.prepTime,
    required this.workTime,
    required this.restTime,
    required this.cycles,
    required this.sets,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'prepTime': prepTime,
      'workTime': workTime,
      'restTime': restTime,
      'cycles': cycles,
      'sets': sets,
    };
  }

  factory WorkoutPreset.fromMap(Map<String, dynamic> map) {
    return WorkoutPreset(
      id: map['id'],
      name: map['name'],
      prepTime: map['prepTime'],
      workTime: map['workTime'],
      restTime: map['restTime'],
      cycles: map['cycles'],
      sets: map['sets'],
    );
  }
}

class ExerciseDatabase {
  static final ExerciseDatabase instance = ExerciseDatabase._init();
  static Database? _database;

  ExerciseDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('exercise_records.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE exercise_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workoutName TEXT,
        workoutTime INTEGER,
        restTime INTEGER,
        cycles INTEGER,
        sets INTEGER,
        durationSeconds INTEGER,
        dateTime TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE workout_presets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE,
        prepTime INTEGER,
        workTime INTEGER,
        restTime INTEGER,
        cycles INTEGER,
        sets INTEGER
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE exercise_records ADD COLUMN workoutName TEXT;');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS workout_presets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT UNIQUE,
          prepTime INTEGER,
          workTime INTEGER,
          restTime INTEGER,
          cycles INTEGER,
          sets INTEGER
        )
      ''');
    }
  }

  Future<int> insertRecord(ExerciseRecord record) async {
    final db = await instance.database;
    return await db.insert('exercise_records', record.toMap());
  }

  Future<List<ExerciseRecord>> fetchAllRecords() async {
    final db = await instance.database;
    final maps = await db.query('exercise_records', orderBy: 'dateTime DESC');
    return maps.map((e) => ExerciseRecord.fromMap(e)).toList();
  }

  Future<int> insertPreset(WorkoutPreset preset) async {
    final db = await instance.database;
    return await db.insert('workout_presets', preset.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<WorkoutPreset>> fetchAllPresets() async {
    final db = await instance.database;
    final maps = await db.query('workout_presets', orderBy: 'name ASC');
    return maps.map((e) => WorkoutPreset.fromMap(e)).toList();
  }

  Future<WorkoutPreset?> fetchPresetByName(String name) async {
    final db = await instance.database;
    final maps = await db.query('workout_presets', where: 'name = ?', whereArgs: [name]);
    if (maps.isNotEmpty) {
      return WorkoutPreset.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deletePresetByName(String name) async {
    final db = await instance.database;
    return await db.delete('workout_presets', where: 'name = ?', whereArgs: [name]);
  }

  Future<int> deleteRecordsByIds(List<int> ids) async {
    final db = await instance.database;
    if (ids.isEmpty) return 0;
    final idList = ids.join(',');
    return await db.delete(
      'exercise_records',
      where: 'id IN ($idList)'
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
