import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:gameplayground/models/bluetooth_manager.dart';
import 'package:gameplayground/models/emg_recording.dart';
import 'package:gameplayground/models/emg_sample.dart';
import 'package:gameplayground/models/game_record_saving_utils.dart';
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
  static final String _labelRecordButton = 'Record';
  static final String _labelSaveButton = 'Save';
  static final String _labelPreviewButton = 'Preview';
  static final String _heroTagRecordButton = 'record_button';
  static final String _heroTagSaveButton = 'save_button';
  static final String _heroTagPreviewButton = 'preview_button';

  static final String _callbackNameHandleSEmgValue =
      '_InputTimeseriesPageState_Callback';

  TimeseriesWindowForPlot _timeseriesWindow = TimeseriesWindowForPlot(20);
  BluetoothManager _bluetoothManager;
  ThresholdedTriggerDataProcessor _dataProcessor;
  bool _recording = false;

  EmgRecording<RawEmgSample> _currentRecording;
  EmgRecording<RawEmgSample> _previousRecording;

  List<int> _packetTimestamps = List<int>();
  int _packetCountForAverage = 20;
  String _currentPacketRateString = 'awaiting samples';

  int _currentGain = 100;

  final _saveTextEditingController = TextEditingController();

  final _saveRecordingFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _bluetoothManager =
        Provider.of<SessionDataModel>(context, listen: false).bluetoothManager;
    _bluetoothManager.addHandleSEmgValueCallback(_callbackNameHandleSEmgValue,
        (RawEmgSample sample) {
      setState(() {
        if (_packetTimestamps.length >= _packetCountForAverage) {
          double packetRate = (_packetTimestamps.length - 1) /
              ((_packetTimestamps.last - _packetTimestamps.first) / 1000.0);
          _packetTimestamps.clear();
          _currentPacketRateString = '${packetRate.toStringAsFixed(1)} Hz';
        }
        print(sample.timestamp);
        _packetTimestamps.add(sample.timestamp);
        _handleEmgSample(sample);
        _timeseriesWindow.addEmgSample(sample);
      });
    });

    _setGain(_currentGain);

    _dataProcessor = ThresholdedTriggerDataProcessor(_bluetoothManager);
    _dataProcessor.startProcessing(
        (ProcessedEmgSample data) =>
            _timeseriesWindow.addTriggerTimestamp(data.timestamp),
        logData: false);
  }

  @override
  void deactivate() {
    super.deactivate();
    _dataProcessor.stopProcessing();
    _bluetoothManager
        .removeHandleSEmgValueCallback(_callbackNameHandleSEmgValue);
  }

  @override
  void dispose() {
    // Clean up controller when widget is disposed.
    _saveTextEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        title: Text("Input Timeseries"),
        centerTitle: true,
        leading: BackButton(onPressed: () async {
          _dataProcessor.stopProcessing();
          _bluetoothManager
              .removeHandleSEmgValueCallback(_callbackNameHandleSEmgValue);
          _bluetoothManager.stopStreamingValues();
          Navigator.of(context).pop();
        }),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 10),
            Text('Set Gain'),
            SizedBox(height: 10),
            _buildGainButtonRow(),
            SizedBox(height: 10),
            SizedBox(
                height: 250,
                width: 250,
                child: charts.LineChart(
                    <charts.Series<RawEmgSample, int>>[
                      charts.Series<RawEmgSample, int>(
                          id: 'fake_data',
                          colorFn: (_, __) =>
                              charts.MaterialPalette.blue.shadeDefault,
                          domainFn: (RawEmgSample pair, _) => pair.timestamp,
                          measureFn: (RawEmgSample pair, _) => pair.voltage,
                          data: _timeseriesWindow.dataToPlot)
                    ]..addAll(_mapTriggerTimestampsToPlotToSeries(
                        _timeseriesWindow.triggerTimestampsToPlot,
                        _timeseriesWindow.dataMin,
                        _timeseriesWindow.dataMax)),
                    animate: false,
                    domainAxis: charts.NumericAxisSpec(
                        tickProviderSpec:
                            charts.NumericEndPointsTickProviderSpec()),
                    primaryMeasureAxis: charts.NumericAxisSpec(
                        tickProviderSpec: charts.StaticNumericTickProviderSpec(
                            [charts.TickSpec(-0.00001), charts.TickSpec(0.0001)])))),
            SizedBox(height: 30),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              FloatingActionButton.extended(
                  onPressed: _onRecordButtonPressed,
                  label: Text(_labelRecordButton),
                  heroTag: _heroTagRecordButton,
                  icon: Icon(Icons.fiber_manual_record,
                      color: _recording ? Colors.red : Colors.white)),
            ]),
            SizedBox(height: 20),
            Text(_currentPacketRateString),
            SizedBox(height: 15),
            _buildPreviousRecordingPanel()
          ],
        ),
      ),
    );
  }

  Widget _buildPreviousRecordingPanel() {
    if (_previousRecording == null) {
      return Container();
    }

    double maxRecordedValue = _previousRecording.data
        .map((rawEmgSample) => rawEmgSample.voltage)
        .reduce(max);

    String previousRecordingDuration =
        _previousRecording.durationSeconds.toStringAsFixed(3);
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Divider(indent: 20, endIndent: 20, thickness: 4),
          Text('Previous Recording:'),
          Text('   Duration: ${previousRecordingDuration}s'),
          SizedBox(height: 10),
          FloatingActionButton.extended(
              label: Text(_labelSaveButton),
              heroTag: _heroTagSaveButton,
              icon: Icon(Icons.save),
              onPressed: () {
                showDialog<String>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                          title: Text('Save recording.'),
                          content: Form(
                              key: _saveRecordingFormKey,
                              child: TextFormField(
                                textCapitalization: TextCapitalization.words,
                                controller: _saveTextEditingController,
                                cursorColor: Theme.of(context).cursorColor,
                                validator: (value) {
                                  return value.isEmpty
                                      ? 'Cannot be empty.'
                                      : null;
                                },
                                decoration: InputDecoration(
                                    filled: true,
                                    icon: const Icon(Icons.save),
                                    labelText: 'Filename'),
                              )),
                          actions: <Widget>[
                            FlatButton(
                                child: Text('Save'),
                                onPressed: () async {
                                  if (_saveRecordingFormKey.currentState
                                      .validate()) {
                                    print(
                                        'Saving with filename: ${_saveTextEditingController.text}');
                                    String filename =
                                        await buildSavePathInRecordingsDirectoryFromFilename(
                                            _saveTextEditingController.text +
                                                _previousRecording
                                                    .filenameTimestampSuffix);
                                    saveRecordingWithMetadata(
                                        _previousRecording,
                                        filename,
                                        'recordedData');
                                    Navigator.pop(context);
                                  }
                                }),
                            FlatButton(
                                child: Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                })
                          ]);
                    });
              }),
          SizedBox(height: 10),
          FloatingActionButton.extended(
            label: Text(_labelPreviewButton),
            heroTag: _heroTagPreviewButton,
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return SimpleDialog(
                      title: Text(
                          '${_previousRecording.durationMilliseconds} ms recording'),
                      children: <Widget>[
                        SizedBox(
                            height: 200,
                            width: 200,
                            child: charts.LineChart(
                              <charts.Series<RawEmgSample, int>>[
                                charts.Series<RawEmgSample, int>(
                                    id: 'fake_data',
                                    colorFn: (_, __) => charts
                                        .MaterialPalette.blue.shadeDefault,
                                    domainFn: (RawEmgSample sample, _) =>
                                        sample.timestamp -
                                        _previousRecording
                                            .startMillisecondsSinceEpoch,
                                    measureFn: (RawEmgSample sample, _) =>
                                        sample.voltage,
                                    data: _previousRecording.data)
                              ],
                              animate: false,
                              behaviors: [new charts.PanAndZoomBehavior()],
                              domainAxis: charts.NumericAxisSpec(
                                  viewport: charts.NumericExtents(0.0, 500.0)),
                              primaryMeasureAxis: charts.NumericAxisSpec(
                                  tickProviderSpec:
                                      charts.StaticNumericTickProviderSpec([
                                charts.TickSpec(0.0),
                                charts.TickSpec(1.1 * maxRecordedValue)
                              ])),
                            ))
                      ],
                    );
                  });
            },
          ),
        ]);
  }

  String _getCurrentFormFilenameWithTimestampSuffix() {
    return _saveTextEditingController.text +
        _previousRecording.filenameTimestampSuffix;
  }

  Row _buildGainButtonRow() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
      _buildSetGainButton(100, '1e2'),
      SizedBox(width: 10),
      _buildSetGainButton(1000, '1e3'),
      SizedBox(width: 10),
      _buildSetGainButton(10000, '1e4'),
      SizedBox(width: 10),
      _buildSetGainButton(20000, '2e4')
    ]);
  }

  SizedBox _buildSetGainButton(int gain, String label) {
    final theme = Theme.of(context);
    Color backgroundColor;
    if (gain == _currentGain) {
      backgroundColor = theme.colorScheme.primary;
    } else {
      backgroundColor = Colors.grey[300];
    }
    return SizedBox(
        height: 30,
        width: 60,
        child: FloatingActionButton.extended(
            label: Text(label),
            onPressed: () => _onGainButtonPushed(gain),
            disabledElevation: 0.0,
            backgroundColor: backgroundColor,
            heroTag: 'heroTagGainControlButton$label'));
  }

  void _onGainButtonPushed(int gain) {
    setState(() async {
      await _setGain(gain);
      _currentGain = gain;
    });
  }

  Future<void> _setGain(int gain) {
    _bluetoothManager.setGain(gain);
    print('Setting gain to $gain. Currently $_currentGain');
  }

  void _onRecordButtonPressed() {
    setState(() {
      if (_recording) {
        print(
            'Stopping recording - EmgRecording.numSamples = ${_currentRecording.numSamples}');
        // Need to stop recording, and handle current recording.
        if (_currentRecording.numSamples > 0) {
          _previousRecording = _currentRecording;
        }
        _currentRecording = null;
      } else {
        _currentRecording = EmgRecording();
      }

      _recording = !_recording;
    });
  }

  void _handleEmgSample(EmgSample sample) {
    if (_recording) {
      _currentRecording.addSample(sample);
    }
  }
}

