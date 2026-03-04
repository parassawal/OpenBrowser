import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class DownloadItem {
  final String url;
  final String fileName;
  String status; // downloading, merging, completed, failed
  double progress;
  int totalBytes;
  int downloadedBytes;
  String speed;
  String eta;
  int activeThreads;
  bool isMultiPart;
  List<double> partProgress;
  String? savePath;

  DownloadItem({
    required this.url,
    required this.fileName,
    this.status = 'downloading',
    this.progress = 0.0,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.speed = '',
    this.eta = '--:--',
    this.activeThreads = 1,
    this.isMultiPart = false,
    List<double>? partProgress,
    this.savePath,
  }) : partProgress = partProgress ?? [];
}

class DownloadProvider extends ChangeNotifier {
  final List<DownloadItem> _downloads = [];
  final SharedPreferences prefs;
  Function(String)? onDownloadStarted;

  List<DownloadItem> get downloads => _downloads;

  DownloadProvider({required this.prefs});

  String get downloadPath {
    return prefs.getString('download_path') ?? '';
  }

  Future<void> setDownloadPath(String path) async {
    await prefs.setString('download_path', path);
    notifyListeners();
  }

  Future<String> _getDownloadDir() async {
    final custom = prefs.getString('download_path');
    if (custom != null && custom.isNotEmpty) {
      final dir = Directory(custom);
      if (await dir.exists()) return custom;
    }
    // Fallback to app's download directory
    final appDir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${appDir.path}/Downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir.path;
  }

