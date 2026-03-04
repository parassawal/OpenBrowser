import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

class HistoryProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _history = [];
  Database? _db;

  List<Map<String, dynamic>> get history => _history;

  HistoryProvider() {
    _initDb();
  }

  Future<void> _initDb() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      '$dbPath/history.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE history(_id INTEGER PRIMARY KEY AUTOINCREMENT, url TEXT, title TEXT, timestamp INTEGER)',
        );
      },
    );
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (_db == null) return;
    _history = await _db!.query('history', orderBy: 'timestamp DESC');
    notifyListeners();
  }

  Future<void> addToHistory(String url, String title) async {
    if (_db == null) return;
    // Don't record about:blank
    if (url == 'about:blank' || url.isEmpty) return;
    await _db!.insert('history', {
      'url': url,
      'title': title,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    await _loadHistory();
  }

  Future<void> removeFromHistory(dynamic id) async {
    if (_db == null) return;
    await _db!.delete('history', where: '_id = ?', whereArgs: [id]);
    await _loadHistory();
  }

  Future<void> clearHistory() async {
    if (_db == null) return;
    await _db!.delete('history');
    _history = [];
    notifyListeners();
  }
}
