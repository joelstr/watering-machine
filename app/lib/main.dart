import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() async {
  // client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
  //   final recMess = c![0].payload as MqttPublishMessage;
  //   final pt =
  //       MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

  //   /// The above may seem a little convoluted for users only interested in the
  //   /// payload, some users however may be interested in the received publish message,
  //   /// lets not constrain ourselves yet until the package has been in the wild
  //   /// for a while.
  //   /// The payload is a byte buffer, this will be specific to the topic
  //   _counter = int.parse(pt);
  //   print(
  //       'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
  //   print('');
  // });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Watering app',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Home of the plants'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _water = 0;
  final _client = MqttServerClient('mqtt.joelstrand.se', '');

  void _updateWater(int water) {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _water = water;
    });
  }

  void _onConnected() {
    _subscribe();
    print(
        'EXAMPLE::OnConnected client callback - Client connection was successful');
    _updateWater(0);
  }

  void _onDisconnected() {
    print("Disconnected");
    _updateWater(0);
  }

  void _connect() async {
    _client.setProtocolV311();
    _client.keepAlivePeriod = 20;
    _client.connectTimeoutPeriod = 2000; // milliseconds
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;

    final connMess = MqttConnectMessage()
        .withClientIdentifier('Mqtt_MyClientUniqueId')
        .withWillTopic(
            'willtopic') // If you set this you must set a will message
        .withWillMessage('My Will message')
        .startClean() // Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce)
        .authenticateAs("m5stack", "211221");
    print('EXAMPLE::Mosquitto client connecting....');
    _client.connectionMessage = connMess;

    /// Connect the client, any errors here are communicated by raising of the appropriate exception. Note
    /// in some circumstances the broker will just disconnect us, see the spec about this, we however will
    /// never send malformed messages.
    try {
      await _client.connect();
    } on NoConnectionException catch (e) {
      // Raised by the client when connection fails.
      print('EXAMPLE::client exception - $e');
      _client.disconnect();
    } on SocketException catch (e) {
      // Raised by the socket layer
      print('EXAMPLE::socket exception - $e');
      _client.disconnect();
    }
  }

  void _subscribe() {
    /// Ok, lets try a subscription
    print('EXAMPLE::Subscribing to the testTopic topic');
    const topic = 'testTopic'; // Not a wildcard topic
    _client.subscribe(topic, MqttQos.atMostOnce);

    _client.published!.listen((MqttPublishMessage message) {
      final pt =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);
      _updateWater(int.parse(pt));
      print(
          'EXAMPLE::Published notification:: topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}');
    });
  }

  void _disconnect() {
    _client.disconnect();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    /// Check we are connected
    final connected =
        _client.connectionStatus!.state == MqttConnectionState.connected;

    if (connected) {
      print('EXAMPLE::Mosquitto client connected');
    } else {
      /// Use status here rather than state if you also want the broker return code.
      print(
          'EXAMPLE::ERROR Mosquitto client connection failed - disconnecting, status is ${_client.connectionStatus}');
      _client.disconnect();
    }

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Your plant is this thirsty:',
            ),
            Text(
              '$_water',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: connected ? _disconnect : _connect,
        tooltip: connected ? 'Disconnect' : 'Connect',
        child: Icon(connected ? Icons.stop : Icons.play_arrow),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
