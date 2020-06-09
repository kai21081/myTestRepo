import 'dart:async';
import 'dart:math';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:gameplayground/models/mock_bluetooth_manager.dart';
import 'package:gameplayground/models/session_data.dart';
import 'package:gameplayground/screens/main_menu.dart';
import 'package:provider/provider.dart';

class CalibrationPage extends StatefulWidget {
  final String title;

  CalibrationPage({Key key, this.title}) : super(key: key);

  @override
  _CalibrationPageState createState() => _CalibrationPageState();
}

class _CalibrationPageState extends State<CalibrationPage> {
  bool _animate = false;
  final String _chartBarLabel = 'Muscle Activation Amplitude';

  final int _maxValue = 200;
  final int _minValue = 0;

  MockBluetoothManager _bluetoothManager =
      MockBluetoothManager(100, 1, 10, 5, 50);
  StreamSubscription<EmgSample> _streamSubscription;
  _CalibrationManager _calibrationManager = _CalibrationManager();

  @override
  void initState() {
    super.initState();
    // If the graph begins to fail to update, this may be do to too high of a
    // sample rate. Consider adding a downsampling step here (or elsewhere).
    _streamSubscription = _bluetoothManager.getRawDataStream().listen((data) {
      setState(() {
        _calibrationManager.updateWithValue(data.value);
      });
    });
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    _bluetoothManager.closeStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Calibration"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Activate your muscle\nas much as you can.',
                style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            SizedBox(
                height: 250,
                width: 250,
                child: _buildCalibrationChart(_calibrationManager.chartData)),
            SizedBox(height: 60),
            FloatingActionButton.extended(
              label: Text('Accept'),
              heroTag: 'accept',
              onPressed: () {
                Provider.of<SessionDataModel>(context, listen: false)
                    .handleCalibrationData(_calibrationManager.maxValue);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => MainMenuPage()));
              },
            ),
            SizedBox(height: 20),
            FloatingActionButton.extended(
                label: Text('Reset'),
                heroTag: 'restart',
                onPressed: () {
                  _calibrationManager.reset();
                }),
            SizedBox(height: 20),
            FloatingActionButton.extended(
              label: Text('Cancel'),
              heroTag: 'cancel',
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => MainMenuPage()));
              },
            ),
          ],
        ),
      ),
    );
  }

  charts.BarChart _buildCalibrationChart(_ChartData chartData) {
    List<charts.Series<_ChartData, String>> chartSeries = [
      new charts.Series<_ChartData, String>(
          id: 'max_value_data',
          domainFn: (_, __) => _chartBarLabel,
          measureFn: (_ChartData data, _) =>
              data.historicalMaxValue - data.value,
          data: [chartData]),
      new charts.Series<_ChartData, String>(
          id: 'current_value_data',
          domainFn: (_, __) => _chartBarLabel,
          measureFn: (_ChartData data, _) => data.value,
          data: [chartData]),
    ];

    return new charts.BarChart(
      chartSeries,
      animate: _animate,
      barGroupingType: charts.BarGroupingType.stacked,
      primaryMeasureAxis: charts.NumericAxisSpec(
          tickProviderSpec: charts.StaticNumericTickProviderSpec([
        charts.TickSpec<num>(_minValue),
        charts.TickSpec<num>(_maxValue)
      ])),
    );
  }
}

class _CalibrationManager {
  static final int _initialMaxValue = 0;
  static final int _initialCurrentValue = 0;

  int _maxValue = _initialMaxValue;
  int _currentValue = _initialCurrentValue;

  void updateWithValue(int value) {
    _currentValue = value;
    _maxValue = max(_currentValue, _maxValue);
  }

  _ChartData get chartData => _ChartData(_currentValue, _maxValue);

  int get maxValue => _maxValue;

  void reset() {
    _maxValue = _initialMaxValue;
    _currentValue = _initialCurrentValue;
  }
}

class _ChartData {
  final int value;
  final int historicalMaxValue;

  _ChartData(this.value, this.historicalMaxValue);
}
