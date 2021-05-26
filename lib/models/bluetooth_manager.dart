import 'dart:async';

import 'package:flutter_blue/flutter_blue.dart';
import 'package:gameplayground/models/callback_collection.dart';
import 'package:gameplayground/models/surface_emg_characteristic.dart';
import 'package:gameplayground/models/surface_emg_guids.dart';
import 'package:gameplayground/models/surface_emg_service.dart';

import 'emg_sample.dart';

class BluetoothManager {
  static const int scanTimeoutMilliseconds = 15000;
  static const int betweenScanIntervalMilliseconds = 5000;
  static const int connectTimeoutMilliseconds = 10000;
  static const String handleEmgVoltageCallbackName =
      'BluetoothManager.handleEmgVoltageCallback';

  static const String deviceAuthenticationKey = '00000000';

  final FlutterBlue _flutterBlue;
  StreamSubscription<BluetoothDeviceState> _deviceStateStreamSubscription;

  // Variables holding state.
  ConnectionSpec _connectionSpec = ConnectionSpec.shouldNotConnect();
  bool _canStartConnecting = true;

  ScanningState _scanningState = ScanningState.not_scanning_or_stopping;

  ConnectingState _connectingState =
      ConnectingState.not_connecting_or_disconnecting;

  DiscoveringServicesState _discoveringServicesState =
      DiscoveringServicesState.not_discovering;

  bool _isAuthenticated = false;
  bool _isReadyToProvideValues = false;

  ScanResult _scanResult;
  BluetoothDevice _device;
  BluetoothDeviceState _deviceState; // maybe start with disconnected?
  List<BluetoothService> _discoveredServices;

  SurfaceEmgService _surfaceEmgService;

  CallbackCollection<String, bool> _handleIsReadyToProvideValuesCallbacks =
      CallbackCollection<String, bool>();
  CallbackCollection<String, RawEmgSample> _handleEmgSampleCallbacks =
      CallbackCollection<String, RawEmgSample>();

  BluetoothManager() : _flutterBlue = FlutterBlue.instance {
    _flutterBlue.setLogLevel(LogLevel.debug);
  }

  // Initiates connection process with provided ConnectionSpec.
  void connect(ConnectionSpec connectionSpec) {
    print('connect called.');
    _connectionSpec = connectionSpec;
    _handleGlobalState(callOrigin: 'connect');
  }

  void _handleGlobalState({String callOrigin}) {
    // Printing global state for debugging purposes.
    print('********** GLOBAL STATE *********');
    if (callOrigin != null) {
      print('called from $callOrigin');
    }
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
      print('_handleShouldConnectState: _connectingState = $_connectingState, '
          '_deviceState = $_deviceState.');
      return;
    }

    // Connected to device.
    if (_discoveredServices == null) {
      print('Discovering services.');
      _discoverServicesIfNotAlreadyDiscovering();
      return;
    }

    if (_surfaceEmgService == null) {
      print('Handling discovered services.');
      _handleDiscoveredServices();
      return;
    }

    // TODO: do we need to verify that authenticate succeeded?
    if (!_isAuthenticated) {
      authenticate().then((_) {
        _isAuthenticated = true;
        _handleGlobalState(
            callOrigin: '_handleShouldConnectState -> !_isAuthenticated block');
      });
      return;
    }

    if (!_surfaceEmgService.characteristicIsNotifying(
        ReadOnlySurfaceEmgCharacteristicType.emgVoltage)) {
      print('handling sEMG characteristic.');
      _surfaceEmgService.setCharacteristicNotifyValue(
          ReadOnlySurfaceEmgCharacteristicType.emgVoltage,
          true,
          () => _handleGlobalState(
              callOrigin:
                  '_handleShouldConnectState -> setCharacteristicNotifyValue callback'));
      return;
    }

