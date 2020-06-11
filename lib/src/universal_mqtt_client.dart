import 'dart:typed_data';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:rxdart/rxdart.dart';

import './mqtt_shared.dart';
import 'mqtt_vm.dart' if (dart.library.html) 'mqtt_browser.dart';

export 'package:mqtt_client/mqtt_client.dart' show MqttQos;
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

final _uuid = Uuid();

/// A mqtt client that works in DartVM and browsers. It has auto reconnect and timeout
/// capabilities built in.
///
/// The protocols supported vary depending on platform. In DartVM `tcp`, `ws` and `wss`
/// are supported, while the browser only supports `ws` and `wss`.
///
/// The mqtt client id that is used is a randomly generated UUID and can not be changed.
///
/// The auto reconnect capabilites work as follows: on a non fatal error, like a timeout,
/// or connection error a reconnect attempt will be made, a maximum of every three seconds.
/// If the error is fatal (e.g. a wrong username or password), no further reconnect attempts
/// will be made. You can force a reconnet attempt by calling the [connect] method.
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
/// mqtt.brokerStatus.listen((message) => print("Status: $message");
/// await mqtt.connect();
/// await mqtt.publishString("my/topic", "hello world", MqttQos.exactlyOnce);
/// mqtt.handleString("my/other/topic").listen((message) => print("Received message: $message"));
/// ```
class UniversalMqttClient {
  RawUniversalMqttClient _mqtt;

  final String _username;
  final String _password;

  /// The [timeout] determines the amount of time to wait after trying to connect and not
  /// recieving a response to declare the connection unsuccessful.
  final Duration timeout;

  /// The [autoReconnect] determines if automatic reconnection is enabled. The details of
  /// what this entails can be found in the documentation for the [UniversalMqttClient] class.
  final bool autoReconnect;

  DateTime _lastConnectAttempt;
  bool _stopReconnect = false;

  /// Returns true if both [autoReconnect] is enabled, and if the previous disconnection was
  /// not caused by a fatal error or a manual [disconnect].
  bool get tryingToReconnect => autoReconnect && !_stopReconnect;

  final Map<String, BehaviorSubject<Uint8List>> _subscriptions = {};

  final _brokerStatus = BehaviorSubject<UniversalMqttClientStatus>.seeded(
    UniversalMqttClientStatus.disconnected,
  );

  /// This is the current status of the connection.
  ///
  /// When an error occurs during disconnection, first a [UniversalMqttClientStatus.disconnected]
  /// is emitted, and then the error is emmited. The error is always emitted after the
  /// [UniversalMqttClientStatus.disconnected] message.
  ValueStream<UniversalMqttClientStatus> get status => _brokerStatus.stream;

  /// Creates a new [UniversalMqttClient] with the specified options.
  ///
  /// The [broker] must have a valid [Uri.scheme] (`tcp`, `ws` and `wss` for DartVM, `ws`
  /// and `wss` for the browser). If this is not the case, a [UniversalMqttClientError] will
  /// be thrown. The [Uri.port] must also be set as there is not default port. If this is
  /// not the case a [UniversalMqttClientError] will be thrown.
  ///
  /// The [username] and [password] should be set to [null] if there is no authentication,
  /// otherwise they can be set to a [String].
  ///
  /// The [autoReconnect] flag can be set to enable automatic reconnection. The details of
  /// what this entails can be found in the documentation for the [UniversalMqttClient] class.
  ///
  /// The [timeout] determines the amount of time to wait after trying to connect and not
  /// recieving a response to declare the connection unsuccessful.
  UniversalMqttClient({
    @required final Uri broker,
    final String username,
    final String password,
    this.autoReconnect = true,
    this.timeout = const Duration(seconds: 5),
  })  : _username = username,
        _password = password {
    if (!broker.hasScheme) {
      throw UniversalMqttClientError('Broker Uri must have a scheme.');
    }
    if (!broker.hasPort) {
      throw UniversalMqttClientError('Broker Uri must have a port.');
    }

    _mqtt = RawUniversalMqttClient('', '${_uuid.v4()}');
    _mqtt.keepAlivePeriod = 5;
    _mqtt.port = broker.port;
    if (broker.isScheme('tcp')) {
      _mqtt.server = broker.host;
      _mqtt.useTransport(UniversalMqttTransport.tcp);
    } else if (broker.isScheme('ws')) {
      _mqtt.server = '${broker.scheme}://${broker.host}';
      _mqtt.useTransport(UniversalMqttTransport.ws);
    } else if (broker.isScheme('wss')) {
      _mqtt.server = '${broker.scheme}://${broker.host}';
      _mqtt.useTransport(UniversalMqttTransport.wss);
    }

    _mqtt.onDisconnected = () async {
      _brokerStatus.add(UniversalMqttClientStatus.disconnected);
      _subscriptions.forEach((topic, sink) => sink.add(null));
      if (autoReconnect) {
        if (_stopReconnect) return;
        if (_lastConnectAttempt != null) {
          final diff = DateTime.now().difference(_lastConnectAttempt);
          if (diff.inMilliseconds < 3000) {
            await Future.delayed(Duration(
              milliseconds: 3000 - diff.inMilliseconds,
            ));
          }
        }
        if (_mqtt.connectionStatus.state == MqttConnectionState.disconnected &&
            !_stopReconnect) {
          await connect().catchError((err) {});
        }
      }
    };
  }

