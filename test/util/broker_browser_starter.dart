import 'package:stream_channel/stream_channel.dart';

import '../util/broker_vm.dart';

void hybridMain(StreamChannel channel) async {
  final stream = channel.stream.asBroadcastStream();
  final broker = await startBroker(await stream.first);

  await Future.delayed(Duration(milliseconds: 1000));

  channel.sink.add(null);

  await stream.first;

  broker.kill();

  await Future.delayed(Duration(milliseconds: 500));
}
