// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Simplified Chinese (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizations {
  AppLocalizationsZhHans([String locale = 'zh_Hans']) : super(locale);

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
  String get dateTime => '日期时间 (yyyy-MM-ddTHH:mm)';

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
    return '确定要删除"$name"这个备份文件吗？';
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
    return '确定要删除"$activity"这个活动吗？';
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