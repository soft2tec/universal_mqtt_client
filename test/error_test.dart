import 'package:test/test.dart';
import 'package:universal_mqtt_client/universal_mqtt_client.dart';

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

  test('invalid topic error', () {
    final message = 'hello world';
    final error = InvalidTopicError(message);
    expect(error.toString(), equals('InvalidTopicError: $message'));
  });
}
