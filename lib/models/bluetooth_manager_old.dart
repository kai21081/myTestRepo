import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'emg_sample.dart';

class BluetoothManager {
  static const String serviceGuidString =
      '0000180d-0000-1000-8000-00805f9b34fb';
  static const String characteristicGuidString =
      '00002a37-0000-1000-8000-00805f9b34fb';

  static const int scanTimeoutMilliseconds = 10000;
  static const int betweenScanIntervalMilliseconds = 5000;
  static const int reconnectTimeoutMilliseconds = 5000;

  final FlutterBlue _flutterBlue;

  String _deviceName;

  StreamSubscription<List<int>> _valueStreamSubscription;
  StreamSubscription<BluetoothDeviceState> _deviceStateStreamSubscription;
  BluetoothManagerState _currentState = BluetoothManagerState.disconnected;
  BluetoothDevice _device;
  BluetoothService _service;
  BluetoothCharacteristic _characteristic;

  Map<String, Function> _handleValueCallbacks = Map<String, Function>();
  Map<String, Function> _notifyStateChangeCallbacks = Map<String, Function>();

  BluetoothManager() : _flutterBlue = FlutterBlue.instance;

  DateTime _mostRecentResetTimestamp = DateTime.fromMillisecondsSinceEpoch(0);

  BluetoothManagerState get currentState => _currentState;

  void setDeviceName(String deviceName) {
    print('setDeviceName called with: $deviceName');
    _deviceName = deviceName;
  }

  void initialize() {
    if (_deviceName == null) {
      throw StateError(
          'Cannot initialize BluetoothManager before deviceName is set.');
    }
    _startScanAndConnectLoop();
  }

  Future<void> reset() async {
    _mostRecentResetTimestamp = DateTime.now();
    _deviceName = null;

    if (_currentState == BluetoothManagerState.connected) {
      await _cancelValueStreamSubscriptionAndStopNotifying();
      await _unsubscribeFromDeviceState();
      await _device.disconnect();
    }
    _flutterBlue.stopScan();
    _currentState = BluetoothManagerState.disconnected;
    _handleStateChange(_currentState);
    _handleValueCallbacks.clear();
    _notifyStateChangeCallbacks.clear();
    _device = null;
    _characteristic = null;
    _service = null;
    _device = null;
  }

  Future<List<ScanResult>> scanForAvailableSurfaceEmgDevices(
      {int timeoutMilliseconds: 5000}) async {
    return _flutterBlue.scan(
        timeout: Duration(milliseconds: timeoutMilliseconds),
        withServices: [Guid(serviceGuidString)]).toList();
  }

  Future<void> stopScan() {
    return _flutterBlue.stopScan();
  }

  void _startScanAndConnectLoop() {
    DateTime scanStartTimestamp = DateTime.now();
    _flutterBlue
        .scan(
            timeout: Duration(milliseconds: scanTimeoutMilliseconds),
            withServices: [Guid(serviceGuidString)])
        .firstWhere(
            (ScanResult scanResult) => scanResult.device.name == _deviceName,
            orElse: () => null)
        .then((ScanResult scanResult) {
          // Do nothing if reset was called during scan.
          if (scanStartTimestamp.isBefore(_mostRecentResetTimestamp)) {
            return;
          }

          if (scanResult != null) {
            _handleCorrectlyNamedScanResult(scanResult);
          } else {
            DateTime timerStart = DateTime.now();
            Timer(Duration(milliseconds: betweenScanIntervalMilliseconds), () {
              if (timerStart.isAfter(_mostRecentResetTimestamp)) {
                _startScanAndConnectLoop();
              }
            });
          }
        });
  }

  void _handleCorrectlyNamedScanResult(ScanResult scanResult) {
    _device = scanResult.device;
    _subscribeToDeviceState();
    _flutterBlue.stopScan();
    // TODO: just commented this out here (7/8). Don't think it is necessary.
//    _device.connect().catchError((err) => _startScanAndConnectLoop());

    // flutter_blue's connect method timeout does not allow usual error handling
    // to occur, thus using a timeout here.
    DateTime timeoutStart = DateTime.now();
    _device.connect().timeout(
        Duration(milliseconds: reconnectTimeoutMilliseconds), onTimeout: () {
      print('handling initial connection failure, will revert to scanning.');
      // Handles case where BluetoothManager is reset midway through connecting.
      if (timeoutStart.isAfter(_mostRecentResetTimestamp)) {
        _device.disconnect();
        _startScanAndConnectLoop();
      }
    });
  }

  void _subscribeToDeviceState() {
    DateTime _subscriptionTimestamp = DateTime.now();
    _deviceStateStreamSubscription =
        _device.state.listen(_handleNewDeviceState);
  }

  Future<void> _unsubscribeFromDeviceState() async {
    await _deviceStateStreamSubscription.cancel();
    _deviceStateStreamSubscription = null;
  }

  void _handleNewDeviceState(BluetoothDeviceState state) {
    if (state == BluetoothDeviceState.connected) {
      _handleDeviceConnectedState();
    } else if (state == BluetoothDeviceState.disconnected) {
      _handleDeviceDisconnectedState();
    }
  }

