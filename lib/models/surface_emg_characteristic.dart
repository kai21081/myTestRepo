// Wrappers for the BluetoothCharacteristic classes to provide functionality
// relevant for Surface EMG characteristics.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue/flutter_blue.dart';

import 'callback_collection.dart';
import 'emg_sample.dart';

enum WriteOnlySurfaceEmgCharacteristicType { shouldStreamValues }

enum ReadOnlySurfaceEmgCharacteristicType {
  emgVoltage,
  sampleRate,
  batteryPercent
}

class ReadOnlySurfaceEmgCharacteristic<ProcessedDataType> {
  final BluetoothCharacteristic _characteristic;

  bool _shouldBeNotifying;
  void Function() _onNotifyValueSetCallback;
  bool _changingNotifyValue = false;
  bool _isNotifying;
  StreamSubscription<List<int>> _rawDataStreamSubscription;
  final ProcessedDataType Function(List<int>) _rawDataProcessingFunction;

  CallbackCollection<String, ProcessedDataType> _handleProcessedValueCallbacks =
      CallbackCollection<String, ProcessedDataType>();
  CallbackCollection<String, bool> _handleIsReadyToProvideValuesCallbacks =
      CallbackCollection<String, bool>();

  ReadOnlySurfaceEmgCharacteristic(
      this._characteristic, this._rawDataProcessingFunction) {
    _shouldBeNotifying = this._characteristic.isNotifying;
    _isNotifying = this._characteristic.isNotifying;
  }

  bool get isNotifying => _isNotifying;

  void setNotifyValue(bool value,
      [void Function() onNotifyValueSetCallback]) async {
    print('in setNotifyValue with value of: $value');
    print('previous _shouldBeNotifying: $_shouldBeNotifying');
    print('_changingNotifyValue: $_changingNotifyValue');
    _shouldBeNotifying = value;
    _onNotifyValueSetCallback = onNotifyValueSetCallback;

    if (_changingNotifyValue) {
      print('returning because _changingNotifyValue is true.');
      return;
    }

    if (_characteristic.isNotifying == _shouldBeNotifying) {
      print(
          'returning because _characteristic.isNotifying == _shouldBeNotifying');
      return;
    }

    _changingNotifyValue = true;

    // Notify value is going to be changed, so if it is currently notifying,
    // cancel subscription to stream.
    if (_characteristic.isNotifying) {
      await _rawDataStreamSubscription.cancel();
    }

    print('setNotifyValue progressed to actually changing value.');
    // Now, set the value.
    _characteristic.setNotifyValue(value).then((_) {
      // If now notifying, listen to stream.
      if (value) {
        _rawDataStreamSubscription =
            _characteristic.value.listen(_handleRawValue);
      }

      _isNotifying = value;
      _changingNotifyValue = false;

      // Make sure _shouldBeNotifying hasn't changed while notify value was
      // being set. If so, call method again. If not, call onSetCallback (if
      // provided).
      if (_shouldBeNotifying != value) {
        setNotifyValue(_shouldBeNotifying, _onNotifyValueSetCallback);
      } else {
        if (_onNotifyValueSetCallback != null) {
          _onNotifyValueSetCallback();
        }
      }
    });
  }

  void _handleRawValue(List<int> value) {
    // BluetoothManager would check _isReadyToProvide values and return early if
    // false.
    if (value.isEmpty) {
      return;
    }

    ProcessedDataType processedValue = _rawDataProcessingFunction(value);
    _handleProcessedValueCallbacks.handleValue(processedValue);
  }

  void addHandleProcessedValueCallback(
      String name, void Function(ProcessedDataType) callback) {
    _handleProcessedValueCallbacks.addCallback(name, callback);
  }

  void removeHandleProcessedValueCallback(String name) {
    _handleProcessedValueCallbacks.removeCallback(name);
  }

  void clearHandleProcessedValueCallbacks() {
    _handleProcessedValueCallbacks.clearCallbacks();
  }

