// ignore_for_file: prefer_const_constructors, use_key_in_widget_constructors

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
            'Time to get your feet wet!\n\n Try it with the text below.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(8), // Add padding around the text
            color: Color(0xFFF0EAD6), // Eggshell background color
            child: SelectableText(
              'Step 1. Select ANY word in this textbox.\nStep 2. Press "Select all."\nStep 3. Share with Lisme.\n\nCongratulations. You just learned how to create your first Lisme. Now try it with another text from your phone',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
              ),
            ),
          )
        ],
      ),
    );
  }
}
