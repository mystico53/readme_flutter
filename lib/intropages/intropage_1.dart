import 'package:flutter/material.dart';

class IntroPage1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Lisme can only read text\nthat you have selected',
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
                'assets/images/introslides/Intro1.png',
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
