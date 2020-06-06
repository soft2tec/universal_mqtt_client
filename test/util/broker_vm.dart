import 'dart:io';

import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';
import 'broker_shared.dart';

final offset = 0;

Future<Broker> startBroker({
  @required int tcpPort,
  @required int wsPort,
  bool authEnabled = false,
}) async {
  final dir = await Directory.systemTemp.createTemp();
  final id = Uuid().v4();
  final conf = await File('${dir.path}/${id}.conf');
  final pw = await File('${dir.path}/${id}.passwd').writeAsString(
      'bob:\$6\$KzDhoCl4wf6cLF5V\$kyskq7nSgQleaw+KEya5pUJ5kukPM2ap9UjOuhYA8YOH6EPru5UflkagdoghQyT11Qz0EQNLJV/GHIVWwPYGmQ==');

  await conf.writeAsString('''
port ${tcpPort}
allow_anonymous ${authEnabled ? "false" : "true"}
${authEnabled ? "password_file ${pw.path}" : ""}

listener ${wsPort}
protocol websockets''', flush: true);

  final broker = await Process.start(
    'mosquitto',
    ['-c', conf.path],
    workingDirectory: 'test',
    mode: ProcessStartMode.normal,
  );
  await Future.delayed(Duration(milliseconds: 1000));
  return Broker(kill: () => broker.kill(), tcpPort: tcpPort, wsPort: wsPort);
}
