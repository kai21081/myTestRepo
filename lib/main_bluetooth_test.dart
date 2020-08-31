import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'models/bluetooth_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BluetoothManager bluetoothManager = BluetoothManager();

  bluetoothManager.addHandleSEmgValueCallback(
      'test_0', (value) => print('test_0: $value'));
  bluetoothManager.addHandleSEmgValueCallback(
      'test_1', (value) => print('test_1: $value'));

  bluetoothManager.addNotifyIsReadyToProvideValuesStateCallback(
      'notify',
          (bool state) =>
          print('notify callback called with state: $state'));

  Timer(Duration(seconds: 30), () {
    bluetoothManager.removeHandleSEmgValueCallback('test_0');
    Timer(Duration(seconds: 30), () {
      bluetoothManager.removeHandleSEmgValueCallback('test_1');
    });
  });

//  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Playground',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'BLE Playground Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BluetoothDevice _device;
  Future<void> _deviceIsConnectedAndListeningFuture;
  TimeseriesWindowForPlot _timeseriesWindowForPlot =
  TimeseriesWindowForPlot(10);

  @override
  void initState() {
    super.initState();

    _timeseriesWindowForPlot.addValue(DataPoint(0, 0));

    FlutterBlue flutterBlue = FlutterBlue.instance;
    flutterBlue.setLogLevel(LogLevel.emergency);
    flutterBlue.startScan(timeout: Duration(seconds: 5));

    _deviceIsConnectedAndListeningFuture =
        flutterBlue.scanResults.firstWhere((List<ScanResult> results) {
          return results.any((ScanResult r) => r.device.name == 'Heartrate');
        }).then((List<ScanResult> results) {
          print('one');
          ScanResult deviceScanResult =
          results.firstWhere((ScanResult r) => r.device.name == 'Heartrate');
          _device = deviceScanResult.device;
          return _device.connect();
        }).then((_) {
          print('two');
          return _device.discoverServices();
        }).then((services) {
          print('three');
          print('services.length = ${services.length}');
          services.forEach((s) {
            print('iterating through service - ${s.uuid}');
            BluetoothCharacteristic hrCharacteristic = s.characteristics.firstWhere(
                    (c) => c.uuid.toString().startsWith('00002a37'),
                orElse: () => null);
            print('characteristic search result: $hrCharacteristic');
            if (hrCharacteristic != null) {
              print('found characteristic');
              hrCharacteristic.setNotifyValue(true).then((bool) {
                hrCharacteristic.value.listen((value) => _handleValue(value));
              });
            }
          });
        });
  }

  void _handleValue(List<int> value) {
    print('handling value');
    if (value.length == 0) {
      print('skipping empty characteristic value:');
      return;
    }

    setState(() {
      _timeseriesWindowForPlot.addValue(DataPoint(
          DateTime.now().millisecondsSinceEpoch, _interpretValue(value)));
    });
  }

  int _interpretValue(List<int> value) {
    if (value.length == 2) {
      return value.last;
    } else {
      return (value[2] << 8) + value[1];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: FutureBuilder(
              future: _deviceIsConnectedAndListeningFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Center(
                      child: Column(children: [
                        Text(
                            'Last Timestamp: ${_timeseriesWindowForPlot.dataToPlot.last.timestamp}'),
                        Text(
                            'Last Value: ${_timeseriesWindowForPlot.dataToPlot.last.value}'),
                        SizedBox(
                            height: 250,
                            width: 250,
                            child: charts.LineChart(
                              <charts.Series<DataPoint, int>>[
                                charts.Series<DataPoint, int>(
                                    id: 'fake_data',
                                    colorFn: (_, __) =>
                                    charts.MaterialPalette.blue.shadeDefault,
                                    domainFn: (DataPoint pair, _) => pair.timestamp,
                                    measureFn: (DataPoint pair, _) => pair.value,
                                    data: _timeseriesWindowForPlot.dataToPlot)
                              ],
                              animate: false,
                              domainAxis: charts.NumericAxisSpec(
                                  tickProviderSpec:
                                  charts.NumericEndPointsTickProviderSpec()),
                              primaryMeasureAxis: charts.NumericAxisSpec(
                                  tickProviderSpec:
                                  charts.StaticNumericTickProviderSpec([
                                    charts.TickSpec(0),
                                    charts.TickSpec(20000)
                                  ])),
                            ))
                      ]));
                } else {
                  return CircularProgressIndicator();
                }
              })),
    );
  }
}

class DataPoint {
  final int timestamp;
  final int value;

  DataPoint(this.timestamp, this.value);
}

class TimeseriesWindowForPlot {
  final int _capacity;
  ListQueue<DataPoint> _data;

  UnmodifiableListView<DataPoint> get dataToPlot =>
      UnmodifiableListView<DataPoint>(_data);

  TimeseriesWindowForPlot(this._capacity) {
    _data = ListQueue<DataPoint>();
  }

  void addValue(DataPoint value) {
    _data.addLast(value);

    if (_data.length > _capacity) {
      _data.removeFirst();
    }
  }

  int get domainMin {
    if (_data.isEmpty) {
      return 0;
    }
    charts.AutoDateTimeTickProviderSpec();
    return _data.map((DataPoint pair) => pair.timestamp).reduce(min);
  }

  int get domainMax {
    if (_data.isEmpty) {
      return 0;
    }
    return _data.map((DataPoint pair) => pair.timestamp).reduce(max);
  }
}
