import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peripheral/globals.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

import 'scanner_screen.dart';
import 'service_list.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Peripheral',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Peripheral Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _sendController = TextEditingController();
  IOWebSocketChannel? _channel;
  String _connectAction = 'Connect';
  bool _connected = false;
  final List<String> keys = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '0',
    'Q',
    'W',
    'E',
    'R',
    'T',
    'Y',
    'U',
    'I',
    'O',
    'P',
    'A',
    'S',
    'D',
    'F',
    'G',
    'H',
    'J',
    'K',
    'L',
    'Z',
    'X',
    'C',
    'V',
    'B',
    'N',
    'M',
  ];

  @override
  void initState() {
    super.initState();
  }

  void _launchCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ScannerScreen()),
    );
  }

  void _connect(String msg) {
    if (_connected) {
      print('disconnect to $msg');
      _channel!.sink.close(status.goingAway);
      channels.remove(_channel!);
      _connected = false;
      _connectAction = 'Connect';
      setState(() {});
      return;
    }

    _channel = IOWebSocketChannel.connect('ws://$msg');

    _channel!.ready.then((_) {
      channels.add(_channel!);
      print('connected to $msg');
      _connected = true;
      _connectAction = 'Disconnect';
      setState(() {});
      _channel!.stream.listen((message) {
        print('received: $message');
      }, onError: (error) {
        print('error: $error');
      }, onDone: () {
        if (_channel!.closeCode != null) {
          print('WebSocket is closed with code: ${_channel!.closeCode}');
        } else {
          print('WebSocket is closed');
        }
        _connected = false;
        _connectAction = 'Connect';
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    if (_channel != null) {
      _channel!.sink.close(status.goingAway);
      channels.remove(_channel!);
    }
    super.dispose();
  }

  _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                          hintText: 'Enter the server IP address'),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _connect(_textController.text);
                    },
                    child: Text(_connectAction),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 100.0,
                child: ServiceList(),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: <Widget>[
                  Row(
                    children: keys.sublist(0, 9).map((key) {
                      return Expanded(
                          child: Row(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 9 - 6,
                            height: 40.0,
                            child: MaterialButton(
                              color: Colors.blue,
                              child: Text(
                                key,
                                style: const TextStyle(
                                    fontSize: 10.0, color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              onPressed: () {
                                sendMessage(key);
                              },
                            ),
                          ),
                          const SizedBox(width: 2),
                        ],
                      ));
                    }).toList(),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: keys.sublist(9, 18).map((key) {
                      return Expanded(
                          child: Row(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 9 - 6,
                            height: 40.0,
                            child: MaterialButton(
                              color: Colors.blue,
                              child: Text(
                                key,
                                style: const TextStyle(
                                    fontSize: 10.0, color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              onPressed: () {
                                sendMessage(key);
                              },
                            ),
                          ),
                          const SizedBox(width: 2),
                        ],
                      ));
                    }).toList(),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: keys.sublist(18, 27).map((key) {
                      return Expanded(
                          child: Row(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 9 - 6,
                            height: 40.0,
                            child: MaterialButton(
                              color: Colors.blue,
                              child: Text(
                                key,
                                style: const TextStyle(
                                    fontSize: 10.0, color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              onPressed: () {
                                sendMessage(key);
                              },
                            ),
                          ),
                          const SizedBox(width: 2),
                        ],
                      ));
                    }).toList(),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: keys.sublist(27, keys.length).map((key) {
                      return Expanded(
                          child: Row(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width / 9 - 6,
                            height: 40.0,
                            child: MaterialButton(
                              color: Colors.blue,
                              child: Text(
                                key,
                                style: const TextStyle(
                                    fontSize: 10.0, color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              onPressed: () {
                                sendMessage(key);
                              },
                            ),
                          ),
                          const SizedBox(width: 2),
                        ],
                      ));
                    }).toList(),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      SizedBox(
                          width: 40.0,
                          height: 40.0,
                          child: IconButton(
                            icon: const Icon(Icons.keyboard_backspace),
                            color: Colors.blue,
                            iconSize: 24.0,
                            onPressed: () {
                              sendMessage('backspace');
                            },
                          )),
                      SizedBox(
                          width: 40.0,
                          height: 40.0,
                          child: IconButton(
                            icon: const Icon(Icons.keyboard_return),
                            color: Colors.blue,
                            iconSize: 24.0,
                            onPressed: () {
                              sendMessage('enter');
                            },
                          )),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: 100,
                  width: MediaQuery.of(context).size.width * 2 / 3,
                  child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _sendController,
                              decoration: const InputDecoration(
                                  hintText: 'Input the message'),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              sendMessage(_sendController.text);
                              _sendController.clear();
                            },
                            child: const Text('Send'),
                          ),
                        ],
                      )),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _launchCamera,
        tooltip: 'Barcode Scanner',
        child: const Icon(Icons.camera),
      ),
    );
  }
}
