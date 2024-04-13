import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../view_models/generate_dialog_viewmodel.dart';
import '../models/voice_model.dart';
import '../view_models/user_id_viewmodel.dart';

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
