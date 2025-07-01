// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get title => 'Tabata 計時器';

  @override
  String get settings => '設定';

  @override
  String get changeLanguage => '切換語言';

  @override
  String get tabataTimer => 'Tabata 計時器';

  @override
  String get start => '開始';

  @override
  String get stop => '停止';

  @override
  String get prep => '預備';

  @override
  String get work => '運動';

  @override
  String get rest => '休息';

  @override
  String get cycles => '循環';

  @override
  String get sets => '組數';

  @override
  String cycle(Object current, Object total) {
    return '循環：$current / $total';
  }

  @override
  String set(Object current, Object total) {
    return '組數：$current / $total';
  }

  @override
  String get untitledActivity => '未命名活動';

  @override
  String get createNewActivity => '建立新活動';

  @override
  String get pleaseEnterActivityName => '請輸入活動名稱';

  @override
  String get cancel => '取消';

  @override
  String get create => '建立';

  @override
  String get editRecord => '編輯紀錄';

  @override
  String get activityName => '活動名稱';

  @override
  String get workSeconds => '運動秒數';

  @override
  String get restSeconds => '休息秒數';

  @override
  String get dateTime => '日期時間 (yyyy-MM-ddTHH:mm)';

  @override
  String elapsed(Object time) {
    return '本次運動已進行：$time';
  }

  @override
  String get done => '完成';

  @override
  String get go => '開始';

  @override
  String get confirmStopWorkout => '確定要停止運動嗎？';

  @override
  String get endWorkoutNoSave => '這將結束本次運動，且不會儲存紀錄。';

  @override
  String setPhaseTime(Object phase) {
    return '設定$phase時間';
  }

  @override
  String get pleaseEnterSeconds => '請輸入秒數';

  @override
  String get bgm => '背景音樂 (BGM)';

  @override
  String get bgmHint => '啟用時，workout/rest 階段會播放背景音樂';

  @override
  String get backupToDrive => '備份到 Google Drive';

  @override
  String get restoreFromDrive => '從 Google Drive 還原';

  @override
  String get resetAllSettings => '重設所有設定';

  @override
  String get resetToDefault => '已重設為預設值';

  @override
  String get signIn => '登入';

  @override
  String get signOut => '登出';

  @override
  String get notSignedInGoogle => '尚未登入 Google';

  @override
  String get pleaseSignInGoogle => '請先登入 Google';

  @override
  String get dbNotFound => '找不到資料庫檔案';

  @override
  String get backupSuccess => '備份成功！';

  @override
  String backupFailed(Object error) {
    return '備份失敗: $error';
  }

  @override
  String get restoreSuccess => '還原成功！';

  @override
  String restoreFailed(Object error) {
    return '還原失敗: $error';
  }

  @override
  String get selectBackupToRestore => '選擇要還原的備份';

  @override
  String get deleteBackup => '刪除備份';

  @override
  String deleteBackupConfirm(Object name) {
    return '確定要刪除「$name」這個備份檔案嗎？';
  }

  @override
  String backupDeleted(Object name) {
    return '已刪除備份 $name';
  }

  @override
  String deleteFailed(Object error) {
    return '刪除失敗: $error';
  }

  @override
  String get exerciseHistory => '運動歷史紀錄';

  @override
  String get viewExerciseRatio => '查看運動佔比';

  @override
  String get exercised => '有運動';

  @override
  String get noExercise => '沒運動';

  @override
  String get edit => '編輯';

  @override
  String get delete => '刪除';

  @override
  String get workoutResultReport => '運動結果報告';

  @override
  String get workoutTime => '運動時間';

  @override
  String get workoutSeconds => '運動秒數';

  @override
  String get confirm => '確認';

  @override
  String get previousState => '上一個狀態';

  @override
  String get pause => '暫停';

  @override
  String get continueWorkout => '繼續';

  @override
  String get nextState => '下一個狀態';

  @override
  String get switchActivity => '切換活動';

  @override
  String get deleteActivity => '刪除活動';

  @override
  String confirmDeleteActivity(Object activity) {
    return '確定要刪除「$activity」這個活動嗎？';
  }

  @override
  String activityDeleted(Object activity) {
    return '已刪除活動 $activity';
  }

  @override
  String activityLoaded(Object activity) {
    return '已載入活動 $activity';
  }

  @override
  String activityCreated(Object activity) {
    return '已建立活動 $activity';
  }

  @override
  String get editCycles => '編輯循環';

  @override
  String get editSets => '編輯組數';
}
