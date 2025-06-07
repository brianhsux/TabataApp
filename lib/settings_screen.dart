import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tabataState = context.watch<TabataState>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
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
              icon: Icon(Icons.refresh),
              label: Text('重設所有設定'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await tabataState.resetPreferences();
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
