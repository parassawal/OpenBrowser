import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/download_provider.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final downloadProvider = context.watch<DownloadProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Downloads', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder, color: Colors.white),
            onPressed: () async {
              final result = await FilePicker.platform.getDirectoryPath();
              if (result != null) {
                downloadProvider.setDownloadPath(result);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Download location: $result'),
                      backgroundColor: const Color(0xFF323232),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body:
          downloadProvider.downloads.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.file_download, color: Colors.white24, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'No downloads yet',
                      style: TextStyle(color: Colors.white38, fontSize: 16),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: downloadProvider.downloads.length,
                itemBuilder: (context, index) {
                  final item = downloadProvider.downloads[index];
                  return Card(
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: Icon(
                        item.status == 'completed'
                            ? Icons.check_circle
                            : item.status == 'failed'
                            ? Icons.error
                            : Icons.downloading,
                        color:
                            item.status == 'completed'
                                ? Colors.green
                                : item.status == 'failed'
                                ? Colors.redAccent
                                : Colors.blueAccent,
                      ),
                      title: Text(
                        item.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.status == 'downloading' ||
                              item.status == 'merging') ...[
                            const SizedBox(height: 4),
                            if (item.status == 'merging')
                              const LinearProgressIndicator(
                                minHeight: 6,
                                color: Colors.blueAccent,
                                backgroundColor: Color(0xFF2C2C2C),
                              )
                            else if (item.isMultiPart)
                              Row(
                                children: List.generate(item.activeThreads, (
                                  i,
                                ) {
                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right:
                                            i < item.activeThreads - 1
                                                ? 2.0
                                                : 0.0,
                                      ),
                                      child: LinearProgressIndicator(
                                        minHeight: 6,
                                        value:
                                            item.partProgress.length > i
                                                ? item.partProgress[i]
                                                : 0.0,
                                        color: Colors.blueAccent,
                                        backgroundColor: const Color(
                                          0xFF2C2C2C,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              )
                            else
                              LinearProgressIndicator(
                                minHeight: 6,
                                value:
                                    item.totalBytes > 0 ? item.progress : null,
                                color: Colors.blueAccent,
                                backgroundColor: const Color(0xFF2C2C2C),
                              ),
                            const SizedBox(height: 4),
                            if (item.status == 'merging')
                              const Text(
                                'Constructing file parts...',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              )
                            else ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${_formatBytes(item.downloadedBytes)}${item.totalBytes > 0 ? ' / ${_formatBytes(item.totalBytes)}' : ''} • ${item.speed}',
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (item.eta.isNotEmpty &&
                                      item.eta != '--:--')
                                    Text(
                                      '${item.eta} left',
                                      style: const TextStyle(
                                        color: Colors.blueAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                              if (item.isMultiPart)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.bolt,
                                        color: Colors.blueAccent,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Multi-part (${item.activeThreads} parts)',
                                        style: const TextStyle(
                                          color: Colors.blueAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ] else
                            Text(
                              item.status == 'completed'
                                  ? _formatBytes(
                                    item.totalBytes > 0
                                        ? item.totalBytes
                                        : item.downloadedBytes,
                                  )
                                  : 'Download failed',
                              style: TextStyle(
                                color:
                                    item.status == 'failed'
                                        ? Colors.redAccent
                                        : Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white24,
                          size: 18,
                        ),
                        onPressed: () => downloadProvider.removeDownload(index),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
