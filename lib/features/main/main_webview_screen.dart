import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MainWebviewScreen extends StatefulWidget {
  final WebViewController webViewController;
  const MainWebviewScreen({
    super.key,
    required this.webViewController,
  });

  @override
  State<MainWebviewScreen> createState() => _MainWebviewScreenState();
}

class _MainWebviewScreenState extends State<MainWebviewScreen> {
  Future<void> _onRefresh() async {
    widget.webViewController.reload();
  }

  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers = {
    Factory(() => EagerGestureRecognizer())
  };

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
          child: WebViewWidget(
            controller: widget.webViewController,
            gestureRecognizers: gestureRecognizers,
          ),
        ),
      ),
    );
  }
}
