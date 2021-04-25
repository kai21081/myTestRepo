import 'dart:async';
import 'dart:math';
import 'bluetooth_manager.dart';
import 'callback_collection.dart';
import 'emg_sample.dart';

import 'package:flutter_blue/flutter_blue.dart';

class DebugBluetoothManager implements BluetoothManager {
  static const int millisecondsBetweenSamples = 10;
  static const double randomDataMax = 100.0;
  static const double randomDataMin = 0.0;

  Random randomNumberGenerator = Random();

  CallbackCollection<String, bool> _handleIsReadyToProvideValuesCallbacks =
      CallbackCollection<String, bool>();
  CallbackCollection<String, RawEmgSample> _handleEmgSampleCallbacks =
      CallbackCollection<String, RawEmgSample>();

  Timer periodicDataGeneratingTimer;

  bool _isReadyToProvideValues;

  DebugBluetoothManager() : _isReadyToProvideValues = false;

  void connect(ConnectionSpec connectionSpec) {
    Future.delayed(Duration(milliseconds: 200)).then((_) {
      _isReadyToProvideValues = true;
      _notifyIsReadyToProvideValuesState();
    });
  }

  void reset() {
    _isReadyToProvideValues = false;
    _notifyIsReadyToProvideValuesState();
  }

  void addHandleSEmgValueCallback(
      String name, Function(RawEmgSample) callback) {
    _handleEmgSampleCallbacks.addCallback(name, callback);
  }

  void removeHandleSEmgValueCallback(String name) {
    _handleEmgSampleCallbacks.removeCallback(name);
  }

  void clearHandleSEmgValueCallback() {
    _handleEmgSampleCallbacks.clearCallbacks();
  }

  void _notifyIsReadyToProvideValuesState() {
    _handleIsReadyToProvideValuesCallbacks.handleValue(_isReadyToProvideValues);
  }

  @override
  Future<void> startStreamingValues() {
    return Future.delayed(Duration(milliseconds: 100)).then((_) {
      _startStreamingRandomValues();
    });
  }

  void _startStreamingRandomValues() {
    periodicDataGeneratingTimer =
        Timer.periodic(Duration(milliseconds: millisecondsBetweenSamples), (_) {
      RawEmgSample sample = RawEmgSample(DateTime.now().millisecondsSinceEpoch,
          _generateRandomVoltage(), /*gain=*/ 1.0);
      _handleEmgSampleCallbacks.handleValue(sample);
    });
  }

  double _generateRandomVoltage() {
    return randomDataMin +
        randomNumberGenerator.nextDouble() * (randomDataMax - randomDataMin);
  }

  @override
  Future<void> stopStreamingValues() {
    return Future.delayed(Duration(milliseconds: 100)).then((_) {
      periodicDataGeneratingTimer.cancel();
    });
  }

  @override
  Future<void> authenticate() {
    return Future.delayed(Duration(milliseconds: 100));
  }

  bool get isReadyToProvideValues => _isReadyToProvideValues;

  void addNotifyIsReadyToProvideValuesStateCallback(
      String name, Function(bool) callback) {
    _handleIsReadyToProvideValuesCallbacks.addCallback(name, callback);
  }

  void removeNotifyIsReadyToProvideValuesStateCallback(String name) {
    _handleIsReadyToProvideValuesCallbacks.removeCallback(name);
  }

  void clearNotifyIsReadyToProvideValuesStateCallbacks() {
    _handleIsReadyToProvideValuesCallbacks.clearCallbacks();
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
