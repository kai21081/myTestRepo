import 'dart:async';

import 'package:flutter_blue/flutter_blue.dart';

import 'emg_sample.dart';

class BluetoothManager {
  static const String serviceGuidString =
      '0000180d-0000-1000-8000-00805f9b34fb';
  static const String characteristicGuidString =
      '00002a37-0000-1000-8000-00805f9b34fb';
  static const int scanTimeoutMilliseconds = 20000;
  static const int betweenScanIntervalMilliseconds = 5000;
  static const int connectTimeoutMilliseconds = 5000;

  final FlutterBlue _flutterBlue;
  StreamSubscription<BluetoothDeviceState> _deviceStateStreamSubscription;
  StreamSubscription<bool> _isDiscoveringServicesStreamSubscription;
  StreamSubscription<List<int>> _sEmgCharacteristicValueStreamSubscription;

  // Variables holding state.
  ConnectionSpec _connectionSpec = ConnectionSpec.shouldNotConnect();
  bool _canStartConnecting = true;
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isStoppingConnecting = false;
  bool _isDiscoveringServices = false;
  bool _changingSEmgCharacteristicNotifyValue = false;
  bool _surfaceEmgShouldBeNotifying = false;
  bool _sEmgCharacteristicIsNotifying = false;
  bool _isReadyToProvideValues = false;

  ScanResult _scanResult;
  BluetoothDevice _device;
  BluetoothDeviceState _deviceState; // maybe start with disconnected?
  List<BluetoothService> _discoveredServices;
  BluetoothService _sEmgService;
  BluetoothCharacteristic _sEmgCharacteristic;

  Map<String, void Function(EmgSample)>
      _handleSEmgCharacteristicValueCallbacks =
      Map<String, void Function(EmgSample)>();
  Map<String, void Function(bool)> _handleIsReadyToProvideValuesCallbacks =
      Map<String, void Function(bool)>();

  BluetoothManager() : _flutterBlue = FlutterBlue.instance {
//    _flutterBlue.isScanning.listen(_handleIsScanningChange);
  }

  void connect(ConnectionSpec connectionSpec) {
    print('connect called.');
    _connectionSpec = connectionSpec;
    _handleGlobalState();
  }

  void _startScanIfNotAlreadyScanning() {
    if (_isScanning) {
      return;
    }
    _isScanning = true;
    _flutterBlue.scan(withServices: [Guid(serviceGuidString)]).firstWhere(
        (ScanResult scanResult) {
      print('scan found: ${scanResult.device.name}');
      return scanResult.device.name == _connectionSpec.deviceName;
    }, orElse: () => null).timeout(
        Duration(milliseconds: scanTimeoutMilliseconds), onTimeout: () {
      print('scan timeout.');
      return null;
    }).then((ScanResult scanResult) async {
      print('In then method after scan with scan result: $scanResult.');
      _scanResult = scanResult;
      // Stopping scan will prompt an update based on the state because this
      // class has a listener for changes in FlutterBlue's isScanning value.
      await _flutterBlue.stopScan();
      print('scan stopped.');
      _isScanning = false;
      _handleGlobalState();
    });
  }

  void _handleIsScanningChange(bool isScanning) {
    print('_handleIsScanningChange called with $isScanning.');
    _isScanning = isScanning;
    _handleGlobalState();
  }

  void _handleGlobalState() {
    // If _canStartConnecting is false, it means the disconnect process has
    // been started somewhere. It must be completed before anything else can
    // happen.
    if (!_canStartConnecting) {
      _handleNotCanStartConnectingState();
      return;
    }

    // _canStartConnecting is true, so if the the manager should connect, do so.
    if (!_connectionSpec.shouldConnect) {
      _handleShouldConnectState();
    }

    // need to figure out how to eventually get isDisconnecting back to false
    // (which should re-prompt scan in some cases).
  }

  // Assumes _canStartConnecting == true;
  void _handleShouldConnectState() {
    if (_scanResult == null) {
      print('Starting scan with _scanResult = $_scanResult');
      _startScanIfNotAlreadyScanning();
      return;
    }

    // Arriving here means there are results of a scan.
    if (_device == null) {
      print('Connecting to device.');
      _connectToDeviceIfNotAlreadyConnecting();
      return;
    }

    // May still be trying to connect. Don't do anything further until
    // connected.
    if (_isConnecting || _deviceState != BluetoothDeviceState.connected) {
      return;
    }

    // Connected to device.
    if (_discoveredServices == null) {
      print('Discovering services.');
      _discoverServicesIfNotAlreadyDiscovering();
      return;
    }

    if (_sEmgService == null || _sEmgCharacteristic == null) {
      print('Handling discovered services.');
      _handleDiscoveredServices();
      return;
    }

    if (!_sEmgCharacteristicIsNotifying) {
      print('handling sEMG characteristic.');
      _setSEmgCharacteristicNotifyValue(true);
      return;
    }

    // At this point, characteristic should be notifying and ready.
    print('Notifying that is ready to provide values state.');
    _isReadyToProvideValues = true;
    _notifyIsReadyToProvideValuesState();
  }

