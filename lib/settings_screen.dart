import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart' as main;
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.onLocaleChanged, this.onThemeModeChanged});

  final Function(Locale)? onLocaleChanged;
  final Function(ThemeMode)? onThemeModeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  GoogleSignInAccount? _currentUser;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );
  bool _isLoading = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((account) {
      setState(() {
        _currentUser = account;
      });
    });
    _googleSignIn.signInSilently();
  }

  Future<void> _handleSignIn() async {
    // Step 1. Google Sign-In
    GoogleSignInAccount? googleUser;
    try {
      googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google sign-in cancelled by user');
        return;
      }
      debugPrint('Google sign-in success: ${googleUser.email}');
    } catch (error, stack) {
      debugPrint('Google sign-in error: ${error}');
      FirebaseCrashlytics.instance.recordError(error, stack, reason: 'Error during Google sign-in');
      if (context.mounted) {
        main.showAppSnackBar(context, 'Google 登入失敗: ' + error.toString(), icon: Icons.error, color: Colors.redAccent);
      }
      return; // Stop if Google sign-in failed
    }

    // Step 2. FirebaseAuth Sign-In
    UserCredential? userCredential;
    try {
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint('FirebaseAuth sign-in success: ${userCredential.user?.uid}');
    } catch (error, stack) {
      debugPrint('FirebaseAuth sign-in error: ${error}');
      FirebaseCrashlytics.instance.recordError(error, stack, reason: 'Error during FirebaseAuth sign-in');
      if (context.mounted) {
        main.showAppSnackBar(context, 'Firebase Auth 登入失敗: ' + error.toString(), icon: Icons.error, color: Colors.redAccent);
      }
      return; // Stop if FirebaseAuth sign-in failed
    }

    // Step 3. Firestore Write
    try {
      final firebaseUser = userCredential.user;
      if (firebaseUser != null && firebaseUser.email != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set({'email': firebaseUser.email}, SetOptions(merge: true));
        await FirebaseCrashlytics.instance.setUserIdentifier(firebaseUser.email!);
        debugPrint('Firestore write success for uid: ${firebaseUser.uid}');
      }
    } catch (error, stack) {
      debugPrint('Firestore write error: ${error}');
      FirebaseCrashlytics.instance.recordError(error, stack, reason: 'Error writing user email to Firestore');
      if (context.mounted) {
        main.showAppSnackBar(context, 'Firestore 寫入失敗: ' + error.toString(), icon: Icons.error, color: Colors.redAccent);
      }
    }
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.disconnect();
    await FirebaseCrashlytics.instance.setUserIdentifier('');
  }

  Future<void> backupToGoogleDrive() async {
    if (_currentUser == null) {
      main.showAppSnackBar(context, '請先登入 Google', icon: Icons.warning, color: Colors.orange);
      return;
    }
    setState(() {
      _isLoading = true;
      _progress = 0.0;
    });
    try {
      // 1. 取得本地 DB 檔案
      final dbDir = await getDatabasesPath();
      final dbFile = File('$dbDir/exercise_records.db');
      if (!await dbFile.exists()) {
        setState(() { _isLoading = false; _progress = 0.0; });
        main.showAppSnackBar(context, '找不到資料庫檔案', icon: Icons.error, color: Colors.redAccent);
        return;
      }
      // 2. 取得 Google OAuth token
      final authHeaders = await _currentUser!.authHeaders;
      final client = GoogleHttpClient(authHeaders);
      // 3. 上傳到 Google Drive（帶進度）
      final driveApi = drive.DriveApi(client);
      final fileToUpload = drive.File()
        ..name = 'tabata_backup_${DateTime.now().toIso8601String()}.db';
      final total = await dbFile.length();
      num uploaded = 0;
      final stream = dbFile.openRead().transform<List<int>>(
        StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            uploaded += data.length;
            setState(() { _progress = uploaded / total; });
            sink.add(data);
          },
        ),
      );
      await driveApi.files.create(
        fileToUpload,
        uploadMedia: drive.Media(stream, total),
      );
      setState(() { _isLoading = false; _progress = 0.0; });
      main.showAppSnackBar(context, '備份成功！', icon: Icons.check_circle, color: Colors.green);
    } catch (e) {
      setState(() { _isLoading = false; _progress = 0.0; });
      main.showAppSnackBar(context, '備份失敗: ' + e.toString(), icon: Icons.error, color: Colors.redAccent);
    }
  }

  Future<void> restoreFromGoogleDrive() async {
    if (_currentUser == null) {
      main.showAppSnackBar(context, '請先登入 Google', icon: Icons.warning, color: Colors.orange);
      return;
    }
    setState(() {
      _isLoading = true;
      _progress = 0.0;
    });
    try {
      final authHeaders = await _currentUser!.authHeaders;
      final client = GoogleHttpClient(authHeaders);
      final driveApi = drive.DriveApi(client);
      // 1. 取得所有備份檔案
      final fileList = await driveApi.files.list(q: "name contains 'tabata_backup_' and name contains '.db' and trashed = false", spaces: 'drive', $fields: 'files(id,name,modifiedTime)', orderBy: 'modifiedTime desc');
      final files = fileList.files ?? [];
      setState(() { _isLoading = false; });
      if (files.isEmpty) {
        main.showAppSnackBar(context, 'Google Drive 沒有備份檔案', icon: Icons.info, color: Colors.blueGrey);
        return;
      }
      // 2. 顯示選擇 Dialog
      final selected = await showDialog<drive.File>(
        context: context,
        builder: (context) {
          List<drive.File> fileList = List.from(files);
          return StatefulBuilder(
            builder: (context, setState) => Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 12,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cloud_download, color: Colors.blueAccent, size: 22),
                        SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.chooseBackup, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                      ],
                    ),
                    SizedBox(height: 16),
                    Container(
                      constraints: BoxConstraints(maxHeight: 320, minWidth: 260),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: fileList.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                        itemBuilder: (context, idx) {
                          final f = fileList[idx];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.pop(context, f),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(f.name ?? '', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                                          SizedBox(height: 3),
                                          Text(
                                            f.modifiedTime?.toLocal().toString().replaceFirst('T', ' ').substring(0, 19) ?? '',
                                            style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 22),
                                      tooltip: '刪除備份',
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => Dialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 48),
                                                  SizedBox(height: 18),
                                                  Text(
                                                    '刪除備份',
                                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent),
                                                  ),
                                                  SizedBox(height: 16),
                                                  Text(
                                                    '確定要刪除「${f.name}」這個備份檔案嗎？',
                                                    style: TextStyle(fontSize: 15, color: Colors.black87),
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
                                                          child: Text('取消', style: TextStyle(fontSize: 16)),
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
                                                          child: Text('刪除', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                          try {
                                            final authHeaders = await _currentUser!.authHeaders;
                                            final client = GoogleHttpClient(authHeaders);
                                            final driveApi = drive.DriveApi(client);
                                            await driveApi.files.delete(f.id!);
                                            setState(() {
                                              fileList.removeAt(idx);
                                            });
                                            main.showAppSnackBar(context, '已刪除備份 ${f.name}', icon: Icons.delete_forever_rounded, color: Colors.redAccent);
                                          } catch (e) {
                                            main.showAppSnackBar(context, '刪除失敗: ' + e.toString(), icon: Icons.error, color: Colors.redAccent);
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, null),
                        child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
      if (selected == null) return;
      // 3. 確認覆蓋
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 12,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                    SizedBox(width: 8),
                    Text(AppLocalizations.of(context)!.confirmRestore, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                ),
                SizedBox(height: 18),
                Text(
                  '將覆蓋本地資料庫，確定要還原嗎？',
                  style: TextStyle(fontSize: 16, color: Colors.blueGrey[800]),
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
                        child: Text('取消', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    SizedBox(width: 18),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('確定', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      if (confirm != true) return;
      // 4. 下載檔案並覆蓋
      setState(() { _isLoading = true; _progress = 0.0; });
      final media = await driveApi.files.get(selected.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      final dbDir = await getDatabasesPath();
      final dbFile = File('$dbDir/exercise_records.db');
      final sink = dbFile.openWrite();
      int downloaded = 0;
      final total = media.length ?? 1;
      await for (final chunk in media.stream) {
        sink.add(chunk);
        downloaded += chunk.length;
        setState(() { _progress = downloaded / total; });
      }
      await sink.close();
      setState(() { _isLoading = false; _progress = 0.0; });
      main.showAppSnackBar(context, '還原成功！', icon: Icons.check_circle, color: Colors.green);
    } catch (e) {
      setState(() { _isLoading = false; _progress = 0.0; });
      main.showAppSnackBar(context, '還原失敗: ' + e.toString(), icon: Icons.error, color: Colors.redAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabataState = context.watch<main.TabataState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: ListView(
        children: [
          if (_currentUser != null)
            ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(_currentUser!.photoUrl ?? ''),
                child: _currentUser!.photoUrl == null ? Icon(Icons.account_circle) : null,
              ),
              title: Text(
                _currentUser!.displayName ?? _currentUser!.email,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
              ),
              subtitle: Text(
                _currentUser!.email,
                style: TextStyle(fontSize: 13, color: Colors.blueGrey),
              ),
              trailing: TextButton(
                onPressed: _handleSignOut,
                child: Text(AppLocalizations.of(context)!.signOut),
              ),
            )
          else
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text(
                AppLocalizations.of(context)!.notSignedInGoogle,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
              ),
              trailing: TextButton(
                onPressed: _handleSignIn,
                child: Text(AppLocalizations.of(context)!.signIn),
              ),
            ),
          SwitchListTile(
            title: Text(
              AppLocalizations.of(context)!.bgm,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              AppLocalizations.of(context)!.bgmHint,
              style: TextStyle(fontSize: 13, color: Colors.blueGrey),
            ),
            value: tabataState.bgmEnabled,
            onChanged: (value) {
              tabataState.setBgmEnabled(value);
            },
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(Icons.brightness_6, color: Colors.blueAccent, size: 22),
              title: Text('主題模式', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text(
                tabataState.themeMode == ThemeMode.system
                  ? '跟隨系統'
                  : tabataState.themeMode == ThemeMode.dark
                    ? '深色'
                    : '淺色',
                style: TextStyle(fontSize: 13, color: Colors.blueGrey),
              ),
              trailing: ElevatedButton.icon(
                icon: Icon(Icons.arrow_drop_down, size: 18),
                label: Text(
                  tabataState.themeMode == ThemeMode.system
                    ? '跟隨系統'
                    : tabataState.themeMode == ThemeMode.dark
                      ? '深色'
                      : '淺色',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: TextStyle(fontSize: 15),
                ),
                onPressed: () async {
                  final mode = await showModalBottomSheet<ThemeMode>(
                    context: context,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Icon(Icons.settings),
                          title: Text('跟隨系統', style: TextStyle(fontSize: 15)),
                          onTap: () => Navigator.pop(context, ThemeMode.system),
                          selected: tabataState.themeMode == ThemeMode.system,
                        ),
                        ListTile(
                          leading: Icon(Icons.light_mode),
                          title: Text('淺色', style: TextStyle(fontSize: 15)),
                          onTap: () => Navigator.pop(context, ThemeMode.light),
                          selected: tabataState.themeMode == ThemeMode.light,
                        ),
                        ListTile(
                          leading: Icon(Icons.dark_mode),
                          title: Text('深色', style: TextStyle(fontSize: 15)),
                          onTap: () => Navigator.pop(context, ThemeMode.dark),
                          selected: tabataState.themeMode == ThemeMode.dark,
                        ),
                      ],
                    ),
                  );
                  if (mode != null && widget.onThemeModeChanged != null) {
                    widget.onThemeModeChanged!(mode);
                  }
                },
              ),
            ),
          ),
          const Divider(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              icon: Icon(Icons.cloud_upload),
              label: Text(AppLocalizations.of(context)!.backupToDrive),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: backupToGoogleDrive,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              icon: Icon(Icons.cloud_download),
              label: Text(AppLocalizations.of(context)!.restoreFromDrive),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: restoreFromGoogleDrive,
            ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _progress > 0 && _progress < 1 ? _progress : null,
                    minHeight: 12,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
                  SizedBox(height: 12),
                  Text(
                    _progress > 0 ? '進度：${(_progress * 100).toStringAsFixed(0)}%' : '處理中...',
                    style: TextStyle(fontSize: 16, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.resetAllSettings),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await tabataState.resetPreferences();
                if (!context.mounted) return;
                main.showAppSnackBar(context, AppLocalizations.of(context)!.resetToDefault, icon: Icons.refresh, color: Colors.blueAccent);
              },
            ),
          ),
          Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Icon(Icons.language, color: Colors.blueAccent, size: 22),
              title: Text(
                AppLocalizations.of(context)!.changeLanguage,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                Localizations.localeOf(context).languageCode == 'zh' && Localizations.localeOf(context).scriptCode == 'Hans'
                  ? '🇨🇳 ' + '简体中文'
                  : Localizations.localeOf(context).languageCode == 'zh'
                    ? '🇹🇼 ' + AppLocalizations.of(context)!.languageChinese
                    : '🇺🇸 ' + AppLocalizations.of(context)!.languageEnglish,
                style: TextStyle(fontSize: 13, color: Colors.blueGrey),
              ),
              trailing: ElevatedButton.icon(
                icon: Icon(Icons.arrow_drop_down, size: 18),
                label: Text(
                  Localizations.localeOf(context).languageCode == 'zh' && Localizations.localeOf(context).scriptCode == 'Hans'
                    ? AppLocalizations.of(context)!.languageChineseSimplified
                    : Localizations.localeOf(context).languageCode == 'zh'
                      ? AppLocalizations.of(context)!.languageChinese
                      : AppLocalizations.of(context)!.languageEnglish,
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: TextStyle(fontSize: 15),
                ),
                onPressed: () async {
                  final locale = await showModalBottomSheet<Locale>(
                    context: context,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (context) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Text('🇺🇸', style: TextStyle(fontSize: 20)),
                          title: Text(AppLocalizations.of(context)!.languageEnglish, style: TextStyle(fontSize: 15)),
                          onTap: () => Navigator.pop(context, Locale('en')),
                        ),
                        ListTile(
                          leading: Text('🇹🇼', style: TextStyle(fontSize: 20)),
                          title: Text(AppLocalizations.of(context)!.languageChinese, style: TextStyle(fontSize: 15)),
                          onTap: () => Navigator.pop(context, Locale('zh')),
                        ),
                        ListTile(
                          leading: Text('🇨🇳', style: TextStyle(fontSize: 20)),
                          title: Text(AppLocalizations.of(context)!.languageChineseSimplified, style: TextStyle(fontSize: 15)),
                          onTap: () => Navigator.pop(context, Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans')),
                        ),
                      ],
                    ),
                  );
                  if (locale != null && widget.onLocaleChanged != null) {
                    widget.onLocaleChanged!(locale);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();
  GoogleHttpClient(this._headers);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
