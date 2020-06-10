import 'package:test/test.dart';
import 'package:universal_mqtt_client/universal_mqtt_client.dart';
import 'package:uuid/uuid.dart';

import 'util/broker.dart';

void main() {
  Broker broker1;
  Broker broker2;

  setUpAll(() async {
    broker1 = await startBroker(tcpPort: 1884 + offset, wsPort: 9001 + offset);
    broker2 = await startBroker(
      tcpPort: 1885 + offset,
      wsPort: 9002 + offset,
      authEnabled: true,
    );
  });

  tearDownAll(() async {
    broker1.kill();
    broker2.kill();
  });

  test('simple connect & disconnect tcp', () async {
    final client = UniversalMqttClient(
      broker: broker1.tcp,
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
  }, testOn: 'vm');

  test('simple connect & disconnect ws', () async {
    final client = UniversalMqttClient(
      broker: broker1.ws,
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
      broker: broker2.tcp,
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
  }, testOn: 'vm');

  test('auth connect & disconnect ws', () async {
    final client = UniversalMqttClient(
      broker: broker2.ws,
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

  test('auth connect not authorized tcp', () async {
    final client = UniversalMqttClient(
      broker: broker2.tcp,
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
      client.connect(),
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
  }, testOn: 'vm');

  test('auth connect not authorized ws', () async {
    final client = UniversalMqttClient(
      broker: broker2.ws,
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
      client.connect(),
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
    var broker3 =
        await startBroker(tcpPort: 1886 + offset, wsPort: 9003 + offset);

    final client = UniversalMqttClient(
      broker: broker3.tcp,
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

    broker3 = await startBroker(tcpPort: 1886 + offset, wsPort: 9003 + offset);

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
  }, testOn: 'vm');

  test('reconnect ws', () async {
    var broker3 =
        await startBroker(tcpPort: 1886 + offset, wsPort: 9003 + offset);

    final client = UniversalMqttClient(
      broker: broker3.ws,
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

    broker3 = await startBroker(tcpPort: 1886 + offset, wsPort: 9003 + offset);

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

  test('timeout tcp', () async {
    final client = UniversalMqttClient(
      broker: broker1.tcp,
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
  }, testOn: 'vm');

  test('timeout ws', () async {
    final client = UniversalMqttClient(
      broker: broker1.ws,
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

  test('publish & subscribe tcp', () async {
    final id = Uuid().v4();
    final client = UniversalMqttClient(
      broker: broker1.tcp,
      autoReconnect: false,
    );
    await client.connect();
    final sender = UniversalMqttClient(
      broker: broker1.tcp,
      autoReconnect: false,
    );
    await sender.connect();

    final test = expectLater(
      client.handleString('$id/tcp', MqttQos.exactlyOnce),
      emitsInOrder(['Hello', 'World', '', null]),
    );

    sender.publishString('$id/tcp', 'Hello', MqttQos.exactlyOnce);
    sender.publishString('$id/tcp', 'World', MqttQos.exactlyOnce);
    sender.publishString('$id/tcp', '', MqttQos.exactlyOnce);

    await Future.delayed(Duration(milliseconds: 500));

    client.disconnect();
    sender.disconnect();

    await test;
  }, testOn: 'vm');

  test('publish & subscribe ws', () async {
    final id = Uuid().v4();
    final client = UniversalMqttClient(
      broker: broker1.ws,
      autoReconnect: false,
    );
    await client.connect();
    final sender = UniversalMqttClient(
      broker: broker1.ws,
      autoReconnect: false,
    );
    await sender.connect();

    final test = expectLater(
      client.handleString('$id/ws', MqttQos.exactlyOnce),
      emitsInOrder(['Hello', 'World', '', null]),
    );

    sender.publishString('$id/ws', 'Hello', MqttQos.exactlyOnce);
    sender.publishString('$id/ws', 'World', MqttQos.exactlyOnce);
    sender.publishString('$id/ws', '', MqttQos.exactlyOnce);

    await Future.delayed(Duration(milliseconds: 500));

    client.disconnect();
    sender.disconnect();

    await test;
  });

  test('broker uri must have a scheme', () {
    expect(
      () => UniversalMqttClient(
        broker: Uri(host: 'localhost', port: 1884),
        autoReconnect: false,
      ),
      throwsA(predicate((e) =>
          e is UniversalMqttClientError &&
          e.message == 'Broker Uri must have a scheme.')),
    );
  });

  test('broker uri must have a port', () {
    expect(
      () => UniversalMqttClient(
        broker: Uri.parse('tcp://localhost'),
        autoReconnect: false,
      ),
      throwsA(predicate((e) =>
          e is UniversalMqttClientError &&
          e.message == 'Broker Uri must have a port.')),
    );
  });
}
