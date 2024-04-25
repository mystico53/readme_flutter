import 'dart:async';

import 'package:flutter/material.dart';
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

  String _buildGoogleLoginUrl() {
    const String clientId =
        '699002329011-4uc0putjghn8rd05cvck6lh92l4jl8eq.apps.googleusercontent.com';
    const String redirectUri =
        'https://fir-readme-123.firebaseapp.com/oauth-callback.html';
    const String scope = 'email profile'; // Add any additional scopes you need
    const String responseType = 'code';

    final String url = 'https://accounts.google.com/o/oauth2/auth?'
        'client_id=$clientId&'
        'redirect_uri=$redirectUri&'
        'scope=$scope&'
        'response_type=$responseType';

    return url;
  }

  @override
  void initState() {
    super.initState();
    final userId = Provider.of<UserIdViewModel>(context, listen: false).userId;
    _generateDialogViewModel = GenerateDialogViewModel(userId);

    _controller = WebViewController()
      ..clearCache()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url))
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (WebResourceError error) {
            // Handle SSL errors and other web resource errors
          },
          onNavigationRequest: (NavigationRequest request) {
            //handle oauth logins
            if (request.url
                .startsWith("https://accounts.google.com/o/oauth2/auth")) {
              final googleLoginUrl = _buildGoogleLoginUrl();
              _launchInBrowser(googleLoginUrl); // Open in external browser
              return NavigationDecision.prevent; // Prevent loading in WebView
            }

            // Handle mixed content and other navigation requests
            return NavigationDecision.navigate;
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
      ..setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/93.0.4577.82 Safari/537.36',
      );

    initDeepLinks();
  }

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link if app was in cold state (terminated)
    final appLink = await _appLinks.getInitialAppLink();
    if (appLink != null) {
      print('getInitialAppLink: $appLink');
      _handleDeepLink(appLink);
    }

    // Handle link when app is in warm state (front or background)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      print('onAppLink: $uri');
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'lismeapp' && uri.host == 'oauth2callback') {
      final authorizationCode = uri.queryParameters['code'];
      // TODO: Use the authorization code to obtain an access token from the server
      print('Authorization Code: $authorizationCode');
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _launchInBrowser(String urlString) async {
    print("Launching URL: $urlString"); // Debug: Log the URL being launched
    final Uri url = Uri.parse(urlString);
    final LaunchMode mode = LaunchMode.externalApplication;

    print(
        "Checking if the URL can be launched..."); // Debug: Check URL launch capability
    final bool webViewSupported = await canLaunchUrl(url);

    if (webViewSupported) {
      print(
          "URL can be launched, proceeding with launchUrl..."); // Debug: Confirm URL is supported
      await launchUrl(
        url,
        mode: mode,
      );
      print(
          "URL launched successfully."); // Debug: Confirm URL has been launched
    } else {
      print("Failed to launch URL: $urlString"); // Debug: Log failure
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
        //_textContent = _formatText(textContent); replace /n/n with linebreaks
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
