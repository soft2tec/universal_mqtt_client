# universal_mqtt_client

[![Pub Version](https://img.shields.io/pub/v/universal_mqtt_client)](https://pub.dev/packages/universal_mqtt_client)

A MQTT client for Dart that works on any Dart supported compile target (including
Flutter and Flutter Web).

## Features

- Full support for MQTT 3.3.1
- Support for MQTT over WebSocket on all Dart compile targets (including web)
- Support for MQTT over TCP on mobile and desktop
- Dart idiomatic API using promises and streams
- Built in reconnect functionality
- Full support for wildcard topics

## Usage

```dart
/// To use this example you need to have a WebSocket `mqtt` server
/// running on localhost:9000.

import 'package:universal_mqtt_client/universal_mqtt_client.dart';

void main() async {
  // Create a new UniversalMqttClient. This does not start the connection yet.
  final client = UniversalMqttClient(broker: Uri.parse('ws://localhost:9000'));
  client.status.listen((status) {
    print('Connection Status: $status');
  });

  // We now call `client.connect()` to establish a connection with the MQTT broker.
  // The returned promise resolves when the connection is successful, a timeout
  // has been reached, or the broker responds with an error.
  await client.connect();

  // We now subscribe to the client and save the returned StreamSubscription
  final subscription = client
      .handleString('device_status/1', MqttQos.atLeastOnce)
      .listen((message) => print('Device 1 Status: $message'));

  // then publish a message to the topic we subscribed to.
  client.publishString(
      'device_status/1', 'Connected and running!', MqttQos.atLeastOnce);

  // Then we wait a bit before we cancel our subscription.
  await Future.delayed(Duration(seconds: 2));

  // Now we can cancel our subscription. This means that any messages after this will
  // not be recieved by the client anymore.
  await subscription.cancel();

  // Ultimatly we clean up our connection by disconnecting from the broker.
  client.disconnect();
}
```

## Bugs and feature requests

Please file feature requests and bugs at the [issue tracker][tracker]. If you find any security
related issues, please follow the guidance in the `SECURITY.md` file. Thanks :-)

[tracker]: https://github.com/soft2tec/universal_mqtt_client

## Licence

This project is licensed under the MIT licence. More information can be found in the `LICENCE` file.
