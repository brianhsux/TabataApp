import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ExerciseRecord {
  final int? id;
  final int workoutTime;
  final int restTime;
  final int cycles;
  final int sets;
  final int durationSeconds;
  final String dateTime;

  ExerciseRecord({
    this.id,
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
      workoutTime: map['workoutTime'],
      restTime: map['restTime'],
      cycles: map['cycles'],
      sets: map['sets'],
      durationSeconds: map['durationSeconds'],
      dateTime: map['dateTime'],
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
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE exercise_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workoutTime INTEGER,
        restTime INTEGER,
        cycles INTEGER,
        sets INTEGER,
        durationSeconds INTEGER,
        dateTime TEXT
      )
    ''');
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
