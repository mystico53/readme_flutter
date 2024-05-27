import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:readme_app/utils/app_config.dart';
import 'package:readme_app/widgets/voice_selection_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../view_models/generate_dialog_viewmodel.dart';
import '../models/voice_model.dart';
import '../view_models/user_id_viewmodel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';

class WebViewPage extends StatefulWidget {
  final String url;

  const WebViewPage({Key? key, required this.url}) : super(key: key);

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  String _textContent = '';
  late final GenerateDialogViewModel _generateDialogViewModel;
  double _progress = 0.0;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  String _modifyRedirectUrl(String url) {
    final uri = Uri.parse(url);
    final redirectUri = uri.queryParameters['redirect_uri'];

    if (redirectUri != null) {
      final modifiedRedirectUri = Uri.encodeFull(
        'lismeapp://myaccount.nytimes.com/auth/google-login-callback',
      );
      final modifiedUri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          'redirect_uri': modifiedRedirectUri,
        },
      );
      return modifiedUri.toString();
    }

    return url;
  }

  Future<void> initAppLinks() async {
    _appLinks = AppLinks();

    // Listen for incoming URLs
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        // Extract the original redirect URL from the custom URL scheme
        final redirectUrl =
            uri.toString().replaceFirst('lismeapp://', 'https://');
        // Load the redirect URL in the WebView
        _controller.loadRequest(Uri.parse(redirectUrl));
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final userId = Provider.of<UserIdViewModel>(context, listen: false).userId;
    _generateDialogViewModel = GenerateDialogViewModel(userId);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (WebResourceError error) {
            // Handle SSL errors and other web resource errors
          },
          onNavigationRequest: (NavigationRequest request) async {
            final modifiedUrl = _modifyRedirectUrl(request.url);
            await _launchInBrowser(modifiedUrl);
            return NavigationDecision.prevent;
          },
          onPageFinished: (String url) {
            _scrapeTextContent();
          },
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100.0;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    initAppLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _launchInBrowser(String urlString) async {
    print("Launching URL: $urlString");
    final Uri url = Uri.parse(urlString);
    final LaunchMode mode = LaunchMode.externalApplication;

    print("Checking if the URL can be launched...");
    final bool webViewSupported = await canLaunchUrl(url);

    if (webViewSupported) {
      print("URL can be launched, proceeding with launchUrl...");
      await launchUrl(
        url,
        mode: mode,
      );
      print("URL launched successfully.");
    } else {
      print("Failed to launch URL: $urlString");
      throw 'Could not launch $urlString';
    }
  }

  void _scrapeTextContent() async {
    try {
      final String textContent =
          await _controller.runJavaScriptReturningResult('''
      (function() {
        try {
          return document.body.innerText;
        } catch (error) {
          console.error("JavaScript error:", error);
          return "";
        }
      })();
    ''') as String;

      setState(() {
        _textContent = textContent;
        print("now the text should appear in textbox");
      });

      print('Text Content:');
      print(textContent);
    } catch (error) {
      print('Error scraping text content: $error');
    }
  }

  String _formatText(String text) {
    String formattedText = text.replaceAll('\\n\\n', '\n\n');
    return formattedText;
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserIdViewModel>(context).userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('WebView'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.reload();
            },
          ),
          TextButton(
            onPressed: () {
              final generateDialogViewModel =
                  Provider.of<GenerateDialogViewModel>(context, listen: false);
              generateDialogViewModel.generateAndCheckAudio(
                _textContent,
                generateDialogViewModel.currentSelectedVoice,
                userId,
              );
              Navigator.pop(context);
            },
            child: const Text(
              'Confirm',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          VoiceSelectionWidget(
            onSelectedVoiceChanged: (VoiceModel voice) {
              print("Updating selected voice to: ${voice.name}");
              Provider.of<GenerateDialogViewModel>(context, listen: false)
                  .updateSelectedVoice(voice);
            },
          ),
          if (_progress < 1.0)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          Expanded(
            child: WebViewWidget(
              controller: _controller,
            ),
          ),
          if (_textContent.isNotEmpty)
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  _textContent,
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
