import 'dart:math';
import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:esense_flutter/esense.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:step_bpm/yt_page.dart';
import 'package:flutter/material.dart';


/////////////////////////////// ENTRY POINT ////////////////////////////////////

void main() => runApp(BPMPage());

//////////////////////// MEASURED DATA FOR YT PAGE /////////////////////////////

class Data {
  final int bpm;

  Data({@required this.bpm});
}

//////////////////////////// LOGIC FOR BPM PAGE  ///////////////////////////////

class BPMPage extends StatefulWidget {
  @override
  BPMState createState() => new BPMState();
}

class BPMState extends State<BPMPage> {
  String eSenseName = 'eSense-0176';
  FlutterBlue flutterBlue = FlutterBlue.instance;

  String _deviceStatus = "";
  bool sampling = false;

  String _event = "";
  int _accReadX = 0;
  int _accReadY = 0;
  int _accReadZ = 0;

  double _magnitude = 0;
  int _stepCount = 0;
  int _bpm = 0;

  Stopwatch stepCooldown = new Stopwatch();
  Stopwatch stopwatch = new Stopwatch();

  @override
  void initState() {
    super.initState();
    bleOn();
  }

  // Listener to check for changes in Bluetooth status
  // Prevents the app from crashing when opened without Bluetooth and allows
  // connecting to device while app is already opened
  void bleOn() async {
    flutterBlue.state.listen((event) async {
      if (await flutterBlue.isOn) {
        _connectToESense();
        return;
      }
      switch (event) {
        case BluetoothState.on:
          _connectToESense();
          break;
        case BluetoothState.off:
        // TODO
          break;
        case BluetoothState.turningOff:
          if (sampling) _pauseListenToSensorEvents();
          break;
        default:
        // do nothing
          break;
      }
    });
  }

  Future<void> _connectToESense() async {

    bool con = false;

    // if you want to get the connection events when connecting, set up the listener BEFORE connecting...
    ESenseManager.connectionEvents.listen((event) {
      print('CONNECTION event: $event');

      setState(() {
        switch (event.type) {
          case ConnectionType.connected:
            _deviceStatus = 'connected';
            break;
          case ConnectionType.unknown:
            _deviceStatus = 'unknown';
            break;
          case ConnectionType.disconnected:
            _deviceStatus = 'disconnected';
            break;
          case ConnectionType.device_found:
            _deviceStatus = 'device_found';
            break;
          case ConnectionType.device_not_found:
            _deviceStatus = 'device_not_found';
            break;
        }
      });
    });

    con = await ESenseManager.connect(eSenseName);
    setState(() {
      _deviceStatus = con ? 'connecting' : 'connection failed';
    });
  }

  void _resetMeasuredData() async {
    _accReadX = 0;
    _accReadY = 0;
    _accReadZ = 0;
    _magnitude = 0;
    _stepCount = 0;
    _bpm = 0;
    stopwatch.reset();
  }

  void _detectStep() async {
    if (stepCooldown.isRunning && stepCooldown.elapsedMilliseconds >= 320) {
      stepCooldown.stop();
      stepCooldown.reset();
    }
    if (!stepCooldown.isRunning && _magnitude >= 8700) {
      stepCooldown.start();
      _stepCount++;
    }
  }

  StreamSubscription subscription;
  void _startListenToSensorEvents() async {
    _resetMeasuredData();
    stopwatch.start();

    // subscribe to sensor event from the eSense device
    subscription = ESenseManager.sensorEvents.listen((event) {
      print('SENSOR event: $event');
      setState(() {
        _event = event.toString();
        _accReadX = event.accel[0];
        _accReadY = event.accel[1];
        _accReadZ = event.accel[2];
        _magnitude = sqrt(pow(_accReadX, 2) + pow(_accReadY, 2) + pow(_accReadZ, 2));

        _detectStep();
      });
    });
    setState(() {
      sampling = true;
    });
  }

