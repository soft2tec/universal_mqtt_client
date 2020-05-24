@TestOn('vm')

import 'dart:io';

import 'package:test/test.dart';
import 'package:universal_mqtt_client/universal_mqtt_client.dart';

import '../util/broker.dart';
import '../util/broker_vm.dart';

void main() {
  Process broker1;
  Process broker2;
  UniversalMqttClient broker1Server1;
  UniversalMqttClient broker1Server2;

  setUpAll(() async {
    broker1 = await startBroker('vm/broker1.conf');
    final broker1URI = brokerTCP(1884);
    broker1Server1 = UniversalMqttClient(broker: broker1URI);
    await broker1Server1.connect();
    broker1Server2 = UniversalMqttClient(broker: broker1URI);
    await broker1Server2.connect();
    broker2 = await startBroker('vm/broker2.conf');
  });

  tearDownAll(() async {
    broker1.kill();
    broker1Server1.disconnect();
    broker2.kill();
  });

  test('simple connect & disconnect tcp', () async {
    final client = UniversalMqttClient(
      broker: brokerTCP(1884),
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

  test('simple connect & disconnect ws', () async {
    final client = UniversalMqttClient(
      broker: brokerWS(9001),
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

  test('auth connect & disconnect tcp', () async {
    final client = UniversalMqttClient(
      broker: brokerTCP(1885),
      autoReconnect: false,
      username: username,
      password: password,
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

  test('auth connect & disconnect ws', () async {
    final client = UniversalMqttClient(
      broker: brokerWS(9002),
      autoReconnect: false,
      username: username,
      password: password,
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

  test('auth connect not authorized', () async {
    final client = UniversalMqttClient(
      broker: brokerTCP(1885),
      autoReconnect: false,
      username: username,
      password: 'wrong_password',
    );

    final tests = expectLater(
      client.status,
      emitsInOrder([
        UniversalMqttClientStatus.disconnected,
        UniversalMqttClientStatus.connecting,
        UniversalMqttClientStatus.disconnected,
      ]),
    );

    await expectLater(
      () => client.connect(),
      throwsA(predicate((e) =>
          e is UniversalMqttClientConnectException &&
          e.message == 'Not authorized.')),
    );

    await tests;

    await expectLater(
      client.status,
      emitsError(predicate((e) =>
          e is UniversalMqttClientConnectException &&
          e.message == 'Not authorized.')),
    );

    await client.disconnect();
  });

  test('reconnect tcp', () async {
    var broker3 = await startBroker('vm/broker3.conf');

    final client = UniversalMqttClient(
      broker: brokerTCP(1886),
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

    await Future.delayed(Duration(milliseconds: 200));

    broker3.kill();

    await Future.delayed(Duration(milliseconds: 200));

    broker3 = await startBroker('vm/broker3.conf');

    await tests2;

    final tests3 = expectLater(
      client.status.handleError((err) => print('err: $err')),
      emitsInOrder([
        UniversalMqttClientStatus.connected,
        UniversalMqttClientStatus.disconnected,
      ]),
    );

    broker3.kill();

    await tests3;
  });

  test('tcp timeout', () async {
    final client = UniversalMqttClient(
      broker: brokerTCP(1884),
      autoReconnect: false,
      timeout: Duration(microseconds: 1),
    );

    final tests = expectLater(
      client.status,
      emitsInOrder([
        UniversalMqttClientStatus.disconnected,
        UniversalMqttClientStatus.connecting,
        UniversalMqttClientStatus.disconnected,
      ]),
    );

    await expectLater(
      client.connect(),
      throwsA(predicate((e) =>
          e is UniversalMqttClientConnectException &&
          e.message == 'Connection timed out.')),
    );
    client.disconnect();

    await tests;

    await expectLater(
      client.connect(),
      throwsA(predicate((e) =>
          e is UniversalMqttClientConnectException &&
          e.message == 'Connection timed out.')),
    );
  });
}
