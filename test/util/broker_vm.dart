import 'dart:io';

Future<Process> startBroker(String config) async {
  final broker = await Process.start(
    'mosquitto',
    ['-c', config],
    workingDirectory: 'test',
    mode: ProcessStartMode.normal,
  );
  await Future.delayed(Duration(milliseconds: 500));
  return broker;
}
