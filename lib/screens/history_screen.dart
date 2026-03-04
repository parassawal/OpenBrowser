import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import '../providers/browser_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final browserProvider = context.read<BrowserProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('History', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (historyProvider.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1E1E1E),
                        title: const Text(
                          'Clear History',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          'Delete all browsing history?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            onPressed: () {
                              historyProvider.clearHistory();
                              Navigator.pop(ctx);
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                );
              },
            ),
        ],
      ),
      body:
          historyProvider.history.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, color: Colors.white24, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'No browsing history',
                      style: TextStyle(color: Colors.white38, fontSize: 16),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: historyProvider.history.length,
                itemBuilder: (context, index) {
                  final item = historyProvider.history[index];
                  return ListTile(
                    leading: const Icon(Icons.history, color: Colors.white38),
                    title: Text(
                      item['title'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: Text(
                      item['url'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white24,
                        size: 18,
                      ),
                      onPressed:
                          () => historyProvider.removeFromHistory(item['_id']),
                    ),
                    onTap: () {
                      browserProvider.updateSearchUrl(item['url']);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
    );
  }
}
