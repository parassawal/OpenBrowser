import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

class BookmarkProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _bookmarks = [];
  Database? _db;

  List<Map<String, dynamic>> get bookmarks => _bookmarks;

  BookmarkProvider() {
    _initDb();
  }

  Future<void> _initDb() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      '$dbPath/bookmarks.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE bookmarks(_id INTEGER PRIMARY KEY AUTOINCREMENT, url TEXT, title TEXT, timestamp INTEGER)',
        );
      },
    );
    await _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    if (_db == null) return;
    _bookmarks = await _db!.query('bookmarks', orderBy: 'timestamp DESC');
    notifyListeners();
  }

  Future<void> addBookmark(String url, String title) async {
    if (_db == null) return;
    await _db!.insert('bookmarks', {
      'url': url,
      'title': title,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    await _loadBookmarks();
  }

  Future<void> removeBookmark(dynamic id) async {
    if (_db == null) return;
    await _db!.delete('bookmarks', where: '_id = ?', whereArgs: [id]);
    await _loadBookmarks();
  }

  bool isBookmarked(String url) {
    return _bookmarks.any((b) => b['url'] == url);
  }
}
