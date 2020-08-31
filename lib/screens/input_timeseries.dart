import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:gameplayground/models/bluetooth_manager.dart';
import 'package:gameplayground/models/emg_sample.dart';
import 'package:gameplayground/models/session_data.dart';
import 'package:gameplayground/models/thresholded_trigger_data_processor.dart';
import 'package:provider/provider.dart';

class InputTimeseriesPage extends StatefulWidget {
  final String title;

  InputTimeseriesPage({Key key, this.title}) : super(key: key);

  @override
  _InputTimeseriesPageState createState() => _InputTimeseriesPageState();
}

class _InputTimeseriesPageState extends State<InputTimeseriesPage> {
  static const int rangeMaxValue = 20000;
  static const int rangeMinValue = 0;
  TimeseriesWindowForPlot _timeseriesWindow = TimeseriesWindowForPlot(100);
  BluetoothManager _bluetoothManager;
  ThresholdedTriggerDataProcessor _dataProcessor;
  StreamSubscription<EmgSample> _streamSubscription;

  @override
  void initState() {
    super.initState();
    _bluetoothManager =
        Provider.of<SessionDataModel>(context, listen: false).bluetoothManager;
    _bluetoothManager.addHandleSEmgValueCallback('InputTimeseriesPage',
        (EmgSample sample) {
      setState(() {
        _timeseriesWindow.addValue(sample);
      });
    });

    _dataProcessor = ThresholdedTriggerDataProcessor(_bluetoothManager);
    _dataProcessor.startProcessing(
        (ProcessedDataPoint data) =>
            _timeseriesWindow.addTriggerTimestamp(data.timestamp),
        logData: false);
  }

  @override
  void deactivate() {
    super.deactivate();
    _dataProcessor.stopProcessing();
    _bluetoothManager.removeHandleSEmgValueCallback('InputTimeseriesPage');
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
                    ]..addAll(_mapTriggerTimestampsToPlotToSeries(
                        _timeseriesWindow.triggerTimestampsToPlot)),
                    animate: false,
                    domainAxis: charts.NumericAxisSpec(
                        tickProviderSpec:
                            charts.NumericEndPointsTickProviderSpec()),
                    primaryMeasureAxis: charts.NumericAxisSpec(
                        tickProviderSpec: charts.StaticNumericTickProviderSpec(
                            [charts.TickSpec(0), charts.TickSpec(20000)])))),
          ],
        ),
      ),
    );
  }
}

List<charts.Series<EmgSample, int>> _mapTriggerTimestampsToPlotToSeries(
    UnmodifiableListView<EmgSample> triggerTimestamps) {
  print('_mapTriggerTimestampsToPlotToSeries, length: ${triggerTimestamps.length}');
  return List<charts.Series<EmgSample, int>>.of(
      triggerTimestamps.map((EmgSample sample) {
    List<EmgSample> mappedData = [
      EmgSample(sample.timestamp, _InputTimeseriesPageState.rangeMinValue),
      EmgSample(sample.timestamp, _InputTimeseriesPageState.rangeMaxValue)
    ];
    return charts.Series<EmgSample, int>(
        id: 'trigger_at_${sample.timestamp}',
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        domainFn: (EmgSample point, _) => point.timestamp,
        measureFn: (EmgSample point, _) => point.value,
        data: mappedData);
  }));
}

class TimeseriesWindowForPlot {
  final int _capacity;
  ListQueue<EmgSample> _data;
  ListQueue<int> _triggerTimestamps;

  UnmodifiableListView<EmgSample> get dataToPlot =>
      UnmodifiableListView<EmgSample>(_data);

  // Plot data must all be in EmgSample's, thus the timestamps are wrapped here.
  UnmodifiableListView<EmgSample> get triggerTimestampsToPlot =>
      UnmodifiableListView<EmgSample>(_triggerTimestamps
          .map((int timestamp) => EmgSample(timestamp, null)));

  TimeseriesWindowForPlot(this._capacity) {
    _data = ListQueue<EmgSample>();
    _triggerTimestamps = ListQueue<int>();
  }

  void addValue(EmgSample value) {
    _data.addLast(value);

    if (_data.length > _capacity) {
      _data.removeFirst();
    }

    // Remove any trigger that is before the first data point (because it is no
    // longer needed for plotting).
    while (_triggerTimestamps.isNotEmpty &&
        (_triggerTimestamps.first < _data.first.timestamp)) {
      _triggerTimestamps.removeFirst();
    }
  }

  void addTriggerTimestamp(int timestamp) {
    print('trigger added');
    _triggerTimestamps.addLast(timestamp);
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
