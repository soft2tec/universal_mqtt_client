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
