// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors

import 'package:flutter/material.dart';

class IntropageHowto extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFFFEFC3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FractionallySizedBox(
            widthFactor: 1.5, // Increased by 50%
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.asset(
                'assets/images/introslides/How to Lisme.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Share a news article with Lisme\nto turn it into a mini audiobook',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.normal,
            ),
          ),
          SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ButtonStyle(
              backgroundColor:
                  MaterialStateProperty.all(const Color(0xFFFFEFC3)),
              foregroundColor:
                  MaterialStateProperty.all(const Color(0xFF4B473D)),
              elevation: MaterialStateProperty.all(0),
              shape: MaterialStateProperty.all(RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: const BorderSide(
                  color: Color(0xFF4B473D),
                  width: 1,
                ),
              )),
              padding: MaterialStateProperty.all(const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              )),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
