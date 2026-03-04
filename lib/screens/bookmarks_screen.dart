import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/browser_provider.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final browserProvider = context.read<BrowserProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Bookmarks', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          bookmarkProvider.bookmarks.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      color: Colors.white24,
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No bookmarks yet',
                      style: TextStyle(color: Colors.white38, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap the star icon to bookmark a page',
                      style: TextStyle(color: Colors.white24, fontSize: 13),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: bookmarkProvider.bookmarks.length,
                itemBuilder: (context, index) {
                  final bm = bookmarkProvider.bookmarks[index];
                  return Dismissible(
                    key: Key(bm['_id'].toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.redAccent,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed:
                        (_) => bookmarkProvider.removeBookmark(bm['_id']),
                    child: ListTile(
                      leading: const Icon(
                        Icons.bookmark,
                        color: Colors.blueAccent,
                      ),
                      title: Text(
                        bm['title'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        bm['url'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        browserProvider.updateSearchUrl(bm['url']);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
    );
  }
}
