import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../providers/browser_provider.dart';
import '../providers/bookmark_provider.dart';

/// A single news article parsed from RSS.
class _NewsItem {
  final String title;
  final String url;
  final String source;
  final String pubDate;
  final String? imageUrl;

  _NewsItem({
    required this.title,
    required this.url,
    required this.source,
    required this.pubDate,
    this.imageUrl,
  });
}

/// Default shortcuts shown when user has not customized.
const List<Map<String, dynamic>> _defaultShortcuts = [
  {
    'label': 'Google',
    'url': 'https://www.google.com',
    'icon': 0xe8b6,
    'color': 0xFF4285F4,
  },
  {
    'label': 'YouTube',
    'url': 'https://www.youtube.com',
    'icon': 0xe038,
    'color': 0xFFFF0000,
  },
  {
    'label': 'GitHub',
    'url': 'https://github.com',
    'icon': 0xe86f,
    'color': 0xFF6E40C9,
  },
  {
    'label': 'Reddit',
    'url': 'https://www.reddit.com',
    'icon': 0xe0bf,
    'color': 0xFFFF4500,
  },
  {
    'label': 'Twitter',
    'url': 'https://x.com',
    'icon': 0xef6c,
    'color': 0xFF1DA1F2,
  },
  {
    'label': 'Wikipedia',
    'url': 'https://en.wikipedia.org',
    'icon': 0xe865,
    'color': 0xFF636466,
  },
  {
    'label': 'Amazon',
    'url': 'https://www.amazon.in',
    'icon': 0xe8cc,
    'color': 0xFFFF9900,
  },
  {
    'label': 'Gmail',
    'url': 'https://mail.google.com',
    'icon': 0xe0be,
    'color': 0xFFEA4335,
  },
];

const List<_IconOption> _availableIcons = [
  _IconOption(Icons.search, 'Search'),
  _IconOption(Icons.play_circle_fill, 'Play'),
  _IconOption(Icons.code, 'Code'),
  _IconOption(Icons.forum, 'Forum'),
  _IconOption(Icons.chat_bubble, 'Chat'),
  _IconOption(Icons.menu_book, 'Book'),
  _IconOption(Icons.shopping_cart, 'Shop'),
  _IconOption(Icons.email, 'Email'),
  _IconOption(Icons.public, 'Web'),
  _IconOption(Icons.school, 'School'),
  _IconOption(Icons.work, 'Work'),
  _IconOption(Icons.sports_esports, 'Games'),
  _IconOption(Icons.music_note, 'Music'),
  _IconOption(Icons.photo, 'Photo'),
  _IconOption(Icons.newspaper, 'News'),
  _IconOption(Icons.cloud, 'Cloud'),
];

const List<Color> _availableColors = [
  Color(0xFF4285F4),
  Color(0xFFEA4335),
  Color(0xFFFBBC05),
  Color(0xFF34A853),
  Color(0xFF9C27B0),
  Color(0xFFFF5722),
  Color(0xFF00BCD4),
  Color(0xFF795548),
  Color(0xFFFF9900),
  Color(0xFF1DA1F2),
  Color(0xFF6E40C9),
  Color(0xFF636466),
];

class _IconOption {
  final IconData icon;
  final String name;
  const _IconOption(this.icon, this.name);
}

class NewTabPage extends StatefulWidget {
  const NewTabPage({super.key});

  @override
  State<NewTabPage> createState() => _NewTabPageState();
}

