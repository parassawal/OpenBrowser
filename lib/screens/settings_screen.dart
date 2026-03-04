import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/download_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _jsEnabled = true;
  String _searchEngine = 'Google';

  @override
  Widget build(BuildContext context) {
    final downloadProvider = context.watch<DownloadProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          const _SectionHeader('General'),
          SwitchListTile(
            title: const Text(
              'JavaScript',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Enable JavaScript execution',
              style: TextStyle(color: Colors.white38),
            ),
            value: _jsEnabled,
            activeThumbColor: Colors.blueAccent,
            onChanged: (val) => setState(() => _jsEnabled = val),
          ),
          ListTile(
            title: const Text(
              'Default Search Engine',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              _searchEngine,
              style: const TextStyle(color: Colors.white38),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white24,
              size: 16,
            ),
            onTap: () {
              showDialog(
                context: context,
                builder:
                    (ctx) => SimpleDialog(
                      backgroundColor: const Color(0xFF1E1E1E),
                      title: const Text(
                        'Search Engine',
                        style: TextStyle(color: Colors.white),
                      ),
                      children:
                          ['Google', 'Bing', 'DuckDuckGo', 'Yahoo'].map((e) {
                            return SimpleDialogOption(
                              child: Text(
                                e,
                                style: TextStyle(
                                  color:
                                      e == _searchEngine
                                          ? Colors.blueAccent
                                          : Colors.white,
                                ),
                              ),
                              onPressed: () {
                                setState(() => _searchEngine = e);
                                Navigator.pop(ctx);
                              },
                            );
                          }).toList(),
                    ),
              );
            },
          ),
          const Divider(color: Color(0xFF2C2C2C)),
          const _SectionHeader('Downloads'),
          ListTile(
            title: const Text(
              'Download Location',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              downloadProvider.downloadPath.isEmpty
                  ? 'Default (App directory)'
                  : downloadProvider.downloadPath,
              style: const TextStyle(color: Colors.white38),
            ),
            trailing: const Icon(
              Icons.folder_open,
              color: Colors.white24,
              size: 20,
            ),
            onTap: () async {
              final result = await FilePicker.platform.getDirectoryPath();
              if (result != null) {
                downloadProvider.setDownloadPath(result);
              }
            },
          ),
          const Divider(color: Color(0xFF2C2C2C)),
          const _SectionHeader('Privacy'),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title: const Text(
              'Clear Cookies',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cookies cleared'),
                  backgroundColor: Color(0xFF323232),
                ),
              );
            },
          ),
          const Divider(color: Color(0xFF2C2C2C)),
          const _SectionHeader('About'),
          const ListTile(
            title: Text('OpenBrowser', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.white38),
            ),
            leading: Icon(Icons.info_outline, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.blueAccent,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
