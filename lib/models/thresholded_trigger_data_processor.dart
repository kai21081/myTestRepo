import 'dart:collection';

import 'package:gameplayground/models/mock_bluetooth_manager.dart';

class ThresholdedTriggerDataProcessor {
  MockBluetoothManager _bluetoothManager;
  List<ProcessedDataPoint> _processedDataPoints = List<ProcessedDataPoint>();

  double _previousFilteredValue = 0.0;
  double _smoothingFactor = 0.25;
  double _triggeringThreshold = 10.0;
  static const int _triggerSignalRefractoryPeriodMilliseconds = 2000;
  int _lastTriggerTimestamp = -_triggerSignalRefractoryPeriodMilliseconds;

  UnmodifiableListView<ProcessedDataPoint> get processedDataPoints =>
      UnmodifiableListView<ProcessedDataPoint>(_processedDataPoints);

  ThresholdedTriggerDataProcessor(this._bluetoothManager);

  void startProcessing(Function onTriggerCallback, bool logData) {
    Stream<ProcessedDataPoint> preProcessedData =
        _bluetoothManager.getRawDataStream().map((emgSample) {
      return ProcessedDataPoint(emgSample.timestamp, emgSample.value);
    });

    Stream<ProcessedDataPoint> filteredDataWithTriggers =
        preProcessedData.map((data) {
      data.filteredValue = _smoothingFactor * data.rawValue.toDouble() +
          (1.0 - _smoothingFactor) * _previousFilteredValue;
      _previousFilteredValue = data.filteredValue;
      data.trigger = data.filteredValue > _triggeringThreshold;
      return data;
    });

    filteredDataWithTriggers.listen((data) {
      bool passTriggerToGame = data.trigger &&
          data.timestamp - _lastTriggerTimestamp >
              _triggerSignalRefractoryPeriodMilliseconds;
      data.triggerSignalPassedToGame = passTriggerToGame;

      if (passTriggerToGame) {
        onTriggerCallback();
        _lastTriggerTimestamp = data.timestamp;
      }

      if (logData) {
        _logDataPoint(data);
      }
    });
  }

  void stopProcessing() {
    _bluetoothManager.closeStream();
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
