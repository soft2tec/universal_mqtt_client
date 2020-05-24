import 'package:test/test.dart';
import 'package:universal_mqtt_client/src/mqtt_shared.dart';

void main() {
  test('universal mqtt client exception', () {
    final message = 'hello world';
    final exception = UniversalMqttClientException(message);
    expect(
        exception.toString(), equals('UniversalMqttClientException: $message'));
  });
  test('universal mqtt client connect error', () {
    final message = 'hello world';
    final exception = UniversalMqttClientConnectException(message);
    expect(exception.toString(),
        equals('UniversalMqttClientConnectException: $message'));
  });
  test('universal mqtt client error', () {
    final message = 'hello world';
    final error = UniversalMqttClientError(message);
    expect(error.toString(), equals('UniversalMqttClientError: $message'));
  });
}
