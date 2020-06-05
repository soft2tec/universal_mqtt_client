final username = 'bob';
final password = '1JOHN!';
Uri brokerTCP(int port) => Uri.parse('tcp://localhost:$port');
Uri brokerWS(int port) => Uri.parse('ws://localhost:$port/mqtt');
