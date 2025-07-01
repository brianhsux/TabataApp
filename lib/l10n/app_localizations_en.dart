// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Tabata App';

  @override
  String get settings => 'Settings';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get tabataTimer => 'Tabata Timer';

  @override
  String get start => 'Start';

  @override
  String get stop => 'Stop';

  @override
  String get prep => 'Prep';

  @override
  String get work => 'Work';

  @override
  String get rest => 'Rest';

  @override
  String get cycles => 'Cycles';

  @override
  String get sets => 'Sets';

  @override
  String cycle(Object current, Object total) {
    return 'Cycle: $current / $total';
  }

  @override
  String set(Object current, Object total) {
    return 'Set: $current / $total';
  }

  @override
  String get untitledActivity => 'Untitled Activity';

  @override
  String get createNewActivity => 'Create New Activity';

  @override
  String get pleaseEnterActivityName => 'Please enter activity name';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get editRecord => 'Edit Record';

  @override
  String get activityName => 'Activity Name';

  @override
  String get workSeconds => 'Work Seconds';

  @override
  String get restSeconds => 'Rest Seconds';

  @override
  String get dateTime => 'DateTime (yyyy-MM-ddTHH:mm)';

  @override
  String elapsed(Object time) {
    return 'Elapsed: $time';
  }

  @override
  String get done => 'Done';

  @override
  String get go => 'Go';

  @override
  String get confirmStopWorkout => 'Are you sure you want to stop the workout?';

  @override
  String get endWorkoutNoSave =>
      'This will end the workout and not save the record.';

  @override
  String setPhaseTime(Object phase) {
    return 'Set $phase time';
  }

  @override
  String get pleaseEnterSeconds => 'Please enter seconds';

  @override
  String get bgm => 'Background Music (BGM)';

  @override
  String get bgmHint => 'When enabled, BGM will play during workout/rest';

  @override
  String get backupToDrive => 'Backup to Google Drive';

  @override
  String get restoreFromDrive => 'Restore from Google Drive';

  @override
  String get resetAllSettings => 'Reset All Settings';

  @override
  String get resetToDefault => 'Reset to default';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get notSignedInGoogle => 'Not signed in to Google';

  @override
  String get pleaseSignInGoogle => 'Please sign in to Google first';

  @override
  String get dbNotFound => 'Database file not found';

  @override
  String get backupSuccess => 'Backup successful!';

  @override
  String backupFailed(Object error) {
    return 'Backup failed: $error';
  }

  @override
  String get restoreSuccess => 'Restore successful!';

  @override
  String restoreFailed(Object error) {
    return 'Restore failed: $error';
  }

  @override
  String get selectBackupToRestore => 'Select backup to restore';

  @override
  String get deleteBackup => 'Delete backup';

  @override
  String deleteBackupConfirm(Object name) {
    return 'Are you sure you want to delete the backup \"$name\"?';
  }

  @override
  String backupDeleted(Object name) {
    return 'Backup $name deleted';
  }

  @override
  String deleteFailed(Object error) {
    return 'Delete failed: $error';
  }

  @override
  String get exerciseHistory => 'Exercise History';

  @override
  String get viewExerciseRatio => 'View Exercise Ratio';

  @override
  String get exercised => 'Exercised';

  @override
  String get noExercise => 'No Exercise';

  @override
  String get edit => 'Edit';
}
