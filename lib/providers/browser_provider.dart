import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/tab_state.dart';
import '../models/tab_group.dart';

class BrowserProvider extends ChangeNotifier {
  final List<TabState> _tabs = [];
  int _activeTabIndex = 0;
  final List<TabGroup> _tabGroups = [];

  /// Called when a download URL is detected
  Function(String url)? onDownloadRequested;

  List<TabState> get tabs => _tabs;
  int get activeTabIndex => _activeTabIndex;
  TabState? get activeTab => _tabs.isNotEmpty ? _tabs[_activeTabIndex] : null;
  List<TabGroup> get tabGroups => _tabGroups;

  static const _downloadExtensions = [
    '.apk',
    '.zip',
    '.rar',
    '.7z',
    '.tar',
    '.gz',
    '.pdf',
    '.doc',
    '.docx',
    '.xls',
    '.xlsx',
    '.ppt',
    '.pptx',
    '.mp3',
    '.mp4',
    '.avi',
    '.mkv',
    '.mov',
    '.flv',
    '.wmv',
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.bmp',
    '.svg',
    '.webp',
    '.exe',
    '.msi',
    '.dmg',
    '.deb',
    '.rpm',
    '.csv',
    '.txt',
    '.json',
    '.xml',
    '.iso',
    '.img',
  ];

  BrowserProvider() {
    createNewTab();
  }

  bool _isDownloadUrl(String url) {
    final lower = url.toLowerCase().split('?').first;
    return _downloadExtensions.any((ext) => lower.endsWith(ext));
  }

  void createNewTab({bool isIncognito = false}) {
    final controller = WebViewController();
    _setupWebViewController(controller);
    controller.loadRequest(Uri.parse('about:blank'));

    final tab = TabState(
      url: 'about:blank',
      title: 'New Tab',
      isIncognito: isIncognito,
      webViewController: controller,
    );

    _tabs.add(tab);
    _activeTabIndex = _tabs.length - 1;
    notifyListeners();
  }

  void _setupWebViewController(WebViewController controller) {
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (_isDownloadUrl(request.url)) {
              onDownloadRequested?.call(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (url) {
            final tab = _tabs.firstWhere(
              (t) => t.webViewController == controller,
              orElse: () => _tabs.first,
            );
            tab.url = url;
            tab.progress = 0.0;
            notifyListeners();
          },
          onProgress: (progress) {
            final tab = _tabs.firstWhere(
              (t) => t.webViewController == controller,
              orElse: () => _tabs.first,
            );
            tab.progress = progress / 100;
            notifyListeners();
          },
          onPageFinished: (url) async {
            final tab = _tabs.firstWhere(
              (t) => t.webViewController == controller,
              orElse: () => _tabs.first,
            );
            tab.url = url;
            tab.progress = 1.0;
            tab.title = await controller.getTitle() ?? url;
            tab.canGoBack = await controller.canGoBack();
            tab.canGoForward = await controller.canGoForward();
            notifyListeners();
          },
          onUrlChange: (change) {
            if (change.url != null && _isDownloadUrl(change.url!)) {
              onDownloadRequested?.call(change.url!);
            }
          },
        ),
      );
  }

  void setActiveTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _activeTabIndex = index;
      notifyListeners();
    }
  }

  void closeTab(int index) {
    if (_tabs.length <= 1) return;
    _tabs.removeAt(index);
    if (_activeTabIndex >= _tabs.length) {
      _activeTabIndex = _tabs.length - 1;
    }
    notifyListeners();
  }

  void updateSearchUrl(String input) {
    if (activeTab == null) return;
    String url;
    if (input.startsWith('http://') || input.startsWith('https://')) {
      url = input;
    } else if (input.contains('.') && !input.contains(' ')) {
      url = 'https://$input';
    } else {
      url = 'https://www.google.com/search?q=${Uri.encodeComponent(input)}';
    }
    activeTab!.url = url;
    activeTab!.webViewController.loadRequest(Uri.parse(url));
    notifyListeners();
  }

  // ── Tab Groups ──────────────────────────────────
  TabGroup createTabGroup(String name, {Color color = Colors.blueAccent}) {
    final group = TabGroup(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      color: color,
    );
    _tabGroups.add(group);
    notifyListeners();
    return group;
  }

  void addTabToGroup(int tabIndex, String groupId) {
    if (tabIndex >= 0 && tabIndex < _tabs.length) {
      _tabs[tabIndex].groupId = groupId;
      notifyListeners();
    }
  }

  void removeTabFromGroup(int tabIndex) {
    if (tabIndex >= 0 && tabIndex < _tabs.length) {
      _tabs[tabIndex].groupId = null;
      notifyListeners();
    }
  }

  void renameTabGroup(String groupId, String newName) {
    final group = _tabGroups.firstWhere((g) => g.id == groupId);
    group.name = newName;
    notifyListeners();
  }

  void deleteTabGroup(String groupId) {
    for (final tab in _tabs) {
      if (tab.groupId == groupId) tab.groupId = null;
    }
    _tabGroups.removeWhere((g) => g.id == groupId);
    notifyListeners();
  }

  void toggleGroupCollapsed(String groupId) {
    final group = _tabGroups.firstWhere((g) => g.id == groupId);
    group.isCollapsed = !group.isCollapsed;
    notifyListeners();
  }

  List<TabState> getTabsInGroup(String groupId) {
    return _tabs.where((t) => t.groupId == groupId).toList();
  }

  List<TabState> get ungroupedTabs {
    return _tabs.where((t) => t.groupId == null).toList();
  }
}
