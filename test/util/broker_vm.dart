import 'dart:io';

Future<Process> startBroker(String config) async {
  final broker = await Process.start(
    'mosquitto',
    ['-c', config],
    workingDirectory: 'test',
    mode: ProcessStartMode.normal,
  );
  return broker;
}
