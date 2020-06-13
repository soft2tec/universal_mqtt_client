import 'package:mqtt_client/mqtt_browser_client.dart';
import './mqtt_shared.dart';

class RawUniversalMqttClient extends MqttBrowserClient {
  /// Initializes a new instance of [RawUniversalMqttClient].
  /// The [server] hostname to connect to
  /// The [clientIdentifier] to use to connect with
  RawUniversalMqttClient(String server, String clientIdentifier)
      : super(server, clientIdentifier, maxConnectionAttempts: 1);

  void useTransport(UniversalMqttTransport transport) {
    switch (transport) {
      case UniversalMqttTransport.tcp:
        throw UniversalMqttClientError(
            'tcp transport is not supported on this platform');
        break;
      case UniversalMqttTransport.ws:
        websocketProtocols = ['mqtt'];
        break;
      case UniversalMqttTransport.wss:
        websocketProtocols = ['mqtt'];
        break;
      default:
        throw UniversalMqttClientError('Invalid transport: $transport');
    }
  }
}
