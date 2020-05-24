@TestOn('browser')

import 'package:test/test.dart';
import 'package:universal_mqtt_client/universal_mqtt_client.dart';

import '../util/broker.dart';
import '../util/broker_browser.dart';

void main() {
  test('simple connect ws', () async {
    final broker1 = await startBroker('browser/broker1.conf');
    addTearDown(() => broker1.kill());

    final client = UniversalMqttClient(
      broker: brokerWS(9011),
      autoReconnect: false,
    );

    final tests = expectLater(
      client.status,
      emitsInOrder([
        UniversalMqttClientStatus.disconnected,
        UniversalMqttClientStatus.connecting,
        UniversalMqttClientStatus.connected,
        UniversalMqttClientStatus.disconnected,
      ]),
    );

    await client.connect();
    client.disconnect();

    await tests;
  });

  test('reconnect ws', () async {
    var broker3 = await startBroker('browser/broker3.conf');

    final client = UniversalMqttClient(
      broker: brokerWS(9013),
      autoReconnect: true,
    );

    final tests = expectLater(
      client.status,
      emitsInOrder([
        UniversalMqttClientStatus.disconnected,
        UniversalMqttClientStatus.connecting,
        UniversalMqttClientStatus.connected,
      ]),
    );

    await client.connect();

    await tests;

    final tests2 = expectLater(
      client.status,
      emitsInOrder([
        UniversalMqttClientStatus.connected,
        UniversalMqttClientStatus.disconnected,
        UniversalMqttClientStatus.connecting,
        UniversalMqttClientStatus.connected,
      ]),
    );

    await broker3.kill();

    await Future.delayed(Duration(milliseconds: 200));

    broker3 = await startBroker('browser/broker3.conf');

    await tests2;

    final tests3 = expectLater(
      client.status,
      emitsInOrder([
        UniversalMqttClientStatus.connected,
        UniversalMqttClientStatus.disconnected,
      ]),
    );

    await broker3.kill();

    await tests3;
  });
}
