/// [universal_mqtt_client] is a mqtt package that transparently works with any
/// Dart supported compile target. This means it supports all targets for Flutter
/// (mobile, desktop and web), and all Dart targets (web and vm).
///
/// It supports `tcp` and `ws` (WebSocket) transports.
///
/// Here is an example of creating a client, connecting to it, listening to its current
/// connection status, publishing a message and subscribing to a topic:
/// ```
/// final uri = Uri.parse("tcp://localhost:1883")
/// final mqtt = UniversalMqttClient(
///   broker: uri,
///   username: "john",
///   password: "***",
///   autoReconnect: true,
///   timeout: Duration(seconds: 2),
/// );
/// mqtt.status.listen((message) => print("Status: $message");
/// await mqtt.connect();
/// await mqtt.publishString("my/topic", "hello world", MqttQos.exactlyOnce);
/// mqtt.handleString("my/other/topic").listen((message) => print("Received message: $message"));
/// ```
///
/// There are more examples in the `examples` direcotry of this package.
library universal_mqtt_client;

export 'src/universal_mqtt_client.dart';
export 'src/mqtt_shared.dart' hide UniversalMqttTransport;
export 'src/topics.dart' show InvalidTopicError;