List<charts.Series<RawEmgSample, int>> _mapTriggerTimestampsToPlotToSeries(
    UnmodifiableListView<RawEmgSample> triggerTimestamps,
    double rangeMinValue,
    double rangeMaxValue) {
  print(
      '_mapTriggerTimestampsToPlotToSeries, length: ${triggerTimestamps.length}');
  return List<charts.Series<RawEmgSample, int>>.of(
      triggerTimestamps.map((RawEmgSample sample) {
    List<RawEmgSample> mappedData = [
      RawEmgSample(
          sample.timestamp,
          rangeMinValue,
          /*gain=*/ 1.0),
      RawEmgSample(
          sample.timestamp,
          rangeMaxValue,
          /*gain=*/ 1.0)
    ];
    return charts.Series<RawEmgSample, int>(
        id: 'trigger_at_${sample.timestamp}',
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        domainFn: (RawEmgSample point, _) => point.timestamp,
        measureFn: (RawEmgSample point, _) => point.voltage,
        data: mappedData);
  }));
}

class TimeseriesWindowForPlot {
  final int _capacity;
  ListQueue<RawEmgSample> _data;
  ListQueue<int> _triggerTimestamps;

  UnmodifiableListView<RawEmgSample> get dataToPlot =>
      UnmodifiableListView<RawEmgSample>(_data);

