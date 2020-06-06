import 'package:meta/meta.dart';

class Broker {
  final int tcpPort;
  final int wsPort;
  final Function kill;

  Broker({@required this.tcpPort, @required this.wsPort, @required this.kill});

  Uri get tcp => Uri.parse('tcp://localhost:$tcpPort');
  Uri get ws => Uri.parse('ws://localhost:$wsPort');
}
