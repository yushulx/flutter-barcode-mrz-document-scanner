import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_sdk/dynamsoft_barcode.dart';
import 'global.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _isLoaded = false;
  final List<BarcodeResult> _barcodeHistory =
      List<BarcodeResult>.empty(growable: true);
  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var data = prefs.getStringList('barcode_data');
    if (data != null) {
      _barcodeHistory.clear();
      for (String json in data) {
        BarcodeResult barcodeResult = BarcodeResult.fromJson(jsonDecode(json));
        _barcodeHistory.add(barcodeResult);
      }
    }
    setState(() {
      _isLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    var listView = Expanded(
        child: ListView.builder(
            itemCount: _barcodeHistory.length,
            itemBuilder: (context, index) {
              return MyCustomWidget(
                  result: _barcodeHistory[index],
                  cbDeleted: () async {
                    _barcodeHistory.removeAt(index);
                    final SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    List<String> data =
                        prefs.getStringList('barcode_data') as List<String>;
                    data.removeAt(index);
                    prefs.setStringList('barcode_data', data);
                    setState(() {});
                  },
                  cbOpenResultPage: () {});
            }));
    return Scaffold(
      appBar: AppBar(
        title: Text('History',
            style: TextStyle(
              fontSize: 22,
              color: colorTitle,
            )),
        centerTitle: true,
        backgroundColor: colorMainTheme,
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 30),
              child: IconButton(
                onPressed: () async {
                  final SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.remove('barcode_data');
                  setState(() {
                    _barcodeHistory.clear();
                  });
                },
                icon: Image.asset(
                  "images/icon-delete.png",
                  width: 26,
                  height: 26,
                  fit: BoxFit.cover,
                ),
              ))
        ],
      ),
      body: _isLoaded
          ? Column(
              children: [listView],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

class MyCustomWidget extends StatelessWidget {
  final BarcodeResult result;
  final Function cbDeleted;
  final Function cbOpenResultPage;

  const MyCustomWidget({
    super.key,
    required this.result,
    required this.cbDeleted,
    required this.cbOpenResultPage,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
        decoration: const BoxDecoration(color: Colors.black),
        child: Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 16, left: 30),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.format,
                      style: const TextStyle(color: Colors.white),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 105,
                      child: Text(
                        result.text,
                        style: TextStyle(
                            color: colorSubtitle,
                            fontSize: 14,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
                Expanded(child: Container()),
                Padding(
                  padding: const EdgeInsets.only(right: 0),
                  child: IconButton(
                    icon: const Icon(Icons.more_vert),
                    color: Colors.white,
                    onPressed: () async {
                      final RenderBox button =
                          context.findRenderObject() as RenderBox;

                      final RelativeRect position = RelativeRect.fromLTRB(
                        100,
                        button.localToGlobal(Offset.zero).dy,
                        40,
                        0,
                      );

                      final selected = await showMenu(
                        context: context,
                        position: position,
                        color: colorBackground,
                        items: [
                          const PopupMenuItem<int>(
                              value: 0,
                              child: Text(
                                'Delete',
                                style: TextStyle(color: Colors.white),
                              )),
                          const PopupMenuItem<int>(
                              value: 1,
                              child: Text(
                                'Copy',
                                style: TextStyle(color: Colors.white),
                              )),
                        ],
                      );

                      if (selected != null) {
                        if (selected == 0) {
                          // delete
                          cbDeleted();
                        } else if (selected == 1) {
                          // copy
                          Clipboard.setData(ClipboardData(
                              text:
                                  'Format: ${result.format}, Text: ${result.text}'));
                        }
                      }
                    },
                  ),
                ),
              ],
            )));
  }
}
