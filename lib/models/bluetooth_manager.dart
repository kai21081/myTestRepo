import 'dart:async';

import 'package:flutter_blue/flutter_blue.dart';

import 'emg_sample.dart';

class BluetoothManager {
  static const String serviceGuidString =
      '6506f07a-e64c-11ea-adc1-0242ac120002';
  static const String characteristicGuidString =
      '6506ed28-e64c-11ea-adc1-0242ac120002';
  static const int scanTimeoutMilliseconds = 10000;
  static const int betweenScanIntervalMilliseconds = 5000;
  static const int connectTimeoutMilliseconds = 5000;

  final FlutterBlue _flutterBlue;
  StreamSubscription<BluetoothDeviceState> _deviceStateStreamSubscription;

//  StreamSubscription<bool> _isDiscoveringServicesStreamSubscription;
  StreamSubscription<List<int>> _sEmgCharacteristicValueStreamSubscription;

  // Variables holding state.
  ConnectionSpec _connectionSpec = ConnectionSpec.shouldNotConnect();
  bool _canStartConnecting = true;

//  bool _isScanning = false;
//  bool _isStoppingScanning = false;
  ScanningState _scanningState = ScanningState.not_scanning_or_stopping;

//  bool _isConnecting = false;
//  bool _isStoppingConnecting = false;
  ConnectingState _connectingState =
      ConnectingState.not_connecting_or_disconnecting;

//  bool _isDiscoveringServices = false;
  DiscoveringServicesState _discoveringServicesState =
      DiscoveringServicesState.not_discovering;
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
    _flutterBlue.setLogLevel(LogLevel.debug);
    _flutterBlue.isScanning.listen((bool isScanning) {
      print('SCANNING CHANGE - isScanning = $isScanning');
    });
  }

  void connect(ConnectionSpec connectionSpec) {
    print('connect called.');
    _connectionSpec = connectionSpec;
    _handleGlobalState();
  }

  void _startScanIfNotAlreadyScanning() {
    // Only start the scan if not currently scanning or stopping a scan.
    if (_scanningState != ScanningState.not_scanning_or_stopping) {
      return;
    }

    print('Starting a scan becuase _scanningState = $_scanningState.');

    _scanningState = ScanningState.scanning;

    // Start a scan for devices with required services. Apply timeout to scan
    // here instead of using built in flutter_blue timeout to allow more control
    // over timeout behavior. No onTimeout method provided for timeout, meaning
    // it will throw a TimeoutException. This allows it to be caught and
    // different blocks of code to be executed on timeout versus found device.
    _flutterBlue
        .scan(withServices: [Guid(serviceGuidString)])
        .firstWhere((ScanResult result) {
      print(
          'Found scan result with appropriate service: ${result.device.name}.');
      print(result);
      return result.device.name == _connectionSpec.deviceName;
    })
        .timeout(Duration(milliseconds: scanTimeoutMilliseconds))
        .then((ScanResult result) {
      // Scan result was found with appropriate services and name. Only do
      // something with it if still scanning.
      if (_scanningState != ScanningState.scanning) {
        print(
            'In scan().firstWhere().then() with result, but _scanningState is $_scanningState.');
        return;
      }
      print('Handling correctly named scan result.');
      _scanResult = result;
    })
        .catchError((_) {
      // Timeout occurred. Stop scan.
      print('Scan timeout occurred.');
    })
        .whenComplete(() {
      // This block must stop the scan (regardless of whether or not a timeout
      // occurred or a device was found).
      _stopScan();
    });

//    if (_isScanning) {
//      return;
//    }
//    print('Setting: _isScanning = true');
//    _isScanning = true;
//    _flutterBlue.scan(withServices: [Guid(serviceGuidString)]).firstWhere(
//        (ScanResult scanResult) {
//      print('scan found: ${scanResult.device.name}');
//      return scanResult.device.name == _connectionSpec.deviceName;
//    }, orElse: () => null).timeout(
//        Duration(milliseconds: scanTimeoutMilliseconds), onTimeout: () {
//      print('scan timeout.');
//      return null;
//    }).then((ScanResult scanResult) async {
//      if (_isStoppingScanning) {
//        print('returning from .scan.then because _isStoppingScanning is true.');
//        return;
//      }
//
//      _isStoppingScanning = true;
//      print('In the method after scan with scan result: $scanResult.');
//      _scanResult = scanResult;
//      // Stopping scan will prompt an update based on the state because this
//      // class has a listener for changes in FlutterBlue's isScanning value.
//      await _flutterBlue.stopScan();
//      print('scan stopped.');
//      print('Setting: _isScanning = false');
//      _isScanning = false;
//      _handleGlobalState();
//    });
  }

  void _stopScan() async {
    // A scan should only be stopped if the device is currently scanning.
    if (_scanningState != ScanningState.scanning) {
      return;
    }

    _scanningState = ScanningState.stopping_scanning;
    print('Stopping scan from within _stopScan().');
    await _flutterBlue.stopScan();
    print('scan has been stopped!!!!');
    _scanningState = ScanningState.not_scanning_or_stopping;
    _handleGlobalState();

//    return _flutterBlue.stopScan().then((_) {
//      print('Setting _scanningState back to not_scanning_or_stopping.');
//      _scanningState = ScanningState.not_scanning_or_stopping;
//      _handleGlobalState();
//    }).catchError(
//        (_) => print('Caught stopScan error, must have skipped then.'));
  }

  void _handleGlobalState() {
    // Printing global state for debugging purposes.
    print('********** GLOBAL STATE *********');
    print('_connectionSpec: $_connectionSpec');
    print('_canStartConnecting: $_canStartConnecting');
    print('_scanningState: $_scanningState');
    print('_connectingState: $_connectingState');
    print('********** ************ *********\n\n');

    // If _canStartConnecting is false, it means the disconnect process has
    // been started somewhere. It must be completed before anything else can
    // happen.
    if (!_canStartConnecting) {
      _handleNotCanStartConnectingState();
      return;
    }

    // _canStartConnecting is true, so if the the manager should connect, do so.
    if (_connectionSpec.shouldConnect) {
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
    if (_connectingState == ConnectingState.connecting ||
        _deviceState != BluetoothDeviceState.connected) {
      print(
          '_handleShouldConnectState: _connectingState = $_connectingState, _deviceState = $_deviceState.');
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
    // a call to _handleGlobalState will occur once it finishes. But must not
    // proceed farther here while still discovering.
    if (_discoveringServicesState == DiscoveringServicesState.discovering) {
      print('Exiting _handleNotCanStartConnectingState because discovering '
          'services');
      return;
    }

    if (_deviceState == BluetoothDeviceState.connected) {
      print('Device connected - disconnecting.');
      _device.disconnect();
      return;
    }

    if (_connectingState == ConnectingState.connecting) {
      print('Device _isConnecting, stopping.');
      _disconnect();
      return;
    }

    if (_deviceState != BluetoothDeviceState.disconnected &&
        _deviceState != null) {
      print('Exiting _handleNotCanStartConnectingState because device not '
          'disconnected (state = $_deviceState)');
      return;
    }

    if (_scanningState == ScanningState.scanning) {
      print('Stopping scan from _handleNotCanStartConnectingState().');
      _stopScan();
      return;
    }

    // The process of stopping a scan has started. Don't pass this point until
    // it has finished.
    if (_scanningState == ScanningState.stopping_scanning) {
      print('Returning because _scanningState == stopping_scanning.');
      return;
    }

//    if (_isScanning && !_isStoppingScanning) {
//      print('Stopping scan from _handleNotCanStartConnectingState.');
//      _isStoppingScanning = true;
//      _flutterBlue.stopScan().then((_) {
//        print(
//            'Setting: _isScanning = false in _handleNoCanStartConnectingState');
//        _isScanning = false;
//        _isStoppingScanning = false;
//        _handleGlobalState();
//      });
//      return;
//    }

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
    // If already connecting or in process of disconnecting, do nothing and
    // return.
    if (_connectingState != ConnectingState.not_connecting_or_disconnecting) {
      return;
    }

    _connectingState = ConnectingState.connecting;
    _device = _scanResult.device;
    _deviceStateStreamSubscription =
        _device.state.listen(_handleDeviceStateChange);

    _device
        .connect()
        .timeout(Duration(milliseconds: connectTimeoutMilliseconds))
        .then((_) {
      // Did not time out. Confirm that a disconnect hasn't been initiated
      // elsewhere.
      if (_connectingState != ConnectingState.connecting) {
        return;
      }

      // This could potentially be moved to the function called when
      // connection state changes.
      _connectingState = ConnectingState.not_connecting_or_disconnecting;
      _handleGlobalState();
    }).catchError((_) {
      // Timed out. Disconnect.
      _disconnect();
    });

//    _connectingState = ConnectingState.connecting;
//    _device = _scanResult.device;
//    _deviceStateStreamSubscription =
//        _device.state.listen(_handleDeviceStateChange);
//
//    _device.connect().timeout(
//        Duration(milliseconds: connectTimeoutMilliseconds),
//        onTimeout: () async {
//          print('connection timeout in _connectToDeviceIfNotAlreadyConnecting');
//        });
//
//    _isConnecting = true;
//    _device = _scanResult.device;
//    _deviceStateStreamSubscription =
//        _device.state.listen(_handleDeviceStateChange);
//
//    _device
//        .connect()
//        .timeout(Duration(milliseconds: connectTimeoutMilliseconds),
//        onTimeout: () async {
//          print(
//              'connection timeout in _connectToDeviceIfNotAlreadyConnecting.');
//          await _stopConnecting();
//        }).then((_) {
//      _isConnecting = false;
//      _handleGlobalState();
//    });
  }

  void _disconnect() async {
    if (_connectingState != ConnectingState.connecting) {
      return;
    }

    print('Starting _disconnect with _connectionState = $_connectingState .');
    _connectingState = ConnectingState.disconnecting;
    await _deviceStateStreamSubscription.cancel();
    await _device.disconnect();

    // Clear values that were stored in connection process.
    _device = null;
    _scanResult = null;

    // Update states to reflect disconnect.
    _deviceState = BluetoothDeviceState.disconnected;
    _connectingState = ConnectingState.not_connecting_or_disconnecting;

    // Handle global state now that disconnecting is complete.
    _handleGlobalState();
  }

//  Future<void> _stopConnecting() async {
//    if (_isStoppingConnecting) {
//      return;
//    }
//
//    print('starting _stopConnecting.');
//    _isStoppingConnecting = true;
//    await _deviceStateStreamSubscription.cancel();
//    await _device.disconnect();
//    _device = null;
//    _scanResult = null;
//    _deviceState = BluetoothDeviceState.disconnected;
//    _isStoppingConnecting = false;
//    print('ending _stopConnecting.');
//  }

  void _handleDeviceStateChange(BluetoothDeviceState state) async {
    print('_handleDeviceStateChange with: $state');
    bool stateChangeConnectToDisconnect =
        state == BluetoothDeviceState.disconnected &&
            _deviceState == BluetoothDeviceState.connected;

    _deviceState = state;

    if (stateChangeConnectToDisconnect) {
      print('!!!!! HANDLE DEVICE DISCONNECT !!!!!');
      _discoveredServices = null;
      _device = null;
    }

    _handleGlobalState();
  }

  void _discoverServicesIfNotAlreadyDiscovering() {
    if (_discoveringServicesState == DiscoveringServicesState.discovering) {
      return;
    }
    _discoveringServicesState = DiscoveringServicesState.discovering;

    _device.discoverServices().then((List<BluetoothService> services) {
      _discoveredServices = services;
      _discoveringServicesState = DiscoveringServicesState.not_discovering;
      _handleGlobalState();
    });
  }

  void _handleDiscoveredServices() {
    // Device should for certain have services because that was a condition for
    // the scan.
    _sEmgService = _discoveredServices.firstWhere(
            (BluetoothService service) =>
        service.uuid == Guid(serviceGuidString));

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
      print('Starting to set notify value to: $notifyValue');
      _sEmgCharacteristic.setNotifyValue(notifyValue).then((_) {
        // If now notifying, listen to stream.
        print('Notify value set, in ' 'then' ' callback.');
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
    EmgSample(DateTime
        .now()
        .millisecondsSinceEpoch, interpretedValue);
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

  bool get isReadyToProvideValues => _isReadyToProvideValues;

  void addNotifyIsReadyToProvideValuesStateCallback(String name,
      Function(bool) callback) {
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
    print('resetting.');
    _connectionSpec = ConnectionSpec.shouldNotConnect();
    _canStartConnecting = false;
    _handleGlobalState();
  }

  Future<List<ScanResult>> scanForAvailableSurfaceEmgDevices(
      {int timeoutMilliseconds: scanTimeoutMilliseconds}) async {
    return _flutterBlue.scan(
        timeout: Duration(milliseconds: timeoutMilliseconds),
        withServices: [Guid(serviceGuidString)]).toList();
  }

  // This is used when searching for available devices to display to the user.
  // Long term, it may be better to find a way to combine it with the scan done
  // during the connection process.
  Future stopScan() {
    return _flutterBlue.stopScan();
  }
}

enum BluetoothManagerState { connected, disconnected }

enum ConnectingState {
  connecting,
  disconnecting,
  not_connecting_or_disconnecting
}

enum ScanningState { scanning, stopping_scanning, not_scanning_or_stopping }

enum DiscoveringServicesState { discovering, not_discovering }

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

  String toString() {
    return 'shouldConnect: $shouldConnect, deviceName: $deviceName';
  }
}
