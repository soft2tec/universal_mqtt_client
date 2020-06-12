import 'package:mqtt_client/mqtt_server_client.dart';
import './mqtt_shared.dart';

class RawUniversalMqttClient extends MqttServerClient {
  /// Initializes a new instance of [RawUniversalMqttClient].
  /// The [server] hostname to connect to
  /// The [clientIdentifier] to use to connect with
  RawUniversalMqttClient(String server, String clientIdentifier)
      : super(server, clientIdentifier, maxConnectionAttempts: 1);

  void useTransport(UniversalMqttTransport transport) {
    switch (transport) {
      case UniversalMqttTransport.tcp:
        useWebSocket = false;
        break;
      case UniversalMqttTransport.ws:
        useWebSocket = true;
        break;
      case UniversalMqttTransport.wss:
        useWebSocket = true;
        break;
      default:
        throw UniversalMqttClientError('Invalid transport: $transport');
    }
  }
}