    // At this point, characteristic should be notifying and ready.
    print('Notifying that is ready to provide values state.');
    _isReadyToProvideValues = true;
    _notifyIsReadyToProvideValuesState();
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
    // over timeout behavior. No onTimeout method provided for timeout within
    // flutter_blue, meaning it will throw a TimeoutException. This allows it to
    // be caught and different blocks of code to be executed on timeout versus
    // found device.
    _flutterBlue
        .scan(withServices: [SurfaceEmgGuids.surfaceEmgService()])
        .firstWhere((ScanResult result) {
          print('*****************************************');
          print('*****************************************');
          print(
              'Found scan result with appropriate service: ${result.device.name}.');
          print(result);
          print('*****************************************');
          print('*****************************************');

          return result.device.name == _connectionSpec.deviceName;
        })
        .timeout(Duration(milliseconds: scanTimeoutMilliseconds))
        .then((ScanResult result) {
          // Scan result was found with appropriate services and name. Only do
          // something with it if still scanning.
          if (_scanningState != ScanningState.scanning) {
            print(
                'In scan().firstWhere().then() with result, but _scanningState '
                'is $_scanningState.');
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
  }

  void _stopScan() async {
    // A scan should only be stopped if the device is currently scanning.
    if (_scanningState != ScanningState.scanning) {
      return;
    }

    _scanningState = ScanningState.stopping_scanning;
    print('Stopping scan from within _stopScan().');
    await _flutterBlue.stopScan();
    print('Scan has been stopped.');
    _scanningState = ScanningState.not_scanning_or_stopping;
    _handleGlobalState(callOrigin: '_stopScan');
  }

  void _handleNotCanStartConnectingState() {
    if (_isReadyToProvideValues) {
      print('Notifying not ready to provide values');
      _isReadyToProvideValues = false;
      _notifyIsReadyToProvideValuesState();
    }

    // If _canStartConnecting is false, it means manager is part way through a
    // disconnect. Finish the disconnection.
    if (_surfaceEmgService != null &&
        _surfaceEmgService.characteristicIsNotifying(
            ReadOnlySurfaceEmgCharacteristicType.emgVoltage)) {
      print('Stopping sEMG characteristic notification.');
      _surfaceEmgService.setCharacteristicNotifyValue(
          ReadOnlySurfaceEmgCharacteristicType.emgVoltage,
          false,
          () => _handleGlobalState(
              callOrigin:
                  '_handleNotCanStartConnectingState -> setCharacteristicNotifyValue callback'));
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

    _isAuthenticated = false;
    _device = null;
    _scanResult = null;
    _discoveredServices = null;
    _surfaceEmgService = null;

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

    // If everything has been undone, the device is now ready to connect
    // (assuming a device name is provided).
    print('Setting _canStartConnecting to true.');
    _canStartConnecting = true;

    if (_connectionSpec.shouldConnect) {
      _handleGlobalState(
          callOrigin:
              '_handleNotCanStartConnectingState -> _connectionSpec.shouldConnect block');
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
      _handleGlobalState(
          callOrigin:
              '_connectToDeviceIfNotAlreadyConnecting -> _device.connect().then()');
    }).catchError((_) {
      // Timed out. Disconnect.
      _disconnect();
    });
  }

  void _disconnect() async {
    if (_connectingState != ConnectingState.connecting) {
      return;
    }

    print('Starting _disconnect with _connectionState = $_connectingState .');
    _connectingState = ConnectingState.disconnecting;
    await _deviceStateStreamSubscription.cancel();
    await _device.disconnect();

    // Update states to reflect disconnect.
    _deviceState = BluetoothDeviceState.disconnected;
    _connectingState = ConnectingState.not_connecting_or_disconnecting;

    // Handle global state now that disconnecting is complete.
    _handleGlobalState(callOrigin: '_disconnect');
  }

  void _handleDeviceStateChange(BluetoothDeviceState state) async {
    print('_handleDeviceStateChange with: $state');
    bool stateChangeConnectToDisconnect =
        state == BluetoothDeviceState.disconnected &&
            _deviceState == BluetoothDeviceState.connected;

    _deviceState = state;

    if (stateChangeConnectToDisconnect) {
      _canStartConnecting = false;
    }

    _handleGlobalState(callOrigin: '_handleDeviceStateChange');
  }

  void _discoverServicesIfNotAlreadyDiscovering() {
    if (_discoveringServicesState == DiscoveringServicesState.discovering) {
      return;
    }
    _discoveringServicesState = DiscoveringServicesState.discovering;

    _device.discoverServices().then((List<BluetoothService> services) {
      _discoveredServices = services;
      _discoveringServicesState = DiscoveringServicesState.not_discovering;
      _handleGlobalState(
          callOrigin:
              '_discoverServicesIfNotAlreadyDiscovering -> _device.discoverServices().then()');
    });
  }

  void _handleDiscoveredServices() {
    // Device should for certain have services because that was a condition for
    // the scan.
    _surfaceEmgService = SurfaceEmgService(_discoveredServices.firstWhere(
        (BluetoothService service) =>
            service.uuid == SurfaceEmgGuids.surfaceEmgService()));
    _surfaceEmgService.addHandleEmgVoltageProcessedValueCallback(
        BluetoothManager.handleEmgVoltageCallbackName,
        _handleEmgSampleCallbacks.handleValue);
    _handleGlobalState(callOrigin: '_handleDiscoveredServices');
  }

  void addHandleSEmgValueCallback(
      String name, Function(RawEmgSample) callback) {
    // Wrapping callback for debugging
    Function(RawEmgSample) wrappedCallback = (RawEmgSample sample) {
      print('Calling callback: $name');
      callback(sample);
    };
    _handleEmgSampleCallbacks.addCallback(name, wrappedCallback);
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

  Future<void> authenticate() {
    return _surfaceEmgService
        .setConnectionModeAuthenticationCharacteristicValue(
            deviceAuthenticationKey);
  }

  Future<void> startStreamingValues() {
    return _surfaceEmgService.setShouldStreamValuesCharacteristicValue(true);
  }

  Future<void> stopStreamingValues() {
    return _surfaceEmgService.setShouldStreamValuesCharacteristicValue(false);
  }

  void reset() {
    print('resetting.');
    _connectionSpec = ConnectionSpec.shouldNotConnect();
    _canStartConnecting = false;
    _handleGlobalState(callOrigin: 'reset');
  }

  Future<List<ScanResult>> scanForAvailableSurfaceEmgDevices(
      {int timeoutMilliseconds: scanTimeoutMilliseconds}) async {
    return _flutterBlue.scan(
        timeout: Duration(milliseconds: timeoutMilliseconds),
        withServices: [SurfaceEmgGuids.surfaceEmgService()]).toList();
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
