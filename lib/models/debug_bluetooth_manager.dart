import 'dart:async';
import 'bluetooth_manager.dart';
import 'emg_sample.dart';

import 'package:flutter_blue/flutter_blue.dart';

class DebugBluetoothManager implements BluetoothManager {
  Map<String, void Function(EmgSample)>
      _handleSEmgCharacteristicValueCallbacks =
      Map<String, void Function(EmgSample)>();
  Map<String, void Function(bool)> _handleIsReadyToProvideValuesCallbacks =
      Map<String, void Function(bool)>();

  bool _isReadyToProvideValues;

  DebugBluetoothManager() : _isReadyToProvideValues = false;

  void connect(ConnectionSpec connectionSpec) {
    Future.delayed(Duration(seconds: 1)).then((_) {
      _isReadyToProvideValues = true;
      _notifyIsReadyToProvideValuesState();
    });
  }

  void reset() {
    _isReadyToProvideValues = false;
    _notifyIsReadyToProvideValuesState();
  }

  void addHandleSEmgValueCallback(String name, Function(EmgSample) callback) {
    if (_handleSEmgCharacteristicValueCallbacks.containsKey(name)) {
      throw ArgumentError('addHandleSEmgValueCallback failed because a '
          'callback with name $name already exists.');
    }
    _handleSEmgCharacteristicValueCallbacks[name] = callback;
  }

  void removeHandleSEmgValueCallback(String name) {
    if (_handleSEmgCharacteristicValueCallbacks.containsKey(name)) {
      _handleSEmgCharacteristicValueCallbacks.remove(name);
    }
  }

  void clearHandleSEmgValueCallback() {
    _handleSEmgCharacteristicValueCallbacks.clear();
  }

  void _notifyIsReadyToProvideValuesState() {
    _handleIsReadyToProvideValuesCallbacks.values
        .forEach((Function callback) => callback(_isReadyToProvideValues));
  }

  bool get isReadyToProvideValues => _isReadyToProvideValues;

  void addNotifyIsReadyToProvideValuesStateCallback(
      String name, Function(bool) callback) {
    if (_handleIsReadyToProvideValuesCallbacks.containsKey(name)) {
      throw ArgumentError(
          'addNotifyIsReadyToProvideValuesStateCallback failed because a '
          'callback with name $name already exists.');
    }
    _handleIsReadyToProvideValuesCallbacks[name] = callback;
  }

  void removeNotifyIsReadyToProvideValuesStateCallback(String name) {
    if (_handleIsReadyToProvideValuesCallbacks.containsKey(name)) {
      _handleIsReadyToProvideValuesCallbacks.remove(name);
    }
  }

  void clearNotifyIsReadyToProvideValuesStateCallbacks() {
    _handleIsReadyToProvideValuesCallbacks.clear();
  }

  Future<List<ScanResult>> scanForAvailableSurfaceEmgDevices(
      {int timeoutMilliseconds: 500}) async {
    return Future.delayed(Duration(seconds: 2), () {
      return <ScanResult>[
        ScanResult(
            device: MockBluetoothDevice('first'),
            advertisementData: null,
            rssi: -70),
        ScanResult(
            device: MockBluetoothDevice('second'),
            advertisementData: null,
            rssi: -80)
      ];
    });
  }

  // This is used when searching for available devices to display to the user.
  // Long term, it may be better to find a way to combine it with the scan done
  // during the connection process.
  Future stopScan() {
    return Future.delayed(Duration(milliseconds: 100));
  }
}

class MockBluetoothDevice implements BluetoothDevice {
  final String name;

  MockBluetoothDevice(this.name);

  @override
  // TODO: implement canSendWriteWithoutResponse
  Future<bool> get canSendWriteWithoutResponse => null;

  @override
  Future<void> connect({Duration timeout, bool autoConnect = true}) {
    // TODO: implement connect
    return null;
  }

  @override
  Future disconnect() {
    // TODO: implement disconnect
    return null;
  }

  @override
  Future<List<BluetoothService>> discoverServices() {
    // TODO: implement discoverServices
    return null;
  }

  @override
  // TODO: implement id
  DeviceIdentifier get id => null;

  @override
  // TODO: implement isDiscoveringServices
  Stream<bool> get isDiscoveringServices => null;

  @override
  // TODO: implement mtu
  Stream<int> get mtu => null;

  @override
  Future<void> requestMtu(int desiredMtu) {
    // TODO: implement requestMtu
    return null;
  }

  @override
  // TODO: implement services
  Stream<List<BluetoothService>> get services => null;

  @override
  // TODO: implement state
  Stream<BluetoothDeviceState> get state => null;

  @override
  // TODO: implement type
  BluetoothDeviceType get type => null;
}
