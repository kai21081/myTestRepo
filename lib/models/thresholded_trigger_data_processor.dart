import 'dart:collection';
import 'dart:io';

import 'package:gameplayground/models/emg_recording.dart';
import 'package:gameplayground/models/emg_sample.dart';

import 'bluetooth_manager.dart';

class ThresholdedTriggerDataProcessor {
  static const int _triggerSignalRefractoryPeriodMilliseconds = 500;

  static const String bluetoothManagerCallbackName =
      'ThresholdedTriggerDataProcessorCallback';
  final BluetoothManager _bluetoothManager;
  Function _onTriggerCallback;

  EmgRecording<ProcessedEmgSample> _dataLog =
      EmgRecording<ProcessedEmgSample>();
  bool _logData;

  double _previousFilteredValue = 0.0;
  double _smoothingFactor = 0.05;
  double _triggeringThreshold = 0.0001;

  int _lastTriggerTimestamp = -_triggerSignalRefractoryPeriodMilliseconds;
  int _numFlaps = 0;
  int get numFlaps => _numFlaps;

  EmgRecording get dataLog => _dataLog;

  ThresholdedTriggerDataProcessor(this._bluetoothManager);

  void startProcessing(Function(ProcessedEmgSample) onTriggerCallback,
      {bool logData: false}) {
    _onTriggerCallback = onTriggerCallback;
    _logData = logData;
    _bluetoothManager.addHandleSEmgValueCallback(
        bluetoothManagerCallbackName, _handleNewEmgSample);
  }

  void _handleNewEmgSample(RawEmgSample sample) {
    ProcessedEmgSample processedDataPoint =
        ProcessedEmgSample.fromRawEmgSample(sample);

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

    if (passTriggerToGame) {
      _onTriggerCallback(processedDataPoint);
      _lastTriggerTimestamp = processedDataPoint.timestamp;
      _numFlaps++;
    }

    if (_logData) {
      _logDataPoint(processedDataPoint, processedDataPoint.rawValue > _previousFilteredValue);
    }
  }

  void stopProcessing() {
    _bluetoothManager
        .removeHandleSEmgValueCallback(bluetoothManagerCallbackName);
    _onTriggerCallback = null;
    _logData = null;
  }

  void resetDataLog() {
    _dataLog = EmgRecording<ProcessedEmgSample>();
  }

  void _logDataPoint(ProcessedEmgSample sample, bool isFlap) {
    _dataLog.addSample(sample, isFlap);
  }
}
