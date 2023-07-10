import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:moducbt/features/main/main_splash_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:bootpay_webview_flutter/bootpay_webview_flutter.dart';

List<String> mobileUserAgents = [
  // 모바일 User-Agent 문자열 리스트
  'Mozilla/5.0 (Linux; Android 11; SM-G970F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.181 Mobile Safari/537.36',
  'Mozilla/5.0 (Linux; Android 10; Pixel 4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Mobile Safari/537.36',
];

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final WebViewController controller;
  final InAppReview inAppReview = InAppReview.instance;
  DateTime? currentBackPressTime;
  bool isLoading = true;
  static const _platformChannel = MethodChannel('com.example.webview_intents');
  Future<void> _handleIntent(String intentUrl) async {
    try {
      final bool result =
          await _platformChannel.invokeMethod('launchIntent', intentUrl);
      if (!result) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('인텐트를 실행할 수 없습니다.')));
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('오류: ${e.message}')));
    }
  }

  PackageInfo _packageInfo = PackageInfo(
    appName: '',
    packageName: '',
    version: '',
    buildNumber: '',
    buildSignature: '',
    installerStore: '',
  );

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    bool checkAllowUrl({required String url}) {
      final List<String> allowUrls = [
        'http://172.30.1.9',
        'https://www.moducbt.com/',
        'https://moducbt.com/',
        'https://api.moducbt.com/',
        'https://kauth.kakao.com/',
        'https://accounts.kakao.com/',
        'https://logins.daum.net/',
        'https://accounts.google.com/',
        'https://accounts.google.co.kr/',
      ];
      return allowUrls.any((e) {
        return url.startsWith(e);
      });
    }

    String randomUserAgent() {
      return mobileUserAgents[Random().nextInt(mobileUserAgents.length)];
    }

    controller = WebViewController()
      ..setUserAgent(randomUserAgent())
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
            if (request.url.startsWith('intent://')) {
              try {
                _handleIntent(request.url);
                return NavigationDecision.prevent;
              } catch (e) {
                debugPrint('Error launching KakaoTalk app: $e');
              }
              return NavigationDecision.prevent;
            }
            if (request.url.startsWith('kakaotalk://inappbrowser')) {
              final url = Uri.parse(request.url);
              await launchUrl(url);
              return NavigationDecision.prevent;
            }
            if (request.url.startsWith('https://accounts.google.com/')) {
              controller.setUserAgent('random');
            } else {
              controller.setUserAgent(randomUserAgent());
            }
            if (checkAllowUrl(url: request.url)) {
              return NavigationDecision.navigate;
            }
            final url = Uri.parse(request.url);
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
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
      ..addJavaScriptChannel(
        'PackageInfo',
        onMessageReceived: (JavaScriptMessage message) async {
          if (message.message == "getPackageInfo") {
            final packageInfo = {
              "appName": _packageInfo.appName,
              "version": _packageInfo.version,
              "buildNumber": _packageInfo.buildNumber,
            };
            String packageInfoJson = jsonEncode(packageInfo);
            controller.runJavaScript('window.appInfoChanged($packageInfoJson)');
          }
        },
      )
      ..addJavaScriptChannel('fileChooser',
          onMessageReceived: (JavaScriptMessage message) async {
        final ImagePicker _picker = ImagePicker();
        final XFile? imageFile =
            await _picker.pickImage(source: ImageSource.gallery);
        if (imageFile != null) {
          final Uint8List bytes = await imageFile.readAsBytes();
          final String base64 = base64Encode(bytes.buffer.asUint8List());
          controller.runJavaScript('window.uploadFile("$base64")');
        }
      })
      ..loadRequest(Uri.parse('http://172.30.1.9:3000/exam/write'));

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
  }

  Future<bool> _onWillPop() async {
    DateTime now = DateTime.now();
    if (await controller.canGoBack()) {
      await controller.goBack();
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        child: Scaffold(
            backgroundColor: Colors.white,
            body: isLoading
                ? const SplashScreen()
                : WebViewWidget(controller: controller)),
      ),
    );
  }
}
