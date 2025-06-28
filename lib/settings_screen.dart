import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google 登入失敗: ' + error.toString())),
      );
    }
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.disconnect();
  }

  Future<void> backupToGoogleDrive() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('請先登入 Google')));
      return;
    }
    try {
      // 1. 取得本地 DB 檔案
      final dbDir = await getDatabasesPath();
      final dbFile = File('$dbDir/exercise_records.db');
      if (!await dbFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('找不到資料庫檔案')));
        return;
      }
      // 2. 取得 Google OAuth token
      final authHeaders = await _currentUser!.authHeaders;
      final client = GoogleHttpClient(authHeaders);
      // 3. 上傳到 Google Drive
      final driveApi = drive.DriveApi(client);
      final fileToUpload = drive.File()
        ..name = 'tabata_backup_${DateTime.now().toIso8601String()}.db';
      await driveApi.files.create(
        fileToUpload,
        uploadMedia: drive.Media(dbFile.openRead(), await dbFile.length()),
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('備份成功！')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('備份失敗: ' + e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabataState = context.watch<TabataState>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          if (_currentUser != null)
            ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(_currentUser!.photoUrl ?? ''),
                child: _currentUser!.photoUrl == null ? Icon(Icons.account_circle) : null,
              ),
              title: Text(_currentUser!.displayName ?? _currentUser!.email),
              subtitle: Text(_currentUser!.email),
              trailing: TextButton(
                onPressed: _handleSignOut,
                child: Text('登出'),
              ),
            )
          else
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('尚未登入 Google'),
              trailing: TextButton(
                onPressed: _handleSignIn,
                child: Text('登入'),
              ),
            ),
          SwitchListTile(
            title: Text('背景音樂 (BGM)'),
            subtitle: Text('啟用時，workout/rest 階段會播放背景音樂'),
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
              icon: Icon(Icons.refresh),
              label: Text('重設所有設定'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await tabataState.resetPreferences();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已重設為預設值')),
                );
              },
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
