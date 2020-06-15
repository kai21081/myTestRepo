import 'dart:async';
import 'dart:math';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:gameplayground/models/calibration_data.dart';
import 'package:gameplayground/models/mock_bluetooth_manager.dart';
import 'package:gameplayground/models/session_data.dart';
import 'package:provider/provider.dart';

class CalibrationPage extends StatefulWidget {
  final String title;

  CalibrationPage({Key key, this.title}) : super(key: key);

  @override
  _CalibrationPageState createState() => _CalibrationPageState();
}

class _CalibrationPageState extends State<CalibrationPage> {
  bool _animate = false;
  static final String _textChartBarLabel = 'Muscle Activation\nAmplitude';
  static final String _textUserInstructions = 'Activate your muscle.';
  static final String _textScreenTitle = 'Calibrate';

  static final String _labelAcceptButton = 'Accept';
  static final String _labelResetButton = 'Reset';
  static final String _labelCancelButton = 'Cancel';
  static final String _labelThresholdSlider = 'Select threshold';

  static final String _heroTagAcceptButton = 'accept_button';
  static final String _heroTagResetButton = 'reset_button';
  static final String _heroTagCancelButton = 'cancel_button';

  // TODO: Update based on actual limits from hardware.
  static final int _maxSensorValue = 100;
  static final int _minSensorValue = 0;
  static final double _defaultThreshold = 50;
  static const int _defaultGraphUpdatePeriodMilliseconds = 1;

  // Minimum number of milliseconds between graph updates. Can be used to slow
  // down update if UI begins failing to update due to too high of a sample
  // rate.
  final int _graphUpdatePeriodMinMilliseconds;
  int _timestampMillisecondsOfLastChartUpdate = 0;
  _ChartData _dataForPlot;
  double _thresholdSliderValue;
  Future<UserCalibrationData> _previousUserCalibrationData;

  _CalibrationPageState(
      {int graphUpdatePeriodMilliseconds:
          _CalibrationPageState._defaultGraphUpdatePeriodMilliseconds})
      : _graphUpdatePeriodMinMilliseconds = graphUpdatePeriodMilliseconds;

  MockBluetoothManager _bluetoothManager =
      MockBluetoothManager(100, 1, 10, 5, 50);
  StreamSubscription<EmgSample> _streamSubscription;
  _CalibrationManager _calibrationManager = _CalibrationManager();

  @override
  void initState() {
    super.initState();

    _thresholdSliderValue = _defaultThreshold;
    _previousUserCalibrationData =
        Provider.of<SessionDataModel>(context, listen: false)
            .getMostRecentCurrentUserCalibrationValue();
    _updateDataToPlot();
    _streamSubscription = _bluetoothManager.getRawDataStream().listen((data) {
      _calibrationManager.updateWithValue(data.value);
      if (data.timestamp - _timestampMillisecondsOfLastChartUpdate >
          _graphUpdatePeriodMinMilliseconds) {
        _timestampMillisecondsOfLastChartUpdate = data.timestamp;
        setState(() {
          _updateDataToPlot();
        });
      }
    });
  }