  void addIsReadyToProvideValuesStateCallback(
      String name, Function(bool) callback) {
    _handleIsReadyToProvideValuesCallbacks.addCallback(name, callback);
  }

  void removeIsReadyToProvideValuesStateCallback(String name) {
    _handleIsReadyToProvideValuesCallbacks.removeCallback(name);
  }

  void clearIsReadyToProvideValuesStateCallbacks() {
    _handleIsReadyToProvideValuesCallbacks.clearCallbacks();
  }
}

class EmgVoltageCharacteristic
    extends ReadOnlySurfaceEmgCharacteristic<RawEmgSample> {
  EmgVoltageCharacteristic(BluetoothCharacteristic characteristic)
      : super(characteristic, EmgVoltageCharacteristic._processRawValue);

  static RawEmgSample _processRawValue(List<int> value) {
    return RawEmgSample.fromRawIntList(value);
  }
}

class BatteryPercentageCharacteristic
    extends ReadOnlySurfaceEmgCharacteristic<int> {
  BatteryPercentageCharacteristic(BluetoothCharacteristic characteristic)
      : super(characteristic, BatteryPercentageCharacteristic._processRawValue);

  static int _processRawValue(List<int> value) => value[0];
}

class SampleRateCharacteristic extends ReadOnlySurfaceEmgCharacteristic<int> {
  SampleRateCharacteristic(BluetoothCharacteristic characteristic)
      : super(characteristic, SampleRateCharacteristic._processRawValue);

  static int _processRawValue(List<int> value) {
    if (value.length == 2) {
      return value.last;
    } else {
      return (value[2] << 8) + value[1];
    }
  }
}

class WriteOnlySurfaceEmgCharacteristic<DataType> {
  final BluetoothCharacteristic _characteristic;
  final List<int> Function(DataType) _dataTypeToIntListFunction;

  WriteOnlySurfaceEmgCharacteristic(
      this._characteristic, this._dataTypeToIntListFunction);

  Future<bool> writeValue(DataType value) {
    print('writeValue, _characteristic is null: ${_characteristic == null}');
    print('list: ${_dataTypeToIntListFunction(value)}, built from: $value');
    return _characteristic
        .write(this._dataTypeToIntListFunction(value), withoutResponse: false)
        .catchError((e) => false);
  }
}

class ShouldStreamValuesCharacteristic
    extends WriteOnlySurfaceEmgCharacteristic<bool> {
  ShouldStreamValuesCharacteristic(BluetoothCharacteristic characteristic)
      : super(characteristic,
            ShouldStreamValuesCharacteristic._valueToIntListFunction);

  static List<int> _valueToIntListFunction(bool value) {
    return List<int>.from([value ? 1 : 0]);
  }
}

// TODO: Generalize this to read/write when implemented in firmware.
class ConnectionModeAuthenticationCharacteristic
    extends WriteOnlySurfaceEmgCharacteristic<String> {
  ConnectionModeAuthenticationCharacteristic(
      BluetoothCharacteristic characteristic)
      : super(characteristic,
            ConnectionModeAuthenticationCharacteristic._valueToIntListFunction);

  static List<int> _valueToIntListFunction(String value) {
    return value.codeUnits;
  }
}

class GainControlCharacteristic extends WriteOnlySurfaceEmgCharacteristic<int> {
  GainControlCharacteristic(BluetoothCharacteristic characteristic)
      : super(
            characteristic, GainControlCharacteristic._valueToIntListFunction);

  static List<int> _valueToIntListFunction(int value) {
    // First value should be 1 which specifies that the next 4 bytes specify
    // a target gain.
    List<int> values = [1];

    // Set float value.
    var buffer = new Int8List(4).buffer;
    var bufferData = ByteData.view(buffer);
    bufferData.setInt32(0, value, Endian.little);
    values.addAll(buffer.asInt8List());
    return values;
  }
}
