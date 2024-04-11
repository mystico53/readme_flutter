import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPage extends StatefulWidget {
  final String url;

  const WebViewPage({Key? key, required this.url}) : super(key: key);

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  String _textContent = '';

  @override
  void initState() {
    super.initState();
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
            var paragraphs = document.querySelectorAll('p');
            var text = "";
            for (var i = 0; i < paragraphs.length; i++) {
              text += paragraphs[i].innerText + "\\n\\n";
            }
            return text;
          } catch (error) {
            console.error("JavaScript error:", error);
            return "";
          }
        })();
      ''') as String;
      setState(() {
        _textContent = textContent;
      });
      print('Text Content:');
      print(textContent);
    } catch (error) {
      print('Error scraping text content: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebView'),
      ),
      body: Column(
        children: [
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
