import 'package:flutter/material.dart';
import 'scan_provider.dart';
import 'package:provider/provider.dart';

import 'utils.dart';

class HistoryView extends StatelessWidget {
  final String title;

  const HistoryView({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    ScanProvider scanProvider = Provider.of<ScanProvider>(context);
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                scanProvider.clearResults();
              },
            ),
          ],
        ),
        body: Center(
          child: Stack(
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
            ],
          ),
        ));
  }
}
