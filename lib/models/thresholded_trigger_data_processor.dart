import 'dart:collection';
import 'dart:io';

import 'package:gameplayground/models/emg_sample.dart';

import 'bluetooth_manager.dart';

class ThresholdedTriggerDataProcessor {
  static const String bluetoothManagerCallbackName =
      'ThresholdedTriggerDataProcessorCallback';
  BluetoothManager _bluetoothManager;
  List<ProcessedDataPoint> _processedDataPoints = List<ProcessedDataPoint>();

  Function _onTriggerCallback;
  bool _logData;

  double _previousFilteredValue = 0.0;
  double _smoothingFactor = 0.05;
  double _triggeringThreshold = 4000.0;
  static const int _triggerSignalRefractoryPeriodMilliseconds = 500;
  int _lastTriggerTimestamp = -_triggerSignalRefractoryPeriodMilliseconds;

  UnmodifiableListView<ProcessedDataPoint> get processedDataPoints =>
      UnmodifiableListView<ProcessedDataPoint>(_processedDataPoints);

  ThresholdedTriggerDataProcessor(this._bluetoothManager);

  void startProcessing(Function(ProcessedDataPoint) onTriggerCallback,
      {bool logData: false}) {
    _onTriggerCallback = onTriggerCallback;
    _logData = logData;
    _bluetoothManager.addHandleSEmgValueCallback(
        bluetoothManagerCallbackName, _handleNewEmgSample);
  }

  void _handleNewEmgSample(EmgSample sample) {
    print('handling value');
    ProcessedDataPoint processedDataPoint =
        ProcessedDataPoint.fromEmgSample(sample);

    processedDataPoint.filteredValue =
        _smoothingFactor * processedDataPoint.rawValue.toDouble() +
            (1.0 - _smoothingFactor) * _previousFilteredValue;

    // TODO: figure out if this should stay (approach used for Unity version.)
    processedDataPoint.trigger =
        (processedDataPoint.rawValue > _triggeringThreshold) &&
            (processedDataPoint.rawValue > _previousFilteredValue * 1.18);

    _previousFilteredValue = processedDataPoint.filteredValue;

    bool passTriggerToGame = processedDataPoint.trigger &&
        processedDataPoint.timestamp - _lastTriggerTimestamp >
            _triggerSignalRefractoryPeriodMilliseconds;
    processedDataPoint.triggerSignalPassedToGame = passTriggerToGame;

    print('filtered value: ${processedDataPoint.filteredValue}, '
        'trigger: ${processedDataPoint.trigger}, '
        'passTriggerToGame: ${processedDataPoint.triggerSignalPassedToGame}');

    if (passTriggerToGame) {
      _onTriggerCallback(processedDataPoint);
      _lastTriggerTimestamp = processedDataPoint.timestamp;
    }

    if (_logData) {
      _logDataPoint(processedDataPoint);
    }
  }

  void stopProcessing() {
    _bluetoothManager
        .removeHandleSEmgValueCallback(bluetoothManagerCallbackName);
    _onTriggerCallback = null;
    _logData = null;
  }

  void resetDataLog() {
    _processedDataPoints = List<ProcessedDataPoint>();
  }

  void _logDataPoint(ProcessedDataPoint dataPoint) {
    _processedDataPoints.add(dataPoint);
  }
}

class ProcessedDataPoint {
  int timestamp;
  int rawValue;
  double filteredValue;
  bool trigger;
  bool triggerSignalPassedToGame;

  ProcessedDataPoint(this.timestamp, this.rawValue);

  ProcessedDataPoint.fromEmgSample(EmgSample sample)
      : this.timestamp = sample.timestamp,
        this.rawValue = sample.value;

  Map<String, dynamic> asMap() {
    return {
      'timestamp': timestamp,
      'rawValue': rawValue,
      'filteredValue': filteredValue,
      'trigger': trigger,
      'triggerSignalPassedToGame': triggerSignalPassedToGame
    };
  }
}
