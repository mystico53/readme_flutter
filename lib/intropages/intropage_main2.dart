import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:readme_app/intropages/intropage_1.dart';
import 'package:readme_app/intropages/intropage_2.dart';
import 'package:readme_app/intropages/intropage_3.dart';
import 'package:readme_app/views/main_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class IntroPageMain extends StatefulWidget {
  @override
  _IntroPageMainState createState() => _IntroPageMainState();
}

class _IntroPageMainState extends State<IntroPageMain> {
  final PageController _controller = PageController();

  bool onLastPage = false;
  bool onFirstPage = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                onFirstPage = (index == 0);
                onLastPage = (index == 2);
              });
            },
            children: [
              IntroPage1(),
              IntroPage2(),
              IntroPage3(),
            ],
          ),
          Container(
            alignment: Alignment(0, 0.9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                onFirstPage
                    ? GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Text('close'),
                      )
                    : GestureDetector(
                        onTap: () {
                          _controller.previousPage(
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeIn,
                          );
                        },
                        child: Text('previous'),
                      ),
                SmoothPageIndicator(controller: _controller, count: 3),
                onLastPage
                    ? GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Text('done'),
                      )
                    : GestureDetector(
                        onTap: () {
                          _controller.nextPage(
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeIn,
                          );
                        },
                        child: Text('next'),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
