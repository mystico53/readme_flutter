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

// Step 2: Implement the state class
class _IntroPageMainState extends State<IntroPageMain> {
  // keepng track on which page we're on
  final PageController _controller = PageController();

  // check if we're on last page
  bool onLastPage = false;
  bool onFirstPage = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(children: [
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
          ]),
      Container(
        alignment: Alignment(0, 0.6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            //skip
            onFirstPage
                ? GestureDetector(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return const MainScreen();
                      }));
                    },
                    child: Text('close'))
                : GestureDetector(
                    onTap: () {
                      _controller.previousPage(
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeIn);
                    },
                    child: Text('previous')),

            SmoothPageIndicator(controller: _controller, count: 3),

            //next or done
            onLastPage
                ? GestureDetector(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return const MainScreen();
                      }));
                    },
                    child: Text('done'))
                : GestureDetector(
                    onTap: () {
                      _controller.nextPage(
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeIn);
                    },
                    child: Text('next'))
          ],
        ),
      )
    ]));
  }
}
