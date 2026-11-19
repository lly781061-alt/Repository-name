import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SunbulaApp());
}

class SunbulaApp extends StatelessWidget {
  const SunbulaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'السنبلة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B2A4A)),
        useMaterial3: true,
      ),
      home: const SunbulaWebViewPage(),
    );
  }
}

class SunbulaWebViewPage extends StatefulWidget {
  const SunbulaWebViewPage({super.key});

  @override
  State<SunbulaWebViewPage> createState() => _SunbulaWebViewPageState();
}

class _SunbulaWebViewPageState extends State<SunbulaWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF4F6F8))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (error) {
            if (error.errorCode == -10 || error.description.contains('ERR_CACHE_MISS')) {
              return;
            }
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = error.description;
              });
            }
          },
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      androidController.setOnShowFileSelector((params) async {
        return [];
      });
    }

    _controller = controller;
    _loadLocalHtml();
  }

  Future<void> _loadLocalHtml() async {
    try {
      final htmlContent = await rootBundle.loadString('index.html');
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/sunbula_index.html');
      await file.writeAsString(htmlContent, flush: true);
      await _controller.loadFile(file.path);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'تعذر تحميل index.html: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        body: SafeArea(
          child: Stack(
            children: [
              if (_errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                WebViewWidget(controller: _controller),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