  // Plot data must all be in EmgSample's, thus the timestamps are wrapped here.
  UnmodifiableListView<RawEmgSample> get triggerTimestampsToPlot =>
      UnmodifiableListView<RawEmgSample>(_triggerTimestamps.map(
          (int timestamp) =>
              RawEmgSample(timestamp, /*value=*/ null, /*gain=*/ 1.0)));

  TimeseriesWindowForPlot(this._capacity) {
    _data = ListQueue<RawEmgSample>();
    _triggerTimestamps = ListQueue<int>();
  }

  void addEmgSample(RawEmgSample value) {
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

  double get dataMin {
    if (_data.isEmpty) {
      return 0.0;
    }

    return _data.map((RawEmgSample sample) => sample.voltage).reduce(min);
  }

  double get dataMax {
    if (_data.isEmpty) {
      return 0.0;
    }

    return _data.map((RawEmgSample sample) => sample.voltage).reduce(max);
  }

  int get domainMin {
    if (_data.isEmpty) {
      return 0;
    }
    // Delete if works without
//    charts.AutoDateTimeTickProviderSpec();
    return _data.map((RawEmgSample pair) => pair.timestamp).reduce(min);
  }

  int get domainMax {
    if (_data.isEmpty) {
      return 0;
    }
    return _data.map((RawEmgSample pair) => pair.timestamp).reduce(max);
  }
}