  void _handleNotCanStartConnectingState() {
    if (_isReadyToProvideValues) {
      print('Notifying not ready to provide values');
      _isReadyToProvideValues = false;
      _notifyIsReadyToProvideValuesState();
    }

    // If _canStartConnecting is false, it means manager is part way through a
    // disconnect. Finish the disconnection.
    if (_sEmgCharacteristicIsNotifying) {
      print('Stopping sEMG characteristic notification.');
      _setSEmgCharacteristicNotifyValue(false);
      return;
    }

    // Note nothing needs to be done if _isDiscoveringServices is true because
    // there should be a stream listening to updates for this value.
    if (_isDiscoveringServices) {
      print('Exiting _handleNotCanStartConnectingState because discovering '
          'services');
      return;
    }

    if (_deviceState == BluetoothDeviceState.connected) {
      print('Device connected - disconnecting.');
      _device.disconnect();
      return;
    }

    if (_isConnecting) {
      print('Device _isConnecting, stopping.');
      _stopConnecting().then((_) => _handleGlobalState());
      return;
    }

    if (_deviceState != BluetoothDeviceState.disconnected) {
      print('Exiting _handleNotCanStartConnectingState because device not '
          'disconnected.');
      return;
    }

    if (_isScanning) {
      print('Stopping scan.');
      _flutterBlue.stopScan().then((_) {
        _isScanning = false;
        _handleGlobalState();
      });
      return;
    }

    // If everything has been undone, the device is now ready to connect
    // (assuming a device name is provided).
    print('Setting _canStartConnecting to true.');
    _scanResult = null;
    _canStartConnecting = true;

    if (_connectionSpec.shouldConnect) {
      _handleGlobalState();
    }
  }

  // Expects that _scanResult will contain a scan result with a device with
  // the correct name and service.
  void _connectToDeviceIfNotAlreadyConnecting() {
    if (_isConnecting) {
      return;
    }

    _isConnecting = true;
    _device = _scanResult.device;
    _deviceStateStreamSubscription =
        _device.state.listen(_handleDeviceStateChange);
    _isDiscoveringServicesStreamSubscription = _device.isDiscoveringServices
        .listen(_handleIsDiscoveringServicesChange);

    _device
        .connect()
        .timeout(Duration(milliseconds: connectTimeoutMilliseconds),
            onTimeout: () async {
      print('connection timeout.');
      await _stopConnecting();
    }).then((_) {
      _isConnecting = false;
      _handleGlobalState();
    });
  }

  Future<void> _stopConnecting() async {
    if (_isStoppingConnecting) {
      return;
    }

    print('starting _stopConnecting.');
    _isStoppingConnecting = true;
    await _deviceStateStreamSubscription.cancel();
    await _isDiscoveringServicesStreamSubscription.cancel();
    await _device.disconnect();
    _device = null;
    _scanResult = null;
    _deviceState = BluetoothDeviceState.disconnected;
    _isStoppingConnecting = false;
    print('ending _stopConnecting.');
  }

  void _handleDeviceStateChange(BluetoothDeviceState state) async {
    print('_handleDeviceStateChange with: $state');
    bool stateChangeConnectToDisconnect =
        state == BluetoothDeviceState.disconnected &&
            _deviceState == BluetoothDeviceState.connected;
    _deviceState = state;

    if (stateChangeConnectToDisconnect) {
      print('!!!!! HANDLE DEVICE DISCONNECT !!!!!');
    }

    _handleGlobalState();
  }

  void _discoverServicesIfNotAlreadyDiscovering() {
    if (_isDiscoveringServices) {
      return;
    }

    _device.discoverServices().then((List<BluetoothService> services) {
      _discoveredServices = services;
      _handleGlobalState();
    });
  }

  void _handleIsDiscoveringServicesChange(bool isDiscoveringServices) {
    _isDiscoveringServices = isDiscoveringServices;
    _handleGlobalState();
  }