  // Check for services and characteristics
  // if present, set state to connected
  void _handleDeviceConnectedState() {
    if (_currentState == BluetoothManagerState.connected) {
      print('skipping _handleDeviceConnectedState call.');
      return;
    }
    print('handleDeviceConnectedState');
    _device.discoverServices().then((List<BluetoothService> services) {
      _service = services.singleWhere(
          (BluetoothService service) => service.uuid == Guid(serviceGuidString),
          orElse: () => null);

      if (_service == null) {
        _startScanAndConnectLoop();
        return;
      }

      _characteristic = _service.characteristics.singleWhere(
          (BluetoothCharacteristic characteristic) =>
              characteristic.uuid == Guid(characteristicGuidString),
          orElse: () => null);

      if (_characteristic == null) {
        _startScanAndConnectLoop();
        return;
      }

      _handleStateChange(BluetoothManagerState.connected);
    });
  }

  void _handleDeviceDisconnectedState() {
    if (_currentState == BluetoothManagerState.disconnected) {
      print('skipping _handleDeviceDisconnectedState call.');
      return;
    }
    print(
        'in _handleDeviceDisconnectedState at ${DateTime.now().millisecondsSinceEpoch}');
    _handleStateChange(BluetoothManagerState.disconnected);

    // flutter_blue's connect method timeout does not allow usual error handling
    // to occur, thus using a timeout here.
    _device.connect().timeout(
        Duration(milliseconds: reconnectTimeoutMilliseconds), onTimeout: () {
      print('handling reconnect failure, will revert to scanning.');
      _device.disconnect();
      _cancelValueStreamSubscriptionAndStopNotifying();
      _unsubscribeFromDeviceState();
      _characteristic = null;
      _service = null;
      _device = null;
      _startScanAndConnectLoop();
    });
  }

  void addHandleValueCallback(String name, void Function(EmgSample) callback) {
    if (_handleValueCallbacks.containsKey(name)) {
      throw ArgumentError(
          'addHandleValueCallback failed because a callback with name $name '
          'already exists.');
    }
    _handleValueCallbacks[name] = callback;
    _notifyWithValuesIfConnected();
  }

  void removeHandleValueCallback(String name) {
    if (_handleValueCallbacks.containsKey(name)) {
      _handleValueCallbacks.remove(name);
    }

    if (_handleValueCallbacks.isEmpty) {
      _cancelValueStreamSubscriptionAndStopNotifying();
    }
  }

  void clearHandleValueCallbacks() {
    _handleValueCallbacks.clear();
    _cancelValueStreamSubscriptionAndStopNotifying();
  }

  void _notifyWithValuesIfConnected() {
    if (_currentState == BluetoothManagerState.disconnected) {
      return;
    }

    if (!_characteristic.isNotifying) {
      // TODO: handle if setting notification value fails.
      _characteristic.setNotifyValue(true).then((_) {
        _valueStreamSubscription = _characteristic.value.listen(_handleValue);
      });
    }
  }

  void _handleValue(List<int> value) {
    if (value.isEmpty) {
      return;
    }

    int timestamp = DateTime.now().millisecondsSinceEpoch;

    int interpretedValue = _interpretCharacteristicValue(value);
    _handleValueCallbacks.values.forEach((Function callback) =>
        callback(EmgSample(timestamp, interpretedValue)));
  }

  Future<void> _cancelValueStreamSubscriptionAndStopNotifying() async {
    if (_valueStreamSubscription == null) {
      return;
    }

    await _valueStreamSubscription.cancel();
    _valueStreamSubscription = null;

    if (_characteristic != null) {
      // TODO: handle if setting notification value fails.
      await _characteristic.setNotifyValue(false);
    }
  }

  void addNotifyChangedStateCallback(
      String name, Function(BluetoothManagerState) callback) {
    if (_notifyStateChangeCallbacks.containsKey(name)) {
      throw ArgumentError(
          'addNotifyChangedStateCallback failed because a callback with name '
          '$name already exists.');
    }
    _notifyStateChangeCallbacks[name] = callback;
  }

  void removeNotifyChangedStateCallback(String name) {
    if (_notifyStateChangeCallbacks.containsKey(name)) {
      _notifyStateChangeCallbacks.remove(name);
    }
  }

  void clearNotifyChangedStateCallback() {
    _notifyStateChangeCallbacks.clear();
  }

  void _handleStateChange(BluetoothManagerState state) {
    _currentState = state;
    _notifyStateChangeCallbacks.values
        .forEach((Function callback) => callback(state));

    if (state == BluetoothManagerState.connected &&
        _handleValueCallbacks.isNotEmpty) {
      _notifyWithValuesIfConnected();
    }
  }
}

enum BluetoothManagerState { connected, disconnected }

int _interpretCharacteristicValue(List<int> value) {
  if (value.length == 2) {
    return value.last;
  } else {
    return (value[2] << 8) + value[1];
  }
}
