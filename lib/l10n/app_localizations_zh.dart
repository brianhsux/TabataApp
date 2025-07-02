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
  String get dateTime => '日期時間 ';

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

  @override
  String get chooseBackup => '選擇要還原的備份';

  @override
  String get confirmRestore => '確認還原';

  @override
  String get deleteConfirmation => '刪除確認';

  @override
  String get confirmDeleteSelectedRecord => '確定要刪除選取的紀錄嗎？';

  @override
  String get range => '區間：';

  @override
  String get days => '天';

  @override
  String daysExercised(Object count) {
    return '（$count天有運動）';
  }

  @override
  String exerciseRatio(Object count, Object percent, Object range) {
    return '$range天內運動$count天，佔比$percent%';
  }

  @override
  String get close => '關閉';

  @override
  String get deleteSelected => '刪除選取';

  @override
  String loadFailed(Object error) {
    return '讀取失敗: $error';
  }

  @override
  String get noExerciseRecord => '尚無運動紀錄';

  @override
  String get noRecordThisDay => '這天沒有運動紀錄';

  @override
  String workoutTimeShort(Object seconds) {
    return 'W:${seconds}s';
  }

  @override
  String restTimeShort(Object seconds) {
    return 'R:${seconds}s';
  }

  @override
  String cyclesShort(Object count) {
    return 'C:$count';
  }

  @override
  String setsShort(Object count) {
    return 'S:$count';
  }

  @override
  String get totalWorkoutSeconds => '運動總秒數';

  @override
  String get save => '儲存';

  @override
  String get recordUpdated => '已更新紀錄';

  @override
  String get languageEnglish => '英文';

  @override
  String get languageChinese => '繁體中文';

  @override
  String get languageChineseSimplified => '簡體中文';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get title => 'Tabata 计时器';

  @override
  String get settings => '设置';

  @override
  String get changeLanguage => '切换语言';

  @override
  String get tabataTimer => 'Tabata 计时器';

  @override
  String get start => '开始';

  @override
  String get stop => '停止';

  @override
  String get prep => '预备';

  @override
  String get work => '运动';

  @override
  String get rest => '休息';

  @override
  String get cycles => '循环';

  @override
  String get sets => '组数';

  @override
  String cycle(Object current, Object total) {
    return '循环：$current / $total';
  }

  @override
  String set(Object current, Object total) {
    return '组数：$current / $total';
  }

  @override
  String get untitledActivity => '未命名活动';

  @override
  String get createNewActivity => '建立新活动';

  @override
  String get pleaseEnterActivityName => '请输入活动名称';

  @override
  String get cancel => '取消';

  @override
  String get create => '建立';

  @override
  String get editRecord => '编辑记录';

  @override
  String get activityName => '活动名称';

  @override
  String get workSeconds => '运动秒数';

  @override
  String get restSeconds => '休息秒数';

  @override
  String get dateTime => '日期时间 ';

  @override
  String elapsed(Object time) {
    return '本次运动已进行：$time';
  }

  @override
  String get done => '完成';

  @override
  String get go => '开始';

  @override
  String get confirmStopWorkout => '确定要停止运动吗？';

  @override
  String get endWorkoutNoSave => '这将结束本次运动，且不会保存记录。';

  @override
  String setPhaseTime(Object phase) {
    return '设定$phase时间';
  }

  @override
  String get pleaseEnterSeconds => '请输入秒数';

  @override
  String get bgm => '背景音乐 (BGM)';

  @override
  String get bgmHint => '启用时，workout/rest 阶段会播放背景音乐';

  @override
  String get backupToDrive => '备份到 Google Drive';

  @override
  String get restoreFromDrive => '从 Google Drive 还原';

  @override
  String get resetAllSettings => '重设所有设置';

  @override
  String get resetToDefault => '已重设为默认值';

  @override
  String get signIn => '登录';

  @override
  String get signOut => '登出';

  @override
  String get notSignedInGoogle => '尚未登录 Google';

  @override
  String get pleaseSignInGoogle => '请先登录 Google';

  @override
  String get dbNotFound => '找不到数据库文件';

  @override
  String get backupSuccess => '备份成功！';

  @override
  String backupFailed(Object error) {
    return '备份失败: $error';
  }

  @override
  String get restoreSuccess => '还原成功！';

  @override
  String restoreFailed(Object error) {
    return '还原失败: $error';
  }

  @override
  String get selectBackupToRestore => '选择要还原的备份';

  @override
  String get deleteBackup => '删除备份';

  @override
  String deleteBackupConfirm(Object name) {
    return '确定要删除“$name”这个备份文件吗？';
  }

  @override
  String backupDeleted(Object name) {
    return '已删除备份 $name';
  }

  @override
  String deleteFailed(Object error) {
    return '删除失败: $error';
  }

  @override
  String get exerciseHistory => '运动历史记录';

  @override
  String get viewExerciseRatio => '查看运动占比';

  @override
  String get exercised => '有运动';

  @override
  String get noExercise => '没运动';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get workoutResultReport => '运动结果报告';

  @override
  String get workoutTime => '运动时间';

  @override
  String get workoutSeconds => '运动秒数';

  @override
  String get confirm => '确认';

  @override
  String get previousState => '上一个状态';

  @override
  String get pause => '暂停';

  @override
  String get continueWorkout => '继续';

  @override
  String get nextState => '下一个状态';

  @override
  String get switchActivity => '切换活动';

  @override
  String get deleteActivity => '删除活动';

  @override
  String confirmDeleteActivity(Object activity) {
    return '确定要删除“$activity”这个活动吗？';
  }

  @override
  String activityDeleted(Object activity) {
    return '已删除活动 $activity';
  }

  @override
  String activityLoaded(Object activity) {
    return '已载入活动 $activity';
  }

  @override
  String activityCreated(Object activity) {
    return '已建立活动 $activity';
  }

  @override
  String get editCycles => '编辑循环';

  @override
  String get editSets => '编辑组数';

  @override
  String get chooseBackup => '选择要还原的备份';

  @override
  String get confirmRestore => '确认还原';

  @override
  String get deleteConfirmation => '删除确认';

  @override
  String get confirmDeleteSelectedRecord => '确定要删除选取的记录吗？';

  @override
  String get range => '区间：';

  @override
  String get days => '天';

  @override
  String daysExercised(Object count) {
    return '（$count天有运动）';
  }

  @override
  String exerciseRatio(Object count, Object percent, Object range) {
    return '$range天内运动$count天，占比$percent%';
  }

  @override
  String get close => '关闭';

  @override
  String get deleteSelected => '删除选取';

  @override
  String loadFailed(Object error) {
    return '读取失败: $error';
  }

  @override
  String get noExerciseRecord => '尚无运动记录';

  @override
  String get noRecordThisDay => '这天没有运动记录';

  @override
  String workoutTimeShort(Object seconds) {
    return 'W:${seconds}s';
  }

  @override
  String restTimeShort(Object seconds) {
    return 'R:${seconds}s';
  }

  @override
  String cyclesShort(Object count) {
    return 'C:$count';
  }

  @override
  String setsShort(Object count) {
    return 'S:$count';
  }

  @override
  String get totalWorkoutSeconds => '运动总秒数';

  @override
  String get save => '保存';

  @override
  String get recordUpdated => '已更新记录';

  @override
  String get languageEnglish => '英文';

  @override
  String get languageChinese => '繁體中文';

  @override
  String get languageChineseSimplified => '简体中文';
}
