import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/browser_provider.dart';
import '../providers/download_provider.dart';
import '../widgets/chrome_top_bar.dart';
import '../widgets/new_tab_page.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  bool _callbackSet = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_callbackSet) {
      _callbackSet = true;
      final downloadProvider = context.read<DownloadProvider>();
      final browserProvider = context.read<BrowserProvider>();

      // Wire up download interception
      browserProvider.onDownloadRequested = (url) {
        downloadProvider.startDownload(url);
      };

      downloadProvider.onDownloadStarted = (fileName) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.downloading, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Downloading $fileName',
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF323232),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      };
    }
  }

  bool _isNewTabPage(String url) {
    return url == 'about:blank' || url.isEmpty || url == 'about:blank#blocked';
  }

  @override
  Widget build(BuildContext context) {
    final browserProvider = context.watch<BrowserProvider>();
    final activeTab = browserProvider.activeTab;

    if (activeTab == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final showNewTabPage = _isNewTabPage(activeTab.url);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (activeTab.canGoBack) {
          await activeTab.webViewController.goBack();
        }
        // If can't go back, stay in app (don't exit)
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Top App Bar
              const ChromeTopBar(),

              // Progress bar
              if (!showNewTabPage && activeTab.progress < 1.0)
                LinearProgressIndicator(
                  value: activeTab.progress,
                  color: Colors.blueAccent,
                  backgroundColor: Colors.transparent,
                  minHeight: 2,
                )
              else
                const SizedBox(height: 2),

              // Content: NewTabPage or WebView
              Expanded(
                child:
                    showNewTabPage
                        ? const NewTabPage()
                        : WebViewWidget(
                          controller: activeTab.webViewController,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
