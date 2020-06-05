import 'package:test/test.dart';
import 'package:universal_mqtt_client/universal_mqtt_client.dart';

void main() {
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
