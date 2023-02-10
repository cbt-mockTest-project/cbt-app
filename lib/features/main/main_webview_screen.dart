import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MainWebviewScreen extends StatelessWidget {
  final WebViewController webViewController;

  const MainWebviewScreen({super.key, required this.webViewController});
  Future<void> _onRefresh() async {
    webViewController.reload();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        child: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: WebViewWidget(controller: webViewController)),
      ),
    );
  }
}