  Future<void> startDownload(String url) async {
    final uri = Uri.parse(url);
    final fileName =
        uri.pathSegments.isNotEmpty
            ? uri.pathSegments.last
            : 'download_${DateTime.now().millisecondsSinceEpoch}';

    final item = DownloadItem(url: url, fileName: fileName);
    _downloads.insert(0, item);
    notifyListeners();

    onDownloadStarted?.call(fileName);

    try {
      final downloadDir = await _getDownloadDir();
      final filePath = '$downloadDir/$fileName';
      item.savePath = filePath;

      // Step 1: Check if server supports Accept-Ranges and get content length
      final headResponse = await http.head(uri);
      bool supportRanges = false;
      int contentLength = 0;

      if (headResponse.statusCode >= 200 && headResponse.statusCode < 400) {
        if (headResponse.headers['accept-ranges']?.toLowerCase() == 'bytes') {
          supportRanges = true;
        }
        if (headResponse.headers.containsKey('content-length')) {
          contentLength =
              int.tryParse(headResponse.headers['content-length']!) ?? 0;
        }
      }

      // Retry with GET if HEAD doesn't return headers correctly
      if (contentLength == 0) {
        final getRequest = http.Request('GET', uri);
        final getResponse = await http.Client().send(getRequest);
        contentLength = getResponse.contentLength ?? 0;
        if (getResponse.headers['accept-ranges']?.toLowerCase() == 'bytes') {
          supportRanges = true;
        }

        // If it doesn't support ranges or we don't have total size, fallback to single stream
        if (!supportRanges || contentLength <= 0) {
          await _downloadSingleThread(
            item,
            getResponse,
            filePath,
            contentLength,
          );
          return;
        }
      }

      // Determine threads based on size
      int threads = 1;
      if (supportRanges && contentLength > 0) {
        if (contentLength >= 1024 * 1024 * 50) {
          threads = 8; // > 50MB -> 8 threads
        } else if (contentLength >= 1024 * 1024 * 10) {
          threads = 4; // > 10MB -> 4 threads
        } else if (contentLength >= 1024 * 1024 * 2) {
          threads = 2; // > 2MB -> 2 threads
        }
      }

      item.totalBytes = contentLength;
      item.isMultiPart = threads > 1;
      item.activeThreads = threads;
      item.partProgress = List.filled(threads, 0.0);
      notifyListeners();

      if (threads == 1) {
        final getRequest = http.Request('GET', uri);
        final getResponse = await http.Client().send(getRequest);
        await _downloadSingleThread(item, getResponse, filePath, contentLength);
        return;
      }

      // Step 2: Calculate chunks
      final chunkSize = (contentLength / threads).ceil();
      final List<Future<String>> downloadFutures = [];
      final List<int> downloadedPerThread = List.filled(threads, 0);

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < threads; i++) {
        final start = i * chunkSize;
        final end =
            (i == threads - 1) ? contentLength - 1 : (start + chunkSize - 1);
        final partFile = '$filePath.part$i';

        downloadFutures.add(
          _downloadChunk(
            url: uri,
            start: start,
            end: end,
            savePath: partFile,
            onProgress: (received) {
              downloadedPerThread[i] = received;
              final totalDownloaded = downloadedPerThread.reduce(
                (a, b) => a + b,
              );
              item.partProgress[i] = received / (end - start + 1);
              _updateProgress(item, totalDownloaded, contentLength, stopwatch);
            },
          ),
        );
      }

      // Wait for all threads to finish
      final partFiles = await Future.wait(downloadFutures);

      // Step 3: Merge files
      item.status = 'merging';
      item.speed = '';
      item.eta = '';
      notifyListeners();

      final outputFile = File(filePath);
      final outputSink = outputFile.openWrite();

      for (final partPath in partFiles) {
        final partFile = File(partPath);
        if (await partFile.exists()) {
          await outputSink.addStream(partFile.openRead());
          await partFile.delete(); // cleanup part
        }
      }
      await outputSink.close();

      item.status = 'completed';
      item.progress = 1.0;
      item.activeThreads = 0;
      notifyListeners();
    } catch (e) {
      item.status = 'failed';
      item.activeThreads = 0;
      notifyListeners();
    }
  }

  Future<String> _downloadChunk({
    required Uri url,
    required int start,
    required int end,
    required String savePath,
    required Function(int) onProgress,
  }) async {
    final request = http.Request('GET', url);
    request.headers['Range'] = 'bytes=$start-$end';

    final response = await http.Client().send(request);
    final file = File(savePath);
    final sink = file.openWrite();

    int received = 0;
    await for (final chunk in response.stream) {
      sink.add(chunk);
      received += chunk.length;
      onProgress(received);
    }

    await sink.close();
    return savePath;
  }

  Future<void> _downloadSingleThread(
    DownloadItem item,
    http.StreamedResponse response,
    String filePath,
    int totalSize,
  ) async {
    item.totalBytes = totalSize;
    item.activeThreads = 1;
    item.isMultiPart = false;
    notifyListeners();

    final file = File(filePath);
    final sink = file.openWrite();
    int received = 0;
    final stopwatch = Stopwatch()..start();

    try {
      await response.stream.listen((chunk) {
        sink.add(chunk);
        received += chunk.length;
        _updateProgress(item, received, totalSize, stopwatch);
      }).asFuture();

      await sink.close();
      item.status = 'completed';
      item.progress = 1.0;
      item.activeThreads = 0;
      notifyListeners();
    } catch (e) {
      await sink.close();
      item.status = 'failed';
      item.activeThreads = 0;
      notifyListeners();
      rethrow;
    }
  }

  void _updateProgress(
    DownloadItem item,
    int downloaded,
    int total,
    Stopwatch stopwatch,
  ) {
    item.downloadedBytes = downloaded;
    if (total > 0) {
      item.progress = downloaded / total;
    }

    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed > 500) {
      // Only update stats every 500ms to avoid UI flutter
      final bytesPerSec = (downloaded / elapsed) * 1000;

      // Speed formats
      if (bytesPerSec > 1024 * 1024) {
        item.speed = '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
      } else if (bytesPerSec > 1024) {
        item.speed = '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
      } else {
        item.speed = '${bytesPerSec.toStringAsFixed(0)} B/s';
      }

      // ETA calculation
      if (bytesPerSec > 0 && total > 0) {
        final remainingBytes = total - downloaded;
        final remainingSeconds = remainingBytes / bytesPerSec;
        if (remainingSeconds < 60) {
          item.eta = '${remainingSeconds.toStringAsFixed(0)} s';
        } else if (remainingSeconds < 3600) {
          final m = (remainingSeconds / 60).floor();
          final s = (remainingSeconds % 60).floor();
          item.eta = '${m}m ${s}s';
        } else {
          final h = (remainingSeconds / 3600).floor();
          final m = ((remainingSeconds % 3600) / 60).floor();
          item.eta = '${h}h ${m}m';
        }
      }
    }
    notifyListeners();
  }

  void removeDownload(int index) {
    if (index >= 0 && index < _downloads.length) {
      _downloads.removeAt(index);
      notifyListeners();
    }
  }
}
