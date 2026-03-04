import 'package:webview_flutter/webview_flutter.dart';

class TabState {
  String url;
  String title;
  double progress;
  bool canGoBack;
  bool canGoForward;
  bool isIncognito;
  String? groupId;
  final WebViewController webViewController;

  TabState({
    required this.url,
    this.title = 'New Tab',
    this.progress = 0.0,
    this.canGoBack = false,
    this.canGoForward = false,
    this.isIncognito = false,
    this.groupId,
    required this.webViewController,
  });
}
