import 'package:meta/meta.dart';
import 'package:platform_detect/platform_detect.dart';
import 'package:test/test.dart';

import 'broker_shared.dart';

final offset = browser.isSafari ? 30 : browser.isFirefox ? 20 : 10;

Future<Broker> startBroker({
  @required int tcpPort,
  @required int wsPort,
  bool authEnabled = false,
}) async {
  final channel = await spawnHybridUri(
    './util/broker_browser_starter.dart',
    message: {
      'tcpPort': tcpPort,
      'wsPort': wsPort,
      'authEnabled': authEnabled,
    },
  );
  await channel.stream.first;
  return Broker(
      kill: () => channel.sink.add(null), tcpPort: tcpPort, wsPort: wsPort);
}
