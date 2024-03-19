import 'package:flutter/material.dart';

class IntroPage3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Try "Select All", Lisme will remove any clutter',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          FractionallySizedBox(
            widthFactor: 1.0,
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.asset(
                'assets/images/introslides/Intro3.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
