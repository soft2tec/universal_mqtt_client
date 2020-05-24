enum UniversalMqttTransport {
  tcp,
  ws,
  wss,
}

class UniversalMqttClientError extends Error {
  final String message;
  UniversalMqttClientError(this.message);
  @override
  String toString() {
    return 'UniversalMqttClientError: $message';
  }
}

class UniversalMqttClientException implements Exception {
  final String message;
  UniversalMqttClientException(this.message);
  @override
  String toString() {
    return 'UniversalMqttClientException: $message';
  }
}

class UniversalMqttClientConnectException extends UniversalMqttClientException {
  final bool fatal;
  UniversalMqttClientConnectException(String message, {this.fatal = false})
      : super(message);
  @override
  String toString() {
    return 'UniversalMqttClientConnectException: $message' +
        (fatal ? ' (fatal)' : '');
  }
}

/// The current status of a [UniversalMqttClient].
enum UniversalMqttClientStatus {
  /// The status when [UniversalMqttClient] is in the process of connection
  /// establishment with the broker.
  connecting,

  /// The status when [UniversalMqttClient] is connected to the broker.
  connected,

  /// The status when [UniversalMqttClient] is disconnected from the broker.
  disconnected
}
