import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/browser_provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/history_provider.dart';
import '../screens/tabs_overview.dart';
import '../screens/history_screen.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/downloads_screen.dart';

class ChromeTopBar extends StatefulWidget {
  const ChromeTopBar({super.key});

  @override
  State<ChromeTopBar> createState() => _ChromeTopBarState();
}

class _ChromeTopBarState extends State<ChromeTopBar> {
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _urlController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _urlController.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String text,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final browserProvider = context.watch<BrowserProvider>();
    final activeTab = browserProvider.activeTab;

    if (activeTab == null) return const SizedBox.shrink();

    if (!_focusNode.hasFocus) {
      _urlController.text = activeTab.url;
    }

    bool isHttps = activeTab.url.startsWith('https://');

    return Container(
      color: Colors.black, // Match Scaffold background
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Home Button
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              activeTab.webViewController.loadRequest(Uri.parse('about:blank'));
              activeTab.url = 'about:blank';
              activeTab.title = 'New Tab';
              _focusNode.unfocus();
            },
          ),
          const SizedBox(width: 8),

          // Search / URL Capsule
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(
                  0xFF202124,
                ), // Chrome's dark mode text field color
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    isHttps ? Icons.lock : Icons.lock_open,
                    color: isHttps ? Colors.white70 : Colors.redAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      focusNode: _focusNode,
                      maxLines: 1,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.go,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Search or type URL',
                        hintStyle: TextStyle(color: Colors.white54),
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          browserProvider.updateSearchUrl(value);
                          _focusNode.unfocus();
                        }
                      },
                    ),
                  ),
                  // Bookmark Icon inside capsule
                  Consumer<BookmarkProvider>(
                    builder: (context, bookmarkProvider, child) {
                      final isBookmarked = bookmarkProvider.isBookmarked(
                        activeTab.url,
                      );
                      return IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.star : Icons.star_border,
                          color: isBookmarked
                              ? Colors.blueAccent
                              : Colors.white70,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          if (activeTab.url.startsWith('http')) {
                            if (isBookmarked) {
                              final b = bookmarkProvider.bookmarks.firstWhere(
                                (element) => element['url'] == activeTab.url,
                              );
                              bookmarkProvider.removeBookmark(b['_id']);
                            } else {
                              bookmarkProvider.addBookmark(
                                activeTab.url,
                                activeTab.title,
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),

          // New Tab Button
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              browserProvider.createNewTab();
            },
          ),
          const SizedBox(width: 8),

          // Tabs Counter Button
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TabsOverviewScreen()),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white70, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${browserProvider.tabs.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Menu Button
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF1E1E1E),
            offset: const Offset(0, 48), // Drops down from the top right
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) async {
              if (value == 'new_tab') {
                browserProvider.createNewTab();
              } else if (value == 'new_incognito') {
                browserProvider.createNewTab(isIncognito: true);
              } else if (value == 'add_tab_group' || value == 'new_tab_group') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TabsOverviewScreen()),
                );
              } else if (value == 'history') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              } else if (value == 'delete_history') {
                context.read<HistoryProvider>().clearHistory();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Browsing history deleted')),
                );
              } else if (value == 'downloads') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DownloadsScreen()),
                );
              } else if (value == 'bookmarks') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookmarksScreen()),
                );
              } else if (value == 'recent_tabs') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recent tabs coming soon')),
                );
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              } else if (value == 'customise') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Customise coming soon')),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      color: activeTab.canGoForward
                          ? Colors.white
                          : Colors.white30,
                      onPressed: activeTab.canGoForward
                          ? () {
                              activeTab.webViewController.goForward();
                              Navigator.pop(context);
                            }
                          : null,
                    ),
                    Consumer<BookmarkProvider>(
                      builder: (context, bookmarkProvider, child) {
                        final isBookmarked = bookmarkProvider.isBookmarked(
                          activeTab.url,
                        );
                        return IconButton(
                          icon: Icon(
                            isBookmarked ? Icons.star : Icons.star_border,
                          ),
                          color: isBookmarked
                              ? Colors.blueAccent
                              : Colors.white,
                          onPressed: () {
                            if (activeTab.url.startsWith('http')) {
                              if (isBookmarked) {
                                final b = bookmarkProvider.bookmarks.firstWhere(
                                  (e) => e['url'] == activeTab.url,
                                );
                                bookmarkProvider.removeBookmark(b['_id']);
                              } else {
                                bookmarkProvider.addBookmark(
                                  activeTab.url,
                                  activeTab.title,
                                );
                              }
                            }
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () {
                        activeTab.webViewController.reload();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              _buildMenuItem('new_tab', Icons.add_box_outlined, 'New tab'),
              _buildMenuItem(
                'new_incognito',
                Icons.privacy_tip_outlined,
                'New Incognito tab',
              ),
              _buildMenuItem(
                'add_tab_group',
                Icons.library_add,
                'Add tab to new group',
              ),
              const PopupMenuDivider(),
              _buildMenuItem('history', Icons.history, 'History'),
              _buildMenuItem(
                'delete_history',
                Icons.delete_outline,
                'Delete browsing history',
              ),
              _buildMenuItem('downloads', Icons.file_download, 'Downloads'),
              _buildMenuItem('bookmarks', Icons.bookmark_border, 'Bookmarks'),
              _buildMenuItem('recent_tabs', Icons.restore, 'Recent tabs'),
              const PopupMenuDivider(),
              _buildMenuItem('settings', Icons.settings, 'Settings'),
              _buildMenuItem('customise', Icons.tune, 'Customise'),
              _buildMenuItem('new_tab_group', Icons.tab, 'New Tab Group'),
            ],
          ),
        ],
      ),
    );
  }
}
