import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Tabata App'**
  String get title;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @tabataTimer.
  ///
  /// In en, this message translates to:
  /// **'Tabata Timer'**
  String get tabataTimer;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @prep.
  ///
  /// In en, this message translates to:
  /// **'Prep'**
  String get prep;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @rest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get rest;

  /// No description provided for @cycles.
  ///
  /// In en, this message translates to:
  /// **'Cycles'**
  String get cycles;

  /// No description provided for @sets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get sets;

  /// No description provided for @cycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle: {current} / {total}'**
  String cycle(Object current, Object total);

  /// No description provided for @set.
  ///
  /// In en, this message translates to:
  /// **'Set: {current} / {total}'**
  String set(Object current, Object total);

  /// No description provided for @untitledActivity.
  ///
  /// In en, this message translates to:
  /// **'Untitled Activity'**
  String get untitledActivity;

  /// No description provided for @createNewActivity.
  ///
  /// In en, this message translates to:
  /// **'New Activity'**
  String get createNewActivity;

  /// No description provided for @pleaseEnterActivityName.
  ///
  /// In en, this message translates to:
  /// **'Please enter activity name'**
  String get pleaseEnterActivityName;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @editRecord.
  ///
  /// In en, this message translates to:
  /// **'Edit Record'**
  String get editRecord;

  /// No description provided for @activityName.
  ///
  /// In en, this message translates to:
  /// **'Activity Name'**
  String get activityName;

  /// No description provided for @workSeconds.
  ///
  /// In en, this message translates to:
  /// **'Work Seconds'**
  String get workSeconds;

  /// No description provided for @restSeconds.
  ///
  /// In en, this message translates to:
  /// **'Rest Seconds'**
  String get restSeconds;

  /// No description provided for @dateTime.
  ///
  /// In en, this message translates to:
  /// **'DateTime '**
  String get dateTime;

  /// No description provided for @elapsed.
  ///
  /// In en, this message translates to:
  /// **'Elapsed: {time}'**
  String elapsed(Object time);

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @go.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get go;

  /// No description provided for @confirmStopWorkout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to stop the workout?'**
  String get confirmStopWorkout;

  /// No description provided for @endWorkoutNoSave.
  ///
  /// In en, this message translates to:
  /// **'This will end the workout and not save the record.'**
  String get endWorkoutNoSave;

  /// No description provided for @setPhaseTime.
  ///
  /// In en, this message translates to:
  /// **'Set {phase} time'**
  String setPhaseTime(Object phase);

  /// No description provided for @pleaseEnterSeconds.
  ///
  /// In en, this message translates to:
  /// **'Please enter seconds'**
  String get pleaseEnterSeconds;

  /// No description provided for @bgm.
  ///
  /// In en, this message translates to:
  /// **'Background Music (BGM)'**
  String get bgm;

  /// No description provided for @bgmHint.
  ///
  /// In en, this message translates to:
  /// **'When enabled, BGM will play during workout/rest'**
  String get bgmHint;

  /// No description provided for @backupToDrive.
  ///
  /// In en, this message translates to:
  /// **'Backup to Google Drive'**
  String get backupToDrive;

  /// No description provided for @restoreFromDrive.
  ///
  /// In en, this message translates to:
  /// **'Restore from Google Drive'**
  String get restoreFromDrive;

  /// No description provided for @resetAllSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset All Settings'**
  String get resetAllSettings;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get resetToDefault;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @notSignedInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Not signed in to Google'**
  String get notSignedInGoogle;

  /// No description provided for @pleaseSignInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to Google first'**
  String get pleaseSignInGoogle;

  /// No description provided for @dbNotFound.
  ///
  /// In en, this message translates to:
  /// **'Database file not found'**
  String get dbNotFound;

  /// No description provided for @backupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup successful!'**
  String get backupSuccess;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {error}'**
  String backupFailed(Object error);

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restore successful!'**
  String get restoreSuccess;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String restoreFailed(Object error);

  /// No description provided for @selectBackupToRestore.
  ///
  /// In en, this message translates to:
  /// **'Select backup to restore'**
  String get selectBackupToRestore;

  /// No description provided for @deleteBackup.
  ///
  /// In en, this message translates to:
  /// **'Delete backup'**
  String get deleteBackup;

  /// No description provided for @deleteBackupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the backup \"{name}\"?'**
  String deleteBackupConfirm(Object name);

  /// No description provided for @backupDeleted.
  ///
  /// In en, this message translates to:
  /// **'Backup {name} deleted'**
  String backupDeleted(Object name);

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String deleteFailed(Object error);

  /// No description provided for @exerciseHistory.
  ///
  /// In en, this message translates to:
  /// **'Exercise History'**
  String get exerciseHistory;

  /// No description provided for @viewExerciseRatio.
  ///
  /// In en, this message translates to:
  /// **'View Exercise Ratio'**
  String get viewExerciseRatio;

  /// No description provided for @exercised.
  ///
  /// In en, this message translates to:
  /// **'Exercised'**
  String get exercised;

  /// No description provided for @noExercise.
  ///
  /// In en, this message translates to:
  /// **'No Exercise'**
  String get noExercise;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @workoutResultReport.
  ///
  /// In en, this message translates to:
  /// **'Workout Result Report'**
  String get workoutResultReport;

  /// No description provided for @workoutTime.
  ///
  /// In en, this message translates to:
  /// **'Workout Time'**
  String get workoutTime;

  /// No description provided for @workoutSeconds.
  ///
  /// In en, this message translates to:
  /// **'Workout Seconds'**
  String get workoutSeconds;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @previousState.
  ///
  /// In en, this message translates to:
  /// **'Previous State'**
  String get previousState;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @continueWorkout.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueWorkout;

  /// No description provided for @nextState.
  ///
  /// In en, this message translates to:
  /// **'Next State'**
  String get nextState;

  /// No description provided for @switchActivity.
  ///
  /// In en, this message translates to:
  /// **'Switch Activity'**
  String get switchActivity;

  /// No description provided for @deleteActivity.
  ///
  /// In en, this message translates to:
  /// **'Delete Activity'**
  String get deleteActivity;

  /// No description provided for @confirmDeleteActivity.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the activity \"{activity}\"?'**
  String confirmDeleteActivity(Object activity);

  /// No description provided for @activityDeleted.
  ///
  /// In en, this message translates to:
  /// **'Activity {activity} deleted'**
  String activityDeleted(Object activity);

  /// No description provided for @activityLoaded.
  ///
  /// In en, this message translates to:
  /// **'Activity {activity} loaded'**
  String activityLoaded(Object activity);

  /// No description provided for @activityCreated.
  ///
  /// In en, this message translates to:
  /// **'Activity {activity} created'**
  String activityCreated(Object activity);

  /// No description provided for @editCycles.
  ///
  /// In en, this message translates to:
  /// **'Edit Cycles'**
  String get editCycles;

  /// No description provided for @editSets.
  ///
  /// In en, this message translates to:
  /// **'Edit Sets'**
  String get editSets;

  /// No description provided for @chooseBackup.
  ///
  /// In en, this message translates to:
  /// **'Select backup to restore'**
  String get chooseBackup;

  /// No description provided for @confirmRestore.
  ///
  /// In en, this message translates to:
  /// **'Confirm Restore'**
  String get confirmRestore;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
