import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:permission_handler/permission_handler.dart';

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
        title: "Connectivity / Events",
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
  String _connectionType = "None";
  String _connectionWifiName = "Unknown";
  Color _connectionStatusColor = Colors.red;

  final NetworkInfo _networkInfo = NetworkInfo();
  final Connectivity _connectivity = Connectivity();

  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();

    _initConnectivity();
    _initNetworkInfo();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _initNetworkInfo() async {
    String? wifiName;
    String? wifiSSID;

    try {
      if (Platform.isIOS) {
        var status = await _networkInfo.getLocationServiceAuthorization();
        if (status == LocationAuthorizationStatus.notDetermined) {
          status = await _networkInfo.requestLocationServiceAuthorization();
        }
        if (status == LocationAuthorizationStatus.authorizedAlways ||
            status == LocationAuthorizationStatus.authorizedWhenInUse) {
          wifiName = await _networkInfo.getWifiName();
        } else {
          wifiName = await _networkInfo.getWifiName();
        }
      } else {
        var status = await Permission.location.status;

        print("##### ANDROID permission $status");

        if (status.isLimited || status.isDenied || status.isRestricted) {
          if (await Permission.location.request().isGranted) {
            // Either the permission was already granted before or the user just granted it.
          }
        }

        wifiName = await _networkInfo.getWifiName();
        wifiSSID = await _networkInfo.getWifiBSSID();
      }
    } on PlatformException catch (e) {
      developer.log('Failed to get Wifi Name', error: e);
      wifiName = 'Failed to get Wifi Name';
    }

    print("#### NAME $wifiName - $wifiSSID");

    setState(() => _connectionWifiName = wifiName!);
  }

  Future<void> _sendAnalyticsEvent(
      String status, String type, String name) async {
    await widget.analytics.logEvent(
      name: 'connectivity_status',
      parameters: <String, dynamic>{
        'status': status,
        'type': type,
        'name': name,
      },
    );
  }

  Future<void> _initConnectivity() async {
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

  void _showStatus(ConnectivityResult result, bool status) {
    final textStatus = status ? 'ON LINE' : 'OFF LINE';
    final snackBar = SnackBar(
        content: Text(textStatus), backgroundColor: _connectionStatusColor);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    _initNetworkInfo();

    if (result == ConnectivityResult.wifi) {
      setState(() => _connectionType = "Wifi");
      setState(() => _connectionStatusColor = Colors.green);
    } else if (result == ConnectivityResult.mobile) {
      setState(() => _connectionType = "Mobile");
      setState(() => _connectionStatusColor = Colors.green);
    } else {
      setState(() => _connectionWifiName = "Unknown");
      setState(() => _connectionType = "None");
      setState(() => _connectionStatusColor = Colors.red);
    }

    if (result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi) {
      _showStatus(result, true);
      _sendAnalyticsEvent("ON LINE", _connectionType, _connectionWifiName);
    } else {
      _showStatus(result, false);
      _sendAnalyticsEvent("OFF LINE", _connectionType, _connectionWifiName);
    }
    developer.log("###### $_connectionType");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: Text(
        'Connection Status: $_connectionType - $_connectionWifiName',
        style: TextStyle(color: _connectionStatusColor),
      )),
    );
  }
}
