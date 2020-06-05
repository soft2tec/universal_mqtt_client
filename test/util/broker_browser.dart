import 'dart:async';

import 'package:test/test.dart';

Future<Broker> startBroker(String config) async {
  final channel = await spawnHybridUri('../util/broker_browser_starter.dart',
      message: config);
  channel.sink.add(config);
  await channel.stream.first;
  return Broker(channel.sink);
}

class Broker {
  final StreamSink _sink;

  Broker(this._sink);

  void kill() {
    _sink.add(null);
  }
}
