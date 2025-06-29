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
import 'l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.onLocaleChanged});

  final Function(Locale)? onLocaleChanged;

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
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      main.showAppSnackBar(context, 'Google 登入失敗: ' + error.toString(), icon: Icons.error, color: Colors.redAccent);
    }
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.disconnect();
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
                        Text('選擇要還原的備份', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
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
                        child: Text('取消', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
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
                    Text('確認還原', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
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
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
              subtitle: Text(
                _currentUser!.email,
                style: TextStyle(fontSize: 13, color: Colors.blueGrey[700]),
              ),
              trailing: TextButton(
                onPressed: _handleSignOut,
                child: Text('登出'),
              ),
            )
          else
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text(
                '尚未登入 Google',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
              trailing: TextButton(
                onPressed: _handleSignIn,
                child: Text('登入'),
              ),
            ),
          SwitchListTile(
            title: Text(
              '背景音樂 (BGM)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
            subtitle: Text(
              '啟用時，workout/rest 階段會播放背景音樂',
              style: TextStyle(fontSize: 13, color: Colors.blueGrey),
            ),
            value: tabataState.bgmEnabled,
            onChanged: (value) {
              tabataState.setBgmEnabled(value);
            },
          ),
          const Divider(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              icon: Icon(Icons.cloud_upload),
              label: Text('備份到 Google Drive'),
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
              label: Text('從 Google Drive 還原'),
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
              label: Text('重設所有設定'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await tabataState.resetPreferences();
                if (!context.mounted) return;
                main.showAppSnackBar(context, '已重設為預設值', icon: Icons.refresh, color: Colors.blueAccent);
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
                Localizations.localeOf(context).languageCode == 'zh'
                  ? '🇹🇼 繁體中文'
                  : '🇺🇸 English',
                style: TextStyle(fontSize: 13, color: Colors.blueGrey[700]),
              ),
              trailing: ElevatedButton.icon(
                icon: Icon(Icons.arrow_drop_down, size: 18),
                label: Text(
                  Localizations.localeOf(context).languageCode == 'zh'
                    ? '繁體中文'
                    : 'English',
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
                          title: Text('English', style: TextStyle(fontSize: 15)),
                          onTap: () => Navigator.pop(context, Locale('en')),
                        ),
                        ListTile(
                          leading: Text('🇹🇼', style: TextStyle(fontSize: 20)),
                          title: Text('繁體中文', style: TextStyle(fontSize: 15)),
                          onTap: () => Navigator.pop(context, Locale('zh')),
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
