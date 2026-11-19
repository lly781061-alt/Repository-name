import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

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
    _controller = WebViewController()
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
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = error.description;
              });
            }
          },
        ),
      );
    _loadLocalHtml();
  }

  Future<void> _loadLocalHtml() async {
    try {
      final htmlContent = await rootBundle.loadString('index.html');
      final uri = Uri.dataFromString(
        htmlContent,
        mimeType: 'text/html',
        encoding: utf8,
      );
      await _controller.loadRequest(uri);
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
