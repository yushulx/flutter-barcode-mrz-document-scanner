import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_sdk/dynamsoft_barcode.dart';
import 'package:share_plus/share_plus.dart';

import 'global.dart';

class BarcodeResultPage extends StatefulWidget {
  const BarcodeResultPage({super.key, required this.barcodeResults});

  final List<BarcodeResult> barcodeResults;

  @override
  State<BarcodeResultPage> createState() => _BarcodeResultPageState();
}

class _BarcodeResultPageState extends State<BarcodeResultPage> {
  void close() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const valueStyle = TextStyle(color: Colors.white, fontSize: 14);
    var count = Container(
      padding: const EdgeInsets.only(left: 16, top: 14, bottom: 15),
      decoration: const BoxDecoration(color: Colors.black),
      child: Row(
        children: [
          const Text('Total: ', style: valueStyle),
          Text('${widget.barcodeResults.length}',
              style: TextStyle(color: colorGreen, fontSize: 14))
        ],
      ),
    );
    final resultList = Expanded(
        child: ListView.builder(
            itemCount: widget.barcodeResults.length,
            itemBuilder: (context, index) {
              return MyCustomWidget(
                index: index,
                result: widget.barcodeResults[index],
              );
            }));

    return PopScope(
        canPop: true,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: colorMainTheme,
            title: const Text(
              'Results',
              style: TextStyle(color: Colors.white),
            ),
            iconTheme: const IconThemeData(
              color: Colors
                  .white, // Set the color of the back arrow and other icons
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: IconButton(
                  onPressed: () {
                    String result = '';
                    for (BarcodeResult barcodeResult in widget.barcodeResults) {
                      result +=
                          'Format: ${barcodeResult.format}, Text: ${barcodeResult.text}\n';
                    }
                    Share.share(result);
                  },
                  icon: const Icon(Icons.share, color: Colors.white),
                ),
              )
            ],
          ),
          body: Column(
            children: [
              count,
              resultList,
              Expanded(
                child: Container(),
              ),
            ],
          ),
        ));
  }
}

class MyCustomWidget extends StatelessWidget {
  final BarcodeResult result;
  final int index;

  const MyCustomWidget({
    super.key,
    required this.index,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
        decoration: const BoxDecoration(color: Colors.black),
        child: Padding(
            padding:
                const EdgeInsets.only(top: 13, bottom: 14, left: 20, right: 19),
            child: Row(
              children: [
                Text(
                  '${index + 1}',
                  style: TextStyle(color: colorGreen, fontSize: 14),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Format: ${result.format}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          overflow: TextOverflow.ellipsis),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 110,
                      child: Text(
                        'Text: ${result.text}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
                Expanded(child: Container()),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(
                        text:
                            'Format: ${result.format}, Text: ${result.text}'));
                  },
                  child: Text('Copy',
                      style: TextStyle(color: colorGreen, fontSize: 14)),
                ),
              ],
            )));
  }
}
