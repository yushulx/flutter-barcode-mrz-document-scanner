import 'package:web_socket_channel/io.dart';

Set<IOWebSocketChannel> channels = {};

void sendMessage(String msg) {
  if (channels.isEmpty) {
    return;
  }

  for (final channel in channels) {
    channel.sink.add(msg);
  }
}
