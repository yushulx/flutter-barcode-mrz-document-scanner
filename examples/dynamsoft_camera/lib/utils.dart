import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'scan_provider.dart';

Widget createURLString(String text) {
  // Create a regular expression to match URL strings.
  RegExp urlRegExp = RegExp(
    r'^(https?|http)://[^\s/$.?#].[^\s]*$',
    caseSensitive: false,
    multiLine: false,
  );

  if (urlRegExp.hasMatch(text)) {
    return InkWell(
      onLongPress: () {
        Share.share(text, subject: 'Scan Result');
      },
      child: Text(
        text,
        style: const TextStyle(color: Colors.blue),
      ),
      onTap: () async {
        launchUrlString(text);
      },
    );
  } else {
    return InkWell(
      onLongPress: () async {
        Share.share(text, subject: 'Scan Result');
      },
      child: Text(text),
    );
  }
}

Widget createListView(BuildContext context) {
  ScanProvider scanProvider = Provider.of<ScanProvider>(context);
  return ListView.builder(
      itemCount: scanProvider.results.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: createURLString(
              scanProvider.results.values.elementAt(index).text),
          subtitle:
              Text(scanProvider.results.values.elementAt(index).formatString),
        );
      });
}