  /// Tries to connect to the specified broker. If the connection is successful the returned
  /// promise resolves. Otherwise the returned promise rejcts with the connection error.
  Future<void> connect() async {
    try {
      _stopReconnect = false;
      _brokerStatus.add(UniversalMqttClientStatus.connecting);
      _lastConnectAttempt = DateTime.now();
      await _mqtt.connect(_username, _password).catchError((e) {}).timeout(
        timeout,
        onTimeout: () async {
          _mqtt.disconnect();
          throw UniversalMqttClientConnectException('Connection timed out.');
        },
      );
      switch (_mqtt.connectionStatus.returnCode) {
        case MqttConnectReturnCode.connectionAccepted:
          break;
        case MqttConnectReturnCode.badUsernameOrPassword:
          throw UniversalMqttClientConnectException(
            'Bad username or password.',
            fatal: true,
          );
          break;
        case MqttConnectReturnCode.brokerUnavailable:
          throw UniversalMqttClientConnectException('Broker unavailable.');
          break;
        case MqttConnectReturnCode.identifierRejected:
          throw UniversalMqttClientConnectException(
            'Identifier rejected.',
            fatal: true,
          );
          break;
        case MqttConnectReturnCode.notAuthorized:
          throw UniversalMqttClientConnectException(
            'Not authorized.',
            fatal: true,
          );
          break;
        case MqttConnectReturnCode.unacceptedProtocolVersion:
          throw UniversalMqttClientConnectException(
            "Broker didn't accept protocol version.",
            fatal: true,
          );
          break;
        default:
          throw UniversalMqttClientConnectException(
              'Unknown connection error.');
      }
      _brokerStatus.add(UniversalMqttClientStatus.connected);
      _subscriptions.forEach((topic, _) {
        _mqtt.subscribe(topic, MqttQos.atLeastOnce);
      });
      _mqtt.updates.listen((messages) {
        messages.forEach((message) {
          if (_subscriptions[message.topic] != null) {
            final MqttPublishMessage publishMessage = message.payload;
            _subscriptions[message.topic]
                .add(publishMessage.payload.message.buffer.asUint8List());
          }
        });
      });
    } on UniversalMqttClientConnectException catch (err) {
      if (err.fatal) {
        _stopReconnect = true;
      }
      _mqtt.disconnect();
      await _brokerStatus.firstWhere(
          (element) => element == UniversalMqttClientStatus.disconnected);
      _brokerStatus.addError(err);
      rethrow;
    } catch (err) {
      _mqtt.disconnect();
      await _brokerStatus.firstWhere(
          (element) => element == UniversalMqttClientStatus.disconnected);
      _brokerStatus.addError(err);
      rethrow;
    }
  }

  /// When this method is called the connection is synchrounously closed and automatic
  /// reconnection is stopped. Calling connect restarts automatic reconnection if it is
  /// enabled.
  void disconnect() {
    _stopReconnect = true;
    _mqtt.disconnect();
  }

  void _createSubscription(String topic, MqttQos qos) {
    _subscriptions[topic] = BehaviorSubject<Uint8List>();
    _subscriptions[topic].doOnCancel(() {
      if (!_subscriptions[topic].hasListener) {
        _mqtt.unsubscribe(topic);
        _subscriptions[topic].close();
        _subscriptions.remove(topic);
      }
    });
    final subscription = _mqtt.subscribe(topic, qos);
    if (subscription == null) {
      throw UniversalMqttClientException(
          'Failed to subscribe to topic "$topic" with qos "$qos"');
    }
  }

  Stream<Uint8List> _handle(String topic, MqttQos qos) {
    if (_subscriptions[topic] == null) {
      _createSubscription(topic, qos);
    }
    return _subscriptions[topic].stream;
  }

  /// Returns a stream of messages from the specified topic as strings. The specified
  /// topic is automatically subscribed to.
  ///
  /// On disconnect from the broker a `null` message is emitted. If applicable the handling
  /// is automatically resumed once a connection to the broker has been reestablishd.
  ///
  /// Cancelling the stream stops the mqtt subscription.
  Stream<String> handleString(String topic, MqttQos qos) {
    return _handle(topic, qos)
        .map((data) => data == null ? null : String.fromCharCodes(data));
  }

  /// Publish a string message to the specified topic with the specified QOS.
  void publishString(String topic, String value, MqttQos qos) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(value);
    _mqtt.publishMessage(topic, qos, builder.payload);
  }
}
