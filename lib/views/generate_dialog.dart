import 'package:flutter/material.dart';

class GenerateDialog extends StatefulWidget {
  const GenerateDialog({super.key});

  @override
  GenerateDialogState createState() => GenerateDialogState();
}

class GenerateDialogState extends State<GenerateDialog> {
  // Add your state variables here if needed

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text("Custom Sized Modal",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            const Text(
                "This modal is slightly smaller than the full screen, allowing the background to be visible."),
            // Add more widgets as needed
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