class _NewTabPageState extends State<NewTabPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _shortcuts = [];
  bool _isEditing = false;
  List<_NewsItem> _news = [];
  bool _newsLoading = true;
  String? _newsError;

  @override
  void initState() {
    super.initState();
    _loadShortcuts();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _newsLoading = true;
      _newsError = null;
    });
    try {
      // Use Saurav Tech NewsAPI proxy to get news WITH real images
      final response = await http.get(
        Uri.parse(
          'https://saurav.tech/NewsAPI/top-headlines/category/general/in.json',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawItems = data['articles'] as List? ?? [];
        final items = <_NewsItem>[];

        for (final item in rawItems) {
          final title = item['title'] as String? ?? '';
          final link = item['url'] as String? ?? '';
          final sourceObj = item['source'] as Map<String, dynamic>?;
          final sourceName = sourceObj?['name'] as String? ?? 'News';
          final pubDate = item['publishedAt'] as String? ?? '';
          String? imageUrl = item['urlToImage'] as String?;

          if (imageUrl != null && imageUrl.isEmpty) imageUrl = null;

          if (title.isNotEmpty && link.isNotEmpty) {
            items.add(
              _NewsItem(
                title: _decodeHtml(title),
                url: link,
                source: _decodeHtml(sourceName),
                pubDate: _formatPubDate(pubDate),
                imageUrl: imageUrl,
              ),
            );
          }
          if (items.length >= 15) break;
        }

        if (mounted) {
          setState(() {
            _news = items;
            _newsLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _newsError = 'Could not load news';
            _newsLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _newsError = 'No internet connection';
          _newsLoading = false;
        });
      }
    }
  }

  String _decodeHtml(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }

  String _formatPubDate(String pubDate) {
    try {
      final date = DateTime.parse(
        pubDate
            .replaceFirst(RegExp(r'\w+, '), '')
            .replaceFirst(' GMT', 'Z')
            .replaceFirst(RegExp(r' \+\d{4}'), 'Z'),
      );
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return pubDate.length > 16 ? pubDate.substring(0, 16) : pubDate;
    }
  }

  Future<void> _loadShortcuts() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('quick_access_shortcuts');
    if (stored != null) {
      final list = jsonDecode(stored) as List;
      setState(() {
        _shortcuts = list.cast<Map<String, dynamic>>();
      });
    } else {
      setState(() {
        _shortcuts = List<Map<String, dynamic>>.from(_defaultShortcuts);
      });
    }
  }

  Future<void> _saveShortcuts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quick_access_shortcuts', jsonEncode(_shortcuts));
  }

  void _onSearch(String query) {
    if (query.trim().isEmpty) return;
    context.read<BrowserProvider>().updateSearchUrl(query.trim());
    _searchController.clear();
    _focusNode.unfocus();
  }

  void _showAddEditDialog({int? editIndex}) {
    final isEdit = editIndex != null;
    final existing = isEdit ? _shortcuts[editIndex] : null;

    final labelCtrl = TextEditingController(text: existing?['label'] ?? '');
    final urlCtrl = TextEditingController(text: existing?['url'] ?? 'https://');
    int selectedIcon = existing?['icon'] ?? Icons.public.codePoint;
    int selectedColor = existing?['color'] ?? 0xFF4285F4;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: Text(
                isEdit ? 'Edit Shortcut' : 'Add Shortcut',
                style: const TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: labelCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecor('Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: urlCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecor('URL'),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Icon',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _availableIcons.map((opt) {
                            final isSelected =
                                opt.icon.codePoint == selectedIcon;
                            return GestureDetector(
                              onTap:
                                  () => setDialogState(
                                    () => selectedIcon = opt.icon.codePoint,
                                  ),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? Color(selectedColor)
                                          : const Color(0xFF2C2C2C),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  opt.icon,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Color',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _availableColors.map((c) {
                            final isSelected = c.toARGB32() == selectedColor;
                            return GestureDetector(
                              onTap:
                                  () => setDialogState(
                                    () => selectedColor = c.toARGB32(),
                                  ),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                if (isEdit)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _shortcuts.removeAt(editIndex);
                      });
                      _saveShortcuts();
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(selectedColor),
                  ),
                  onPressed: () {
                    final label = labelCtrl.text.trim();
                    final url = urlCtrl.text.trim();
                    if (label.isEmpty || url.isEmpty) return;
                    final entry = {
                      'label': label,
                      'url': url,
                      'icon': selectedIcon,
                      'color': selectedColor,
                    };
                    setState(() {
                      if (isEdit) {
                        _shortcuts[editIndex] = entry;
                      } else {
                        _shortcuts.add(entry);
                      }
                    });
                    _saveShortcuts();
                    Navigator.pop(ctx);
                  },
                  child: Text(isEdit ? 'Save' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecor(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final browserProvider = context.read<BrowserProvider>();

    return Container(
      color: Colors.black,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),

            // ── Logo ─────────────────────────────────────
            const Text(
              'Google',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 28),

            // ── Search Bar ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF202124,
                  ), // Google Chrome dark bar color
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    // "G" logo simulation
                    RichText(
                      text: const TextSpan(
                        text: 'G',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search Google or type URL',
                          hintStyle: TextStyle(
                            color: Colors.white54,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onSubmitted: _onSearch,
                        textInputAction: TextInputAction.search,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.mic,
                        color: Colors.white54,
                        size: 24,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.lens_blur_outlined,
                        color: Colors.white54,
                        size: 24,
                      ),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── AI Mode & Incognito Buttons ─────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        // AI mode logic could go here
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF202124),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'AI Mode',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        browserProvider.createNewTab(isIncognito: true);
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF202124),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.privacy_tip_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Incognito',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Quick Access ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF202124,
                  ), // Large encapsulated container
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  spacing: 16,
                  runSpacing: 24,
                  children: [
                    ..._shortcuts.asMap().entries.map((entry) {
                      final i = entry.key;
                      final s = entry.value;
                      return _QuickLink(
                        label: s['label'] as String,
                        iconData: IconData(
                          s['icon'] as int,
                          fontFamily: 'MaterialIcons',
                        ),
                        color: Color(s['color'] as int),
                        isEditing: _isEditing,
                        onTap: () {
                          if (_isEditing) {
                            _showAddEditDialog(editIndex: i);
                          } else {
                            browserProvider.updateSearchUrl(s['url'] as String);
                          }
                        },
                      );
                    }),
                    // Add button
                    _QuickLink(
                      label: 'Add',
                      iconData: Icons.add,
                      color: Colors.white38,
                      isEditing: false,
                      onTap: () => _showAddEditDialog(),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bookmarks ────────────────────────────────
            if (bookmarkProvider.bookmarks.isNotEmpty) ...[
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bookmarks',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children:
                          bookmarkProvider.bookmarks.take(8).map((bm) {
                            return _QuickLink(
                              label: bm['title'] as String? ?? 'Bookmark',
                              iconData: Icons.bookmark,
                              color: Colors.blueAccent,
                              isEditing: false,
                              onTap:
                                  () => browserProvider.updateSearchUrl(
                                    bm['url'] as String,
                                  ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ],

            // ── News Feed ─────────────────────────────────
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.article, color: Colors.white38, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Top Stories',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _fetchNews,
                    child: const Icon(
                      Icons.refresh,
                      color: Colors.blueAccent,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_newsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white24,
                  ),
                ),
              )
            else if (_newsError != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 24,
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cloud_off,
                        color: Colors.white24,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _newsError!,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _fetchNews,
                        child: const Text(
                          'Tap to retry',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(_news.length, (i) {
                final item = _news[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => browserProvider.updateSearchUrl(item.url),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Big image on top
                            if (item.imageUrl != null)
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.network(
                                  item.imageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                        color: const Color(0xFF2A2A2A),
                                        child: const Center(
                                          child: Icon(
                                            Icons.image_outlined,
                                            color: Colors.white12,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                ),
                              )
                            else
                              AspectRatio(
                                aspectRatio: 21 / 9,
                                child: Container(
                                  color: const Color(0xFF2A2A2A),
                                  child: Center(
                                    child: Icon(
                                      Icons.newspaper,
                                      color: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                      size: 48,
                                    ),
                                  ),
                                ),
                              ),
                            // Info section below image
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                12,
                                14,
                                14,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF333333),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            item.source.isNotEmpty
                                                ? item.source[0].toUpperCase()
                                                : 'N',
                                            style: const TextStyle(
                                              color: Colors.blueAccent,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          item.source,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: Text(
                                          '·',
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.3,
                                            ),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        item.pubDate,
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

// ─────────────────── Quick Link Tile ─────────────────────
class _QuickLink extends StatelessWidget {
  final String label;
  final IconData iconData;
  final Color color;
  final VoidCallback onTap;
  final bool isEditing;

  const _QuickLink({
    required this.label,
    required this.iconData,
    required this.color,
    required this.onTap,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333), // Grey circular background
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Icon(iconData, color: color, size: 26)),
                ),
                if (isEditing)
                  const Positioned(
                    top: -4,
                    right: -4,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.edit, size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
