import 'package:flutter/material.dart';
import 'package:readme_app/intropages/intropage_howto.dart';

class IntroPageMain extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IntropageHowto(),
        ],
      ),
    );
  }
}
