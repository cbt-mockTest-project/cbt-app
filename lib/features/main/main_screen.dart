import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:moducbt/features/main/main_splash_screen.dart';
import 'package:moducbt/features/main/main_webview_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:share_plus/share_plus.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final WebViewController _controller;
  final InAppReview inAppReview = InAppReview.instance;
  DateTime? currentBackPressTime;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    bool checkAllowUrl({required String url}) {
      final List<String> allowUrls = [
        'https://www.moducbt.com/',
        'https://moducbt.com/',
        'https://api.moducbt.com/',
        'https://kauth.kakao.com/',
        'https://accounts.kakao.com/',
        'https://logins.daum.net/',
        'https://accounts.google.com/',
        'https://accounts.google.co.kr/'
      ];
      return allowUrls.any((e) {
        return url.startsWith(e);
      });
    }

    controller
      ..setUserAgent('random')
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() {
                isLoading = false;
              });
            }
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) async {
            debugPrint('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
              Page resource error:
                code: ${error.errorCode}
                description: ${error.description}
                errorType: ${error.errorType}
                isForMainFrame: ${error.isForMainFrame}
          ''');
          },
          onNavigationRequest: (NavigationRequest request) async {
            if (request.url.startsWith('https://accounts.google.com/')) {
              controller.setUserAgent('random');
            } else {
              controller.setUserAgent('');
            }
            if (checkAllowUrl(url: request.url)) {
              return NavigationDecision.navigate;
            }
            final url = Uri.parse(request.url);
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..addJavaScriptChannel(
        'Share',
        onMessageReceived: (JavaScriptMessage message) {
          Share.share(message.message);
        },
      )
      ..loadRequest(Uri.parse('http://172.30.1.3:3000'));

    if (controller.platform is AndroidWebViewController) {
      Share.share('https://moducbt.com/question/737');
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    _controller = controller;
  }

  Future<bool> _onWillPop() async {
    DateTime now = DateTime.now();
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('버튼을 한번 더 누르면 종료됩니다.'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }

    return true;
  }

  void _onTapAppBarText() {
    _controller.loadRequest(Uri.parse('https://moducbt.com'));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: isLoading
              ? const SplashScreen()
              : Stack(
                  children: [
                    Positioned(
                      child: MainWebviewScreen(
                        webViewController: _controller,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
