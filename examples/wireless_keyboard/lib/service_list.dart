import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/io.dart';

import 'app_service.dart';
import 'discovery.dart';
import 'package:web_socket_channel/status.dart' as status;

import 'globals.dart';

/// Allows to display all discovered services.
class ServiceList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    BonsoirDiscoveryModel model = ref.watch(discoveryModelProvider);
    List<ResolvedBonsoirService> discoveredServices = model.discoveredServices;
    if (discoveredServices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Found no service of type "${AppService.type}".',
            style: TextStyle(
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
        itemCount: discoveredServices.length,
        itemBuilder: (BuildContext context, int index) {
          return ItemWidget(service: discoveredServices[index]);
        });
  }
}

/// Allows to display a discovered service.
/// class ItemWidget extends StatefulWidget {
class ItemWidget extends StatefulWidget {
  final ResolvedBonsoirService service;
  const ItemWidget({super.key, required this.service});

  @override
  State<ItemWidget> createState() => ItemWidgetState();
}

class ItemWidgetState extends State<ItemWidget> {
  IOWebSocketChannel? _channel;
  String _connectAction = 'Connect';
  bool _connected = false;

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: ListTile(
              title: Text(widget.service.name),
              subtitle: Text('IP : ${widget.service.ip}, Port: 4000'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _connect('${widget.service.ip}:4000');
            },
            child: Text(_connectAction),
          ),
        ],
      ),
    );
  }
}
