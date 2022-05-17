import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo Application',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
        title: "Einstein's POC",
        analytics: analytics,
        observer: observer,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
    required this.title,
    required this.analytics,
    required this.observer,
  }) : super(key: key);

  final String title;
  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _message = '';
  Color _connectionStatusColor = Colors.red;
  final Connectivity _connectivity = Connectivity();
  String _connectionStatus = "SEM CONEXAO";

  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  void setMessage(String message) {
    setState(() => _message = message);
  }

  Future<void> _sendAnalyticsEvent(String status, String type) async {
    await widget.analytics.logEvent(
      name: 'connectivity_status',
      parameters: <String, dynamic>{
        'string': 'string',
        'status': status,
        'type': type,
      },
    );
    setMessage('_sendAnalyticsEvent succeeded');
  }

  @override
  void initState() {
    super.initState();

    initConnectivity();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> initConnectivity() async {
    late ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException {
      return;
    }

    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  void showStatus(ConnectivityResult result, bool status) {
    final textStatus = status ? 'ONLINE' : 'OFFLINE';
    final snackBar = SnackBar(
        content: Text(textStatus), backgroundColor: _connectionStatusColor);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    if (result == ConnectivityResult.wifi) {
      setState(() => _connectionStatus = "Wifi");
      setState(() => _connectionStatusColor = Colors.green);
    } else if (result == ConnectivityResult.mobile) {
      setState(() => _connectionStatus = "Mobile");
      setState(() => _connectionStatusColor = Colors.green);
    } else {
      setState(() => _connectionStatus = "SEM CONEXÃO");
      setState(() => _connectionStatusColor = Colors.red);
    }

    if (result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi) {
      showStatus(result, true);
      _sendAnalyticsEvent("ON LINE", _connectionStatus);
    } else {
      showStatus(result, false);
      _sendAnalyticsEvent("OFF LINE", _connectionStatus);
    }
    print("###### ${_connectionStatus}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: Text(
        'Connection Status: $_connectionStatus',
        style: TextStyle(color: _connectionStatusColor),
      )),
    );
  }
}