  void _pauseListenToSensorEvents() async {
    subscription.cancel();
    stopwatch.stop();
    double elapsedSeconds = stopwatch.elapsedMilliseconds / 1000.0;
    _bpm = ((_stepCount / elapsedSeconds) * 60).round();
    setState(() {
      sampling = false;
    });
  }

  void dispose() {
    _pauseListenToSensorEvents();
    ESenseManager.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Color.fromARGB(255, 80, 80, 80),
        buttonColor: Color.fromARGB(200, 180, 0, 0),
        backgroundColor: Color.fromARGB(255, 250, 250, 250),
      ),
      home: Builder(
        builder: (context) => Scaffold(
          backgroundColor: Theme.of(context).backgroundColor,
          appBar: AppBar(
            title: const Text("Set the Rhythm"),
          ),
          body: Align(
            alignment: Alignment.center,
            child: ListView(
              padding: EdgeInsets.all(12.0),
              children: <Widget>[
                InfoBox(_deviceStatus, eSenseName, _stepCount, stopwatch.elapsedMilliseconds / 1000.0),
                Padding(padding: EdgeInsets.all(10)),
                BPMCard(_bpm, sampling),
                Padding(padding: EdgeInsets.all(10)),
                YTPageButton(_bpm),
              ],
            )
          ),
          floatingActionButton: new FloatingActionButton.extended(
            backgroundColor: Theme.of(context).buttonColor,
            onPressed:
            (!ESenseManager.connected) ? null : (!sampling) ? _startListenToSensorEvents : _pauseListenToSensorEvents,
            icon: (!sampling) ? Icon(Icons.play_arrow) : Icon(Icons.pause),
            label: (!sampling) ? Text("Start measuring") : Text("Stop measuring"),
          ),
        ),
      )
    );
  }
}

////////////////////////////////// WIDGETS /////////////////////////////////////

class InfoBox extends StatelessWidget {
  final String deviceStatus;
  final String eSenseName;
  final int stepCount;
  final double secondsElapsed;

  InfoBox(this.deviceStatus, this.eSenseName, this.stepCount, this.secondsElapsed);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor,
            blurRadius: 10.0, // has the effect of softening the shadow
            spreadRadius: 1.0, // has the effect of extending the shadow
          )
        ],
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        "$eSenseName Device Status: $deviceStatus\n"
            "Steps taken: $stepCount\n"
            "Time elapsed: ${secondsElapsed}s",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}

class BPMCard extends StatelessWidget {
  final int bpm;
  final bool sampling;
  BPMCard(this.bpm, this.sampling);

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 160,
        child: Card(
            elevation: 3,
            color: Colors.white,
            child: Container(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: <Widget>[
                    Text(
                      "BPM:",
                      style: TextStyle(fontSize: 30),
                      textAlign: TextAlign.center,
                    ),
                    (!sampling) ? Text(
                      "$bpm",
                      style: TextStyle(fontSize: 80),
                      textAlign: TextAlign.center,
                    ) : SpinKitRipple(
                      color: Colors.grey,
                      size: 80,
                    ),
                  ],
                )
            )
        )
    );
  }
}

class YTPageButton extends StatelessWidget {
  final int bpm;
  YTPageButton(this.bpm);

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      color: Theme.of(context).buttonColor,
      padding: EdgeInsets.all(20.0),
      child: Text(
        "Give me a song!",
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      onPressed: () {
        _checkInternet().then((available) {
          (!available) ? _showNoInternetDialog(context)
              : Navigator.push(context, MaterialPageRoute(builder: (context) => YTResults(Data(bpm: bpm))));
        });
      },
    );
  }

  Future<bool> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return (result.isNotEmpty && result[0].rawAddress.isNotEmpty);
    } on SocketException catch (_) {
      return false;
    }
  }

  void _showNoInternetDialog(BuildContext context) {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("No Internet Connection"),
          content: new Text(
              "The following feature requires Internet connection. "
              "Please make sure you have WiFi or Mobile Data turned on."
          ),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}