  void _updateDataToPlot() {
    _dataForPlot = _calibrationManager.chartData;
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    _bluetoothManager.closeStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_textScreenTitle),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 10),
            Text(_textUserInstructions, style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            SizedBox(
                height: 350,
                width: 250,
                child: _buildCalibrationChart(_dataForPlot)),
            SizedBox(height: 10),
            _buildSlider(
                context,
                _thresholdSliderValue,
                _minSensorValue.toDouble(),
                _maxSensorValue.toDouble(), (value) {
              setState(() => _thresholdSliderValue = value);
            }, _labelThresholdSlider),
            SizedBox(height: 30),
            FloatingActionButton.extended(
                label: Text('Set to max'),
                heroTag: 'set_to_max_button',
                onPressed: () {
                  setState(() {
                    _thresholdSliderValue =
                        _calibrationManager.maxValue.toDouble();
                  });
                }),
            SizedBox(height: 50),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              FloatingActionButton.extended(
                label: Text(_labelCancelButton),
                heroTag: _heroTagCancelButton,
                backgroundColor: theme.colorScheme.onPrimary,
                foregroundColor: theme.colorScheme.primary,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              SizedBox(width: 10),
              FloatingActionButton.extended(
                  label: Text(_labelResetButton),
                  heroTag: _heroTagResetButton,
                  backgroundColor: theme.colorScheme.onPrimary,
                  foregroundColor: theme.colorScheme.primary,
                  onPressed: () {
                    _calibrationManager.reset();
                    setState(() {
                      _updateDataToPlot();
                    });
                  }),
              SizedBox(width: 10),
              FloatingActionButton.extended(
                label: Text(_labelAcceptButton),
                heroTag: _heroTagAcceptButton,
                onPressed: () {
                  SessionDataModel sessionDataModel =
                      Provider.of<SessionDataModel>(context, listen: false);
                  sessionDataModel
                      .handleCalibrationData(_thresholdSliderValue.toInt())
                      .whenComplete(() {
                    _previousUserCalibrationData = sessionDataModel
                        .getMostRecentCurrentUserCalibrationValue();
                  });
                  Navigator.pop(context);
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
      BuildContext context,
      double sliderValue,
      double sliderMinValue,
      double sliderMaxValue,
      Function onChangedFunction,
      String sliderLabel) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Slider(
            value: sliderValue,
            min: sliderMinValue,
            max: sliderMaxValue,
            divisions: sliderMaxValue.toInt() - sliderMinValue.toInt(),
            onChanged: onChangedFunction,
            label: sliderValue.round().toString()),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Text(
            sliderLabel,
            style: TextStyle(fontSize: 20),
          )
        ]),
      ],
    );
  }

  Widget _buildCalibrationChart(_ChartData chartData) {
    return FutureBuilder(
        future: _previousUserCalibrationData,
        builder: (context, snapshot) {
          List<charts.Series<_ChartData, String>> chartSeries = [
            new charts.Series<_ChartData, String>(
                id: 'max_value_data',
                displayName: 'Max\nValue',
                domainFn: (_, __) => _textChartBarLabel,
                measureFn: (_ChartData data, _) =>
                    data.historicalMaxValue - data.value,
                data: [chartData]),
            new charts.Series<_ChartData, String>(
                id: 'current_value_data',
                displayName: 'Current\nValue',
                domainFn: (_, __) => _textChartBarLabel,
                measureFn: (_ChartData data, _) => data.value,
                data: [chartData]),
            new charts.Series<_ChartData, String>(
                id: 'new_threshold',
                displayName: 'New\nThreshold',
                colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
                domainFn: (_, __) => _textChartBarLabel,
                measureFn: (_ChartData data, _) => data.value,
                data: [_ChartData(_thresholdSliderValue.toInt(), null)])
              ..setAttribute(charts.rendererIdKey, 'newThresholdLine'),
          ];

          if (snapshot.connectionState == ConnectionState.done) {
            chartSeries.add(charts.Series<_ChartData, String>(
                id: 'previous_threshold',
                displayName: 'Previous\nThreshold',
                domainFn: (_, __) => _textChartBarLabel,
                measureFn: (_ChartData data, _) => data.value,
                data: [_ChartData(snapshot.data.value, null)])
              ..setAttribute(charts.rendererIdKey, 'previousThresholdLine'));
          }

          return new charts.BarChart(
            chartSeries,
            animate: _animate,
            barGroupingType: charts.BarGroupingType.stacked,
            primaryMeasureAxis: charts.NumericAxisSpec(
                tickProviderSpec: charts.StaticNumericTickProviderSpec([
              charts.TickSpec<num>(_minSensorValue),
              charts.TickSpec<num>(_maxSensorValue)
            ])),
            customSeriesRenderers: [
              new charts.BarTargetLineRendererConfig(
                  customRendererId: 'previousThresholdLine',
                  groupingType: charts.BarGroupingType.stacked),
              new charts.BarTargetLineRendererConfig(
                  customRendererId: 'newThresholdLine',
                  groupingType: charts.BarGroupingType.stacked)
            ],
            behaviors: [
              charts.SeriesLegend(
                position: charts.BehaviorPosition.end,
                horizontalFirst: false,
              )
            ],
          );
        });
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
