import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:gameplayground/models/mock_bluetooth_manager.dart';

class InputTimeseriesPage extends StatefulWidget {
  final String title;

  InputTimeseriesPage({Key key, this.title}) : super(key: key);

  @override
  _InputTimeseriesPageState createState() => _InputTimeseriesPageState();
}

class _InputTimeseriesPageState extends State<InputTimeseriesPage> {
  TimeseriesWindowForPlot _timeseriesWindow = TimeseriesWindowForPlot(100);
  MockBluetoothManager _bluetoothManager =
      MockBluetoothManager(1000, 20, 10, 5, 50);
  StreamSubscription<EmgSample> _streamSubscription;

  @override
  void initState() {
    super.initState();
    _streamSubscription = _bluetoothManager.getRawDataStream().listen((data) {
      setState(() {
        _timeseriesWindow.addValue(data);
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubscription.cancel();
    _bluetoothManager.closeStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Input Timeseries"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
                height: 250,
                width: 250,
                child: charts.LineChart(
                  <charts.Series<EmgSample, int>>[
                    charts.Series<EmgSample, int>(
                        id: 'fake_data',
                        colorFn: (_, __) =>
                            charts.MaterialPalette.blue.shadeDefault,
                        domainFn: (EmgSample pair, _) => pair.timestamp,
                        measureFn: (EmgSample pair, _) => pair.value,
                        data: _timeseriesWindow.dataToPlot)
                  ],
                  animate: false,
                  domainAxis: charts.NumericAxisSpec(
                      tickProviderSpec:
                          charts.NumericEndPointsTickProviderSpec()),
                )),
          ],
        ),
      ),
    );
  }
}

class TimeseriesWindowForPlot {
  final int _capacity;
  ListQueue<EmgSample> _data;

  UnmodifiableListView<EmgSample> get dataToPlot =>
      UnmodifiableListView<EmgSample>(_data);

  TimeseriesWindowForPlot(this._capacity) {
    _data = ListQueue<EmgSample>();
  }

  void addValue(EmgSample value) {
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
    return _data.map((EmgSample pair) => pair.timestamp).reduce(min);
  }

  int get domainMax {
    if (_data.isEmpty) {
      return 0;
    }
    return _data.map((EmgSample pair) => pair.timestamp).reduce(max);
  }
}