  void _handleDiscoveredServices() {
    // Device should for certain have services because that was a condition for
    // the scan.
    _sEmgService = _discoveredServices.firstWhere(
        (BluetoothService service) => service.uuid == Guid(serviceGuidString));

    List<BluetoothCharacteristic> sEmgCharacteristics = _sEmgService
        .characteristics
        .where((BluetoothCharacteristic characteristic) =>
            characteristic.uuid == Guid(characteristicGuidString))
        .toList();

    if (sEmgCharacteristics.length != 1) {
      print('Was not exactly 1 characteristic.');
      // There was a problem in that device has either no appropriate
      // characteristics or too many.
      _sEmgService = null;
      _canStartConnecting = false;
    } else {
      print('Setting discovered service (found exactly 1).');
      _sEmgCharacteristic = sEmgCharacteristics.first;
    }

    _handleGlobalState();
  }

  void _setSEmgCharacteristicNotifyValue(bool notifyValue) async {
    _surfaceEmgShouldBeNotifying = notifyValue;

    if (_changingSEmgCharacteristicNotifyValue) {
      return;
    }

    if (_sEmgCharacteristic.isNotifying != _surfaceEmgShouldBeNotifying) {
      _changingSEmgCharacteristicNotifyValue = true;

      // We are changing value, so if currently notifying, stop listening to
      // stream.
      if (_sEmgCharacteristic.isNotifying) {
        await _sEmgCharacteristicValueStreamSubscription.cancel();
      }

      // Now set the value.
      _sEmgCharacteristic.setNotifyValue(notifyValue).then((_) {
        // If now notifying, listen to stream.
        if (notifyValue) {
          _sEmgCharacteristicValueStreamSubscription =
              _sEmgCharacteristic.value.listen(_handleSEmgCharacteristicValue);
        }
        _sEmgCharacteristicIsNotifying = notifyValue;
        _changingSEmgCharacteristicNotifyValue = false;

        // Make sure _shouldBeNotifying hasn't changed while notifyValue was
        // set.
        if (_surfaceEmgShouldBeNotifying != notifyValue) {
          _setSEmgCharacteristicNotifyValue(_surfaceEmgShouldBeNotifying);
        } else {
          _handleGlobalState();
        }
      });
    }
  }

  void _startSEmgCharacteristicNotifyingIfNotAlreadyStarting() {
    // Set up notifying.
    if (_changingSEmgCharacteristicNotifyValue) {
      return;
    }

    if (!_sEmgCharacteristic.isNotifying) {
      _changingSEmgCharacteristicNotifyValue = true;
      _sEmgCharacteristic.setNotifyValue(true).then((_) {
        _sEmgCharacteristicValueStreamSubscription =
            _sEmgCharacteristic.value.listen(_handleSEmgCharacteristicValue);
        _sEmgCharacteristicIsNotifying = true;
        _changingSEmgCharacteristicNotifyValue = false;
        _handleGlobalState();
      });
    }
  }

  void _stopSEmgCharacteristicNotifying() {
    if (_sEmgCharacteristic.isNotifying) {
      _sEmgCharacteristicValueStreamSubscription.cancel();
      _sEmgCharacteristic.setNotifyValue(false).then((_) {
        _sEmgCharacteristicIsNotifying = false;
        _handleGlobalState();
      });
    }
  }

  void _handleSEmgCharacteristicValue(List<int> value) {
    if (!_isReadyToProvideValues) {
      return;
    }

    if (value.isEmpty) {
      return;
    }

    int interpretedValue = _interpretSEmgCharacteristicValue(value);
    EmgSample sample =
        EmgSample(DateTime.now().millisecondsSinceEpoch, interpretedValue);
    _handleSEmgCharacteristicValueCallbacks.values
        .forEach((Function callback) => callback(sample));
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

  void reset() {
    _connectionSpec = ConnectionSpec.shouldNotConnect();
    _canStartConnecting = false;
    _handleGlobalState();
  }

  Future<List<ScanResult>> scanForAvailableSurfaceEmgDevices(
      {int timeoutMilliseconds: 5000}) async {
    return _flutterBlue.scan(
        timeout: Duration(milliseconds: timeoutMilliseconds),
        withServices: [Guid(serviceGuidString)]).toList();
  }
}

enum BluetoothManagerState { connected, disconnected }

int _interpretSEmgCharacteristicValue(List<int> value) {
  if (value.length == 2) {
    return value.last;
  } else {
    return (value[2] << 8) + value[1];
  }
}

class ConnectionSpec {
  final bool shouldConnect;
  final String deviceName;

  ConnectionSpec(this.shouldConnect, this.deviceName);

  ConnectionSpec.fromDeviceName(String name)
      : shouldConnect = true,
        deviceName = name;

  static ConnectionSpec shouldNotConnect() {
    return ConnectionSpec(false, null);
  }
}
