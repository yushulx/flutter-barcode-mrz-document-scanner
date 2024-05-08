import 'package:flutter/material.dart';

import 'utils.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Scan Results'),
          actions: [
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Close'))
          ],
        ),
        body: Stack(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height -
                  200 -
                  MediaQuery.of(context).padding.top,
              child: createListView(context),
            ),
            Positioned(
                bottom: 50,
                left: 50,
                right: 50,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('SCAN AGAIN'),
                  ),
                ))
          ],
        ));
  }
}
