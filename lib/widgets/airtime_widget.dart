// lib/widgets/airtime_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/audioplayer_viewmodel.dart';

class AirtimeWidget extends StatefulWidget {
  const AirtimeWidget({Key? key}) : super(key: key);

  @override
  _AirtimeWidgetState createState() => _AirtimeWidgetState();
}

class _AirtimeWidgetState extends State<AirtimeWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayerViewModel = Provider.of<AudioPlayerViewModel>(context);
    final formattedDuration = audioPlayerViewModel
        .formatDuration(audioPlayerViewModel.totalTimePlayed);

    return Text(
      formattedDuration,
      style: const TextStyle(
        color: Color(0xFFFFEFC3),
        fontSize: 20,
      ),
    );
  }
}
