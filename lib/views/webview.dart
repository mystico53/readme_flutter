import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:readme_app/utils/app_config.dart';
import 'package:readme_app/view_models/audioplayer_viewmodel.dart';
import 'package:readme_app/widgets/voice_selection_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../view_models/generate_dialog_viewmodel.dart';
import '../models/voice_model.dart';
import '../view_models/user_id_viewmodel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';

const String mobileUserAgent =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Mobile/15E148 Safari/604.1';

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
  bool _isLoading = true;
  bool _isCreating = false;

  final Color customColor = const Color(0xFF4B473D);

  void _handleCreateLisme() {
    setState(() {
      _isCreating = true;
    });

    Timer(const Duration(milliseconds: 1500), () {
      final generateDialogViewModel =
          Provider.of<GenerateDialogViewModel>(context, listen: false);
      final userId =
          Provider.of<UserIdViewModel>(context, listen: false).userId;

      generateDialogViewModel.generateAndCheckAudio(
        _textContent,
        generateDialogViewModel.currentSelectedVoice,
        userId,
      );

      Navigator.of(context).pop(); // Close the WebView
    });
  }

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

    _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        final redirectUrl =
            uri.toString().replaceFirst('lismeapp://', 'https://');
        _controller.loadRequest(Uri.parse(redirectUrl));
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final userId = Provider.of<UserIdViewModel>(context, listen: false).userId;
    _generateDialogViewModel = GenerateDialogViewModel(
        userId, Provider.of<AudioPlayerViewModel>(context, listen: false));

    _initializeWebView();
    initAppLinks();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setUserAgent(mobileUserAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (WebResourceError error) {
            print("Web Resource Error: ${error.description}");
          },
          onNavigationRequest: (NavigationRequest request) async {
            final modifiedUrl = _modifyRedirectUrl(request.url);
            if (modifiedUrl.contains('focus.de') ||
                _shouldHandleInWebView(modifiedUrl)) {
              _handleUrlInWebView(modifiedUrl);
              return NavigationDecision.prevent;
            }
            await _launchInBrowser(modifiedUrl);
            return NavigationDecision.prevent;
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            _scrapeTextContent();
            _injectAntiAntiFramingScript();
            _setMobileViewport();
            _adjustContentToFit();
          },
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100.0;
            });
          },
        ),
      )
      ..addJavaScriptChannel(
        'Flutter',
        onMessageReceived: (JavaScriptMessage message) {
          print('JavaScript message: ${message.message}');
        },
      );

    _loadUrl(widget.url);
  }

  void _setMobileViewport() {
    const script = '''
    var meta = document.querySelector('meta[name="viewport"]');
    if (!meta) {
      meta = document.createElement('meta');
      meta.name = 'viewport';
      document.head.appendChild(meta);
    }
    meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
  ''';
    _controller.runJavaScript(script);
  }

  void _adjustContentToFit() {
    const script = '''
    function adjustContent() {
      document.body.style.width = '100vw';
      document.body.style.overflowX = 'hidden';
      var elements = document.body.getElementsByTagName("*");
      for (var i = 0; i < elements.length; i++) {
        if (elements[i].offsetWidth > document.body.offsetWidth) {
          elements[i].style.maxWidth = '100%';
          elements[i].style.overflowX = 'auto';
        }
      }
    }
    adjustContent();
    window.addEventListener('resize', adjustContent);
  ''';
    _controller.runJavaScript(script);
  }

  bool _shouldHandleInWebView(String url) {
    // Add logic here to determine if the URL should be handled in WebView
    return false; // Default to false, change as needed
  }

  Future<void> _loadUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final content = response.body;
        await _controller.loadHtmlString(content, baseUrl: url);
      } else {
        print('Failed to load URL: ${response.statusCode}');
        await _controller.loadRequest(Uri.parse(url));
      }
    } catch (e) {
      print('Error loading URL: $e');
      await _controller.loadRequest(Uri.parse(url));
    }
  }

  void _handleUrlInWebView(String url) {
    _loadUrl(url);
  }

  void _injectAntiAntiFramingScript() {
    const script = '''
      // Anti-anti-framing script
      Object.defineProperty(window, 'top', {
        get: function() { return window; }
      });
      Object.defineProperty(window, 'parent', {
        get: function() { return window; }
      });
      function neutralizeFrameBusting() {
        if (window.location !== window.top.location) {
          window.top.location = window.location;
        }
      }
      ['isSecureContext', 'isLocalhost'].forEach(function(prop) {
        Object.defineProperty(window, prop, {
          get: function() { return true; }
        });
      });
      var meta = document.createElement('meta');
      meta.httpEquiv = 'X-Frame-Options';
      meta.content = 'ALLOWALL';
      document.getElementsByTagName('head')[0].appendChild(meta);
      neutralizeFrameBusting();
      Flutter.postMessage('Anti-anti-framing script injected');
    ''';

    _controller.runJavaScript(script);
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

      String cleanedTextContent = _formatText(textContent);

      setState(() {
        _textContent = cleanedTextContent;
        _isLoading = false;
      });

      print('Text Content:');
      print(cleanedTextContent);
    } catch (error) {
      print('Error scraping text content: $error');
    }
  }

  String _formatText(String text) {
    String formattedText = text.replaceAll('\\\\n', '\n');
    formattedText = formattedText.replaceAll('\\\\t', '\t');
    return formattedText;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isCreating,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: customColor,
          iconTheme: const IconThemeData(color: Color(0xFFFFEFC3)),
          title: const Text(
            'Convert to Speech',
            style: TextStyle(
              color: Color(0xFFFFEFC3),
            ),
          ),
        ),
        body: Column(
          children: [
            if (_isLoading)
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: customColor,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFFFEFC3)),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 2,
                      color: Colors.black,
                    ),
                  ),
                  child: WebViewWidget(
                    controller: _controller,
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          color: const Color(0xFFFFEFC3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Tooltip(
                message: 'Choose a voice for text-to-speech conversion',
                preferBelow: false,
                child: VoiceSelectionWidget(
                  onSelectedVoiceChanged: (VoiceModel voice) {
                    print("Updating selected voice to: ${voice.name}");
                    Provider.of<GenerateDialogViewModel>(context, listen: false)
                        .updateSelectedVoice(voice);
                  },
                ),
              ),
              ElevatedButton(
                onPressed:
                    (_isLoading || _isCreating) ? null : _handleCreateLisme,
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all(const Color(0xFF4B473D)),
                  foregroundColor:
                      MaterialStateProperty.all(const Color(0xFFFFEFC3)),
                  elevation: MaterialStateProperty.all(0),
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: const BorderSide(
                      color: Color(0xFF4B473D),
                      width: 1,
                    ),
                  )),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                child: Text(
                  _isLoading
                      ? 'Loading...'
                      : (_isCreating ? 'Creating...' : 'Create Lisme'),
                  style: const TextStyle(
                    color: Color(0xFFFFEFC3),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
