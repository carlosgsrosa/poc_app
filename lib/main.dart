import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo Application',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: "Einstein's POC"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isOffline = false;
  Color _connectionStatusColor = Colors.red;
  final Connectivity _connectivity = Connectivity();
  String _connectionStatus = "SEM CONEXAO";
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

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
      setState(() {
        _connectionStatus = "Wifi";
      });
      setState(() {
        _connectionStatusColor = Colors.green;
      });
    } else if (result == ConnectivityResult.mobile) {
      setState(() {
        _connectionStatus = "Mobile";
      });
      setState(() {
        _connectionStatusColor = Colors.green;
      });
    } else {
      setState(() {
        _connectionStatus = 'SEM CONEXAO';
      });
      setState(() {
        _connectionStatusColor = Colors.red;
      });
    }

    if (result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi) {
      showStatus(result, true);
    } else {
      showStatus(result, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: Text(
        'Connection Status: ${_connectionStatus}',
        style: TextStyle(color: _connectionStatusColor),
      )),
    );
  }
}
