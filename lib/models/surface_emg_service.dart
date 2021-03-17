// Wrapper for BluetoothService class to provide functionality relevant to
// the Surface EMG service.

import 'package:flutter_blue/flutter_blue.dart';
import 'package:gameplayground/models/surface_emg_characteristic.dart';
import 'package:gameplayground/models/surface_emg_guids.dart';

import 'emg_sample.dart';

class MissingCharacteristicException implements Exception {
  final String _guid;

  MissingCharacteristicException(this._guid);

  String errMsg() {
    return 'Surface EMG service did not have GUID: ${this._guid}.';
  }
}

BluetoothCharacteristic _getCharacteristicByGuid(
    BluetoothService service, Guid guid) {
  return service.characteristics.firstWhere(
      (BluetoothCharacteristic characteristic) => characteristic.uuid == guid,
      orElse: () => throw new MissingCharacteristicException(guid.toString()));
}

class SurfaceEmgService {
  final BluetoothService _service;

  EmgVoltageCharacteristic _emgVoltageCharacteristic;
  ShouldStreamValuesCharacteristic _shouldStreamValuesCharacteristic;
  BatteryPercentageCharacteristic _batteryPercentageCharacteristic;
  SampleRateCharacteristic _sampleRateCharacteristic;
  ConnectionModeAuthenticationCharacteristic
      _connectionModeAuthenticationCharacteristic;
  GainControlCharacteristic _gainControlCharacteristic;

  SurfaceEmgService(this._service) {
    _emgVoltageCharacteristic = EmgVoltageCharacteristic(
        _getCharacteristicByGuid(
            this._service, SurfaceEmgGuids.voltageCharacteristic()));
    _shouldStreamValuesCharacteristic = ShouldStreamValuesCharacteristic(
        _getCharacteristicByGuid(
            this._service, SurfaceEmgGuids.shouldStreamValuesCharacteristic()));
    _batteryPercentageCharacteristic = BatteryPercentageCharacteristic(
        _getCharacteristicByGuid(
            this._service, SurfaceEmgGuids.batteryPercentageCharacteristic()));
    _sampleRateCharacteristic = SampleRateCharacteristic(
        _getCharacteristicByGuid(
            this._service, SurfaceEmgGuids.shouldStreamValuesCharacteristic()));
    _connectionModeAuthenticationCharacteristic =
        ConnectionModeAuthenticationCharacteristic(_getCharacteristicByGuid(
            this._service,
            SurfaceEmgGuids.connectionModeAuthenticationCharacteristic()));
    _gainControlCharacteristic = GainControlCharacteristic(
        _getCharacteristicByGuid(
            this._service, SurfaceEmgGuids.emgGainControlCharacteristic()));
  }

  ReadOnlySurfaceEmgCharacteristic _getReadOnlyCharacteristic(
      ReadOnlySurfaceEmgCharacteristicType type) {
    switch (type) {
      case ReadOnlySurfaceEmgCharacteristicType.emgVoltage:
        return _emgVoltageCharacteristic;
      case ReadOnlySurfaceEmgCharacteristicType.batteryPercent:
        return _batteryPercentageCharacteristic;
      case ReadOnlySurfaceEmgCharacteristicType.sampleRate:
        return _sampleRateCharacteristic;
      default:
        throw ArgumentError(
            'Unrecognized ReadOnlySurfaceEmgCharacteristicType: $type.');
    }
  }

  void setCharacteristicNotifyValue(
      ReadOnlySurfaceEmgCharacteristicType characteristicType, bool notifyValue,
      [void Function() onNotifyValueSetCallback]) {
    _getReadOnlyCharacteristic(characteristicType)
        .setNotifyValue(notifyValue, onNotifyValueSetCallback);
  }

  bool characteristicIsNotifying(
      ReadOnlySurfaceEmgCharacteristicType characteristicType) {
    return _getReadOnlyCharacteristic(characteristicType).isNotifying;
  }

  void addHandleEmgVoltageProcessedValueCallback(
      String name, void Function(RawEmgSample) callback) {
    _emgVoltageCharacteristic.addHandleProcessedValueCallback(name, callback);
  }

  void removeHandleEmgVoltageProcessedValueCallback(String name) {
    _emgVoltageCharacteristic.removeHandleProcessedValueCallback(name);
  }

  void clearHandleEmgVoltageProcessedValueCallbacks() {
    _emgVoltageCharacteristic.clearHandleProcessedValueCallbacks();
  }

  Future<void> setShouldStreamValuesCharacteristicValue(bool value) {
    print('setShouldStreamValuesCharacteristicValue');
    print('_shouldStreamValuesCharacteristic is null: '
        '${_shouldStreamValuesCharacteristic == null}');
    return _shouldStreamValuesCharacteristic.writeValue(value);
  }

  Future<void> setConnectionModeAuthenticationCharacteristicValue(
      String value) {
    print('setConnectionModeAuthenticationCharacteristicValue');
    return _connectionModeAuthenticationCharacteristic.writeValue(value);
  }

  Future<void> setGain(int gain) {
    return _gainControlCharacteristic.writeValue(gain);
  }
}